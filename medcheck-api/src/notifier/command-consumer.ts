import { createClient } from "redis";
import { config } from "@/config/config";

const NOTIFIER_COMMAND_CHANNEL = "medcheck:notifier:commands";

type NotifierCommand = {
  type: "process_pending_alerts";
  reason: string;
  requestedAt: string;
  source: "api";
};

type NotifierCommandHandler = (command: NotifierCommand) => Promise<void>;
type AppRedisClient = ReturnType<typeof createClient>;

let publisher: AppRedisClient | null = null;
let subscriber: AppRedisClient | null = null;
let publisherReady = false;
let subscriberReady = false;

function isRedisConfigured(): boolean {
  return config.redisUrl.trim().length > 0;
}

function buildClient(role: "notifier-pub" | "notifier-sub"): AppRedisClient {
  const client = createClient({ url: config.redisUrl });

  client.on("error", (err) => {
    console.error(`[REDIS:${role}] Error:`, err);
  });

  client.on("reconnecting", () => {
    console.warn(`[REDIS:${role}] Reconnecting...`);
  });

  client.on("ready", () => {
    console.log(`[REDIS:${role}] Ready`);
  });

  return client;
}

async function ensurePublisher(): Promise<AppRedisClient | null> {
  if (!isRedisConfigured()) {
    return null;
  }

  if (!publisher) {
    publisher = buildClient("notifier-pub");
  }

  if (!publisherReady) {
    await publisher.connect();
    publisherReady = true;
  }

  return publisher;
}

export async function publishProcessPendingAlertsCommand(
  reason: string,
): Promise<boolean> {
  const client = await ensurePublisher();
  if (!client) {
    return false;
  }

  const payload: NotifierCommand = {
    type: "process_pending_alerts",
    reason,
    requestedAt: new Date().toISOString(),
    source: "api",
  };

  await client.publish(NOTIFIER_COMMAND_CHANNEL, JSON.stringify(payload));
  return true;
}

export async function startNotifierCommandConsumer(
  onCommand: NotifierCommandHandler,
): Promise<void> {
  if (!isRedisConfigured()) {
    console.warn(
      "[REDIS] REDIS_URL not configured. Notifier will use only cron fallback.",
    );
    return;
  }

  if (!subscriber) {
    subscriber = buildClient("notifier-sub");
  }

  if (subscriberReady) {
    return;
  }

  await subscriber.connect();
  subscriberReady = true;

  await subscriber.subscribe(NOTIFIER_COMMAND_CHANNEL, async (message) => {
    try {
      const parsed = JSON.parse(message) as Partial<NotifierCommand>;
      if (parsed.type !== "process_pending_alerts" || !parsed.reason) {
        return;
      }

      await onCommand({
        type: "process_pending_alerts",
        reason: parsed.reason,
        requestedAt: parsed.requestedAt || new Date().toISOString(),
        source: "api",
      });
    } catch (err) {
      console.error("[REDIS:notifier-sub] Invalid command payload:", err);
    }
  });
}

export async function closeNotifierCommandConsumer(): Promise<void> {
  const activePublisher = publisher;
  const activeSubscriber = subscriber;

  publisher = null;
  subscriber = null;
  publisherReady = false;
  subscriberReady = false;

  await Promise.allSettled([activePublisher?.quit(), activeSubscriber?.quit()]);
}

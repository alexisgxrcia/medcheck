import { createClient } from "redis";
import { config } from "@/config/config";

type UserEventHandler = (userId: string, event: string) => void;

const USER_EVENT_CHANNEL = "medcheck:sse:user-events";

type AppRedisClient = ReturnType<typeof createClient>;

let publisher: AppRedisClient | null = null;
let subscriber: AppRedisClient | null = null;
let initPromise: Promise<void> | null = null;
let initialized = false;
let subscribedHandler: UserEventHandler | null = null;

function isRedisConfigured(): boolean {
  return config.redisUrl.trim().length > 0;
}

function buildClient(role: "pub" | "sub"): AppRedisClient {
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

export async function initRedisUserEvents(
  onUserEvent: UserEventHandler,
): Promise<void> {
  if (!isRedisConfigured()) {
    console.warn(
      "[REDIS] REDIS_URL not configured. SSE will use only local in-memory delivery.",
    );
    return;
  }

  if (initialized) {
    subscribedHandler = onUserEvent;
    return;
  }

  subscribedHandler = onUserEvent;

  if (initPromise) {
    await initPromise;
    return;
  }

  initPromise = (async () => {
    publisher = buildClient("pub");
    subscriber = buildClient("sub");

    await publisher.connect();
    await subscriber.connect();

    await subscriber.subscribe(USER_EVENT_CHANNEL, (message) => {
      try {
        const parsed = JSON.parse(message) as {
          userId?: string;
          event?: string;
        };
        if (!parsed.userId || !parsed.event) return;
        subscribedHandler?.(parsed.userId, parsed.event);
      } catch (err) {
        console.error("[REDIS:sub] Invalid user event payload:", err);
      }
    });

    initialized = true;
    console.log(`[REDIS] Subscribed to ${USER_EVENT_CHANNEL}`);
  })();

  try {
    await initPromise;
  } catch (err) {
    initPromise = null;
    publisher = null;
    subscriber = null;
    initialized = false;
    throw err;
  }
}

export async function publishUserEvent(
  userId: string,
  event: string,
): Promise<boolean> {
  if (!isRedisConfigured()) {
    return false;
  }

  if (!publisher || !initialized) {
    throw new Error("[REDIS] publishUserEvent called before initialization");
  }

  await publisher.publish(USER_EVENT_CHANNEL, JSON.stringify({ userId, event }));
  return true;
}

export async function closeRedisUserEvents(): Promise<void> {
  const activePublisher = publisher;
  const activeSubscriber = subscriber;

  publisher = null;
  subscriber = null;
  initPromise = null;
  initialized = false;
  subscribedHandler = null;

  await Promise.allSettled([
    activePublisher?.quit(),
    activeSubscriber?.quit(),
  ]);
}

export function hasRedisUserEvents(): boolean {
  return isRedisConfigured();
}

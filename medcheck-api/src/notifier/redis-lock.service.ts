import { createClient } from "redis";
import { config } from "@/config/config";

const PROCESS_PENDING_ALERTS_LOCK =
  "medcheck:notifier:process_pending_alerts:lock";

type AppRedisClient = ReturnType<typeof createClient>;

let lockClient: AppRedisClient | null = null;

function getLockClient(): AppRedisClient | null {
  if (!config.redisUrl.trim()) {
    return null;
  }

  if (lockClient) {
    return lockClient;
  }

  lockClient = createClient({ url: config.redisUrl });
  lockClient.on("error", (err) => {
    console.error("[REDIS:notifier-lock] Error:", err);
  });

  return lockClient;
}

async function ensureConnected(client: AppRedisClient): Promise<void> {
  if (client.isOpen) return;
  await client.connect();
}

export async function withNotifierExecutionLock(
  fn: () => Promise<void>,
): Promise<boolean> {
  const client = getLockClient();
  if (!client) {
    await fn();
    return true;
  }

  await ensureConnected(client);

  const token = `${process.pid}:${Date.now()}`;
  const acquired = await client.set(PROCESS_PENDING_ALERTS_LOCK, token, {
    NX: true,
    EX: 55,
  });

  if (!acquired) {
    return false;
  }

  try {
    await fn();
    return true;
  } finally {
    try {
      const currentToken = await client.get(PROCESS_PENDING_ALERTS_LOCK);
      if (currentToken === token) {
        await client.del(PROCESS_PENDING_ALERTS_LOCK);
      }
    } catch (err) {
      console.error("[REDIS:notifier-lock] Error liberando lock:", err);
    }
  }
}

export async function closeNotifierLockClient(): Promise<void> {
  const activeClient = lockClient;
  lockClient = null;
  await activeClient?.quit();
}

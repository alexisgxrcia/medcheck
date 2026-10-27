import cron from "node-cron";
import { warmUpPool } from "./config/database";
import "./config/firebase";
import {
  closeNotifierCommandConsumer,
  startNotifierCommandConsumer,
} from "./notifier/command-consumer";
import { processNotificationCron } from "./notifier/notification-cron.service";
import {
  closeNotifierLockClient,
  withNotifierExecutionLock,
} from "./notifier/redis-lock.service";

async function startNotifier() {
  try {
    console.log("[NOTIFIER] Verificando conexión a la base de datos...");
    await warmUpPool();
    console.log("[NOTIFIER] Base de datos lista.");
    await startNotifierCommandConsumer(async (command) => {
      if (command.type !== "process_pending_alerts") return;
      await runNotificationJob(`redis:${command.reason}`);
    });
    console.log("[NOTIFIER] Redis command consumer listo.");
  } catch (err) {
    console.error("[NOTIFIER] No se pudo conectar a la base de datos:", err);
    process.exit(1);
  }

  cron.schedule("* * * * *", async () => {
    await runNotificationJob("cron");
  });

  console.log("[NOTIFIER] Cron de notificaciones iniciado (cada minuto)");
}

let cronRunning = false;

async function runNotificationJob(trigger: string): Promise<void> {
  if (cronRunning) {
    console.log(
      `[NOTIFIER] Ejecución omitida porque ya hay un proceso activo (${trigger})`,
    );
    return;
  }

  cronRunning = true;
  try {
    const executed = await withNotifierExecutionLock(async () => {
      console.log(`[NOTIFIER] Ejecutando proceso de alertas (${trigger})`);
      await processNotificationCron();
    });

    if (!executed) {
      console.log(`[NOTIFIER] Lock ocupado, se omite corrida (${trigger})`);
    }
  } catch (err) {
    console.error("[NOTIFIER] Error en processNotificationCron:", err);
  } finally {
    cronRunning = false;
  }
}

void startNotifier();

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => {
    void Promise.allSettled([
      closeNotifierCommandConsumer(),
      closeNotifierLockClient(),
    ]).finally(() => process.exit(0));
  });
}

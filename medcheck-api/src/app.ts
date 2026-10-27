import cors from "cors";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import { config } from "./config/config";
import { warmUpPool } from "./config/database";
import "./config/firebase";
import authRoutes from "./routes/auth.routes";
import linkRoutes from "./routes/link.routes";
import notificationRoutes from "./routes/notification.routes";
import sseRoutes from "./routes/sse.routes";
import syncRoutes from "./routes/sync.routes";
import {
  closeRedisUserEvents,
  initRedisUserEvents,
} from "./services/redis.service";
import { deliverToLocalClients } from "./services/sse.service";

dayjs.extend(utc);

const app = express();

app.set("trust proxy", 1);

app.use(cors());
app.use(helmet());
app.use(express.json({ limit: "5mb" }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: "Demasiadas peticiones, intenta más tarde.",
});
app.use("/api/v1", limiter);

app.get("/", (_req, res) => {
  res.json({ message: "MedCheck API is running" });
});

app.get("/api/v1/health", (_req, res) => {
  res.json({ status: "ok", timestamp: dayjs.utc().toISOString() });
});

app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/link", linkRoutes);
app.use("/api/v1/sync", syncRoutes);
app.use("/api/v1/sse", sseRoutes);
app.use("/api/v1", notificationRoutes);

app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    console.error("Error no manejado:", err);
    res.status(500).json({ error: "Error interno del servidor" });
  },
);

(async () => {
  try {
    console.log("[STARTUP] Verificando conexión a la base de datos...");
    await warmUpPool();
    console.log("[STARTUP] Base de datos lista.");
    await initRedisUserEvents((userId, event) => {
      deliverToLocalClients(userId, event);
    });
    console.log("[STARTUP] Redis SSE relay listo.");
  } catch (err) {
    console.error("[STARTUP] No se pudo inicializar el servidor:", err);
    process.exit(1);
  }

  app.listen(config.port, () => {
    console.log(`Servidor funcionando en puerto ${config.port}`);
  });
})();

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => {
    void closeRedisUserEvents().finally(() => process.exit(0));
  });
}

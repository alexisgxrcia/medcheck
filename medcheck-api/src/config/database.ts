import { Pool, type PoolClient } from "pg";
import { config } from "./config";

const { dbhost, dbuser, dbpassword, dbname, dbport, dburi } = config;

const pool = new Pool({
  connectionString: dburi || undefined,
  host: !dburi ? dbhost : undefined,
  user: !dburi ? dbuser : undefined,
  password: !dburi ? dbpassword : undefined,
  database: !dburi ? dbname : undefined,
  port: !dburi ? Number(dbport) || 5432 : undefined,
  max: 8,
  min: 1,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  keepAlive: true,
  allowExitOnIdle: false,
});

pool.on("error", (err) => {
  console.error("Error inesperado en el pool de PostgreSQL:", err);
});

export async function warmUpPool(
  maxRetries = 10,
  initialDelayMs = 1000,
): Promise<void> {
  let delay = initialDelayMs;
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const client = await pool.connect();
      try {
        await client.query("SELECT 1");
        console.log(
          `[DB] Conexión verificada correctamente (intento ${attempt})`,
        );
        return;
      } finally {
        client.release();
      }
    } catch (err) {
      console.warn(
        `[DB] Intento ${attempt}/${maxRetries} falló: ${(err as Error).message}`,
      );
      if (attempt === maxRetries) {
        throw new Error(
          `[DB] No se pudo conectar a la base de datos después de ${maxRetries} intentos`,
        );
      }
      await new Promise((r) => setTimeout(r, delay));
      delay = Math.min(delay * 2, 10000);
    }
  }
}

export const executeQuery = async <T>(
  query: string,
  params: any[] = [],
): Promise<T[]> => {
  const client = await pool.connect();
  try {
    const result = await client.query(query, params);
    return result.rows as T[];
  } catch (error) {
    console.error("Error al ejecutar la consulta:", error);
    throw error;
  } finally {
    client.release();
  }
};

export const executeNonQuery = async (
  query: string,
  params: any[] = [],
): Promise<number> => {
  const client = await pool.connect();
  try {
    const result = await client.query(query, params);
    return result.rowCount || 0;
  } catch (error) {
    console.error("Error al ejecutar la consulta:", error);
    throw error;
  } finally {
    client.release();
  }
};

export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>,
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

process.on("SIGINT", async () => {
  await pool.end();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  await pool.end();
  process.exit(0);
});


import dotenv from "dotenv";

dotenv.config();

const env = process.env.NODE_ENV || "development";
const isProd = env === "production";

function getRequiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`[CONFIG] Missing required environment variable: ${name}`);
  }
  return value;
}

function parseEnvList(...values: Array<string | undefined>): string[] {
  return values
    .flatMap((value) => (value || "").split(","))
    .map((value) => value.trim())
    .filter(Boolean);
}

const dburi = process.env.DATABASE_URL || "";
const jwtSecret = isProd
  ? getRequiredEnv("JWT_SECRET")
  : process.env.JWT_SECRET || "dev-secret-change-in-production";
const googleClientId = isProd
  ? getRequiredEnv("GOOGLE_CLIENT_ID")
  : process.env.GOOGLE_CLIENT_ID || "";
const googleClientIdIos = process.env.GOOGLE_CLIENT_ID_IOS || "";
const googleClientIdAndroid = process.env.GOOGLE_CLIENT_ID_ANDROID || "";
const googleClientIdAndroidAlt = process.env.GOOGLE_CLIENT_ID_ANDROID_ALT || "";
const googleClientIdsAndroid = parseEnvList(
  googleClientIdAndroid,
  googleClientIdAndroidAlt,
);
const firebaseServiceAccount = isProd
  ? getRequiredEnv("FIREBASE_SERVICE_ACCOUNT")
  : process.env.FIREBASE_SERVICE_ACCOUNT || "";
const resendApiKey = isProd
  ? getRequiredEnv("RESEND_API_KEY")
  : process.env.RESEND_API_KEY || "";
const redisUrl = isProd
  ? getRequiredEnv("REDIS_URL")
  : process.env.REDIS_URL || "";

if (isProd && !dburi.trim()) {
  throw new Error(
    "[CONFIG] Missing required environment variable: DATABASE_URL",
  );
}

export const config = {
  env,
  isProd,
  port: Number(process.env.PORT) || 3000,
  dbhost: process.env.DB_HOST || "",
  dbport: process.env.DB_PORT || "",
  dbuser: process.env.DB_USER || "",
  dbpassword: process.env.DB_PASSWORD || "",
  dbname: process.env.DB_NAME || "",
  dburi,
  jwtSecret,
  googleClientId,
  googleClientIdIos,
  googleClientIdAndroid,
  googleClientIdAndroidAlt,
  googleClientIdsAndroid,
  firebaseServiceAccount,
  resendApiKey,
  redisUrl,
};

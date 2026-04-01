import dotenv from "dotenv";

dotenv.config();

function resolveUseLocalDevMode() {
  const raw =
    process.env.USE_LOCAL_DEV_MODE ?? process.env.USE_FIREBASE_EMULATORS;

  if (raw !== undefined) {
    return String(raw).trim().toLowerCase() === "true";
  }

  return (process.env.NODE_ENV || "development") !== "production";
}

export const config = {
  nodeEnv: process.env.NODE_ENV || "development",
  useLocalDevMode: resolveUseLocalDevMode(),
  port: process.env.PORT || 5000,
  apiVersion: process.env.API_VERSION || "v1",
  mongoUri: process.env.MONGO_URI || "mongodb://127.0.0.1:27017",
  mongoDbName: process.env.MONGO_DB_NAME || "vitaltrack",

  // JWT
  jwtSecret: process.env.JWT_SECRET || "dev-secret-key",
  jwtExpire: process.env.JWT_EXPIRE || "7d",

  // OTP
  otpExpiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES || "5", 10),
  otpLength: parseInt(process.env.OTP_LENGTH || "6", 10),

  // PDF storage (local mode by default)
  pdfStorageBucket: process.env.PDF_STORAGE_BUCKET || null,
  storageEmulatorHost:
    process.env.STORAGE_EMULATOR_HOST ||
    process.env.FIREBASE_STORAGE_EMULATOR_HOST ||
    "127.0.0.1:9199",

  // Email
  sendgridApiKey: process.env.SENDGRID_API_KEY,
  notificationEmailFrom: process.env.NOTIFICATION_EMAIL_FROM,
};

export function validateConfig() {
  const isProduction = (process.env.NODE_ENV || "development") === "production";

  const required = isProduction ? ["MONGO_URI", "JWT_SECRET"] : [];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(", ")}`,
    );
  }
}

export default config;

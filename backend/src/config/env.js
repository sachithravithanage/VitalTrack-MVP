import dotenv from "dotenv";

dotenv.config();

function resolveUseFirebaseEmulators() {
  const raw = process.env.USE_FIREBASE_EMULATORS;

  if (raw !== undefined) {
    return String(raw).trim().toLowerCase() === "true";
  }

  return (process.env.NODE_ENV || "development") !== "production";
}

export const config = {
  nodeEnv: process.env.NODE_ENV || "development",
  useFirebaseEmulators: resolveUseFirebaseEmulators(),
  port: process.env.PORT || 5000,
  apiVersion: process.env.API_VERSION || "v1",

  // JWT
  jwtSecret: process.env.JWT_SECRET || "dev-secret-key",
  jwtExpire: process.env.JWT_EXPIRE || "7d",

  // OTP
  otpExpiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES || "5", 10),
  otpLength: parseInt(process.env.OTP_LENGTH || "6", 10),

  // Firebase
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || "vitaltrack-vcode",
  pdfStorageBucket:
    process.env.PDF_STORAGE_BUCKET ||
    `${process.env.FIREBASE_PROJECT_ID || "vitaltrack-vcode"}.appspot.com`,

  // Email
  sendgridApiKey: process.env.SENDGRID_API_KEY,
  notificationEmailFrom: process.env.NOTIFICATION_EMAIL_FROM,
};

export function validateConfig() {
  const isProduction = (process.env.NODE_ENV || "development") === "production";

  const required = isProduction
    ? [
        "FIREBASE_PROJECT_ID",
        "FIREBASE_PRIVATE_KEY",
        "FIREBASE_CLIENT_EMAIL",
        "JWT_SECRET",
      ]
    : [];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(", ")}`,
    );
  }
}

export default config;

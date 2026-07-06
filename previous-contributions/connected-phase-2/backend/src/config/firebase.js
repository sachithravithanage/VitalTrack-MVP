import admin from "firebase-admin";
import dotenv from "dotenv";
import { config } from "./env.js";

dotenv.config();

const firebaseConfig = {
  projectId: process.env.FIREBASE_PROJECT_ID,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
};

if (config.useFirebaseEmulators) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST ||= "127.0.0.1:9099";
  process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ||= "127.0.0.1:9199";
}

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  if (config.useFirebaseEmulators) {
    admin.initializeApp({
      projectId: firebaseConfig.projectId || "vitaltrack-vcode",
      storageBucket: config.pdfStorageBucket,
    });
  } else {
    admin.initializeApp({
      credential: admin.credential.cert(firebaseConfig),
      databaseURL: firebaseConfig.databaseURL,
      storageBucket: config.pdfStorageBucket,
    });
  }
}

export const db = admin.firestore();
export const auth = admin.auth();
export const bucket = config.pdfStorageBucket
  ? admin.storage().bucket(config.pdfStorageBucket)
  : null;
export const messaging = admin.messaging();

export default admin;

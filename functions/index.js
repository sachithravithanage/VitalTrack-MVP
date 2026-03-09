const functions = require("firebase-functions");
const admin = require("firebase-admin");
const PDFDocument = require("pdfkit"); // npm install pdfkit
const { v4: uuidv4 } = require("uuid"); // npm install uuid

admin.initializeApp();
const firestore = admin.firestore();
const adminStorage = admin.storage();

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication is required",
    );
  }
  return context.auth.uid;
}

async function isCaregiverLinkedToPatient(caregiverId, patientId) {
  const linkSnapshot = await firestore
    .collection("patient_links")
    .where("caregiverId", "==", caregiverId)
    .where("patientId", "==", patientId)
    .limit(1)
    .get();

  return !linkSnapshot.empty;
}

async function canAccessPatientData(uid, patientId) {
  if (uid === patientId) return true;
  return isCaregiverLinkedToPatient(uid, patientId);
}

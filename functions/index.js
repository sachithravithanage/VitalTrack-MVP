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

/////////////////////////////////////////
// Generate Caregiver Code
/////////////////////////////////////////
exports.generateCaregiverCode = functions.https.onCall(
  async (data, context) => {
    const uid = requireAuth(context);
    const { patientId } = data;
    if (!patientId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing patientId",
      );
    }

    if (uid !== patientId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only the patient can generate their caregiver code",
      );
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    await firestore
      .collection("users")
      .doc(patientId)
      .update({ caregiverCode: code });
    return { caregiverCode: code };
  },
);

/////////////////////////////////////////
// Link Caregiver to Patient
/////////////////////////////////////////
exports.linkCaregiverToPatient = functions.https.onCall(
  async (data, context) => {
    const uid = requireAuth(context);
    const { caregiverId, code } = data;
    if (!caregiverId || !code) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing caregiverId or code",
      );
    }

    if (uid !== caregiverId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Authenticated user must match caregiverId",
      );
    }

    const patientSnapshot = await firestore
      .collection("users")
      .where("caregiverCode", "==", code)
      .limit(1)
      .get();

    if (patientSnapshot.empty) {
      throw new functions.https.HttpsError(
        "not-found",
        "Invalid caregiver code",
      );
    }

    const patientDoc = patientSnapshot.docs[0];
    const patientId = patientDoc.id;

    await firestore.collection("patient_links").add({ patientId, caregiverId });
    await firestore
      .collection("users")
      .doc(caregiverId)
      .update({ linkedPatient: patientId });

    return { success: true, patientId };
  },
);

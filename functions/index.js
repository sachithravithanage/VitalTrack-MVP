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

/////////////////////////////////////////
// Submit Symptom Log (Normal)
/////////////////////////////////////////
exports.submitSymptomLog = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const {
    patientId,
    disease,
    temperature,
    fluidIntake,
    urineOutput,
    musclePain,
    urineColor,
    dangerSigns,
  } = data;
  if (!patientId || !disease) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields",
    );
  }

  const allowed = await canAccessPatientData(uid, patientId);
  if (!allowed) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the patient or linked caregiver can submit logs",
    );
  }

  const logRef = await firestore.collection("symptom_logs").add({
    patientId,
    disease,
    temperature: temperature || null,
    fluidIntake: fluidIntake || null,
    urineOutput: urineOutput || null,
    musclePain: musclePain || null,
    urineColor: urineColor || null,
    dangerSigns: dangerSigns || false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    triage: "Green",
  });

  return { success: true, logId: logRef.id };
});

/////////////////////////////////////////
// Submit Voice-to-Text Symptom Log
/////////////////////////////////////////
exports.submitVoiceSymptomLog = functions.https.onCall(
  async (data, context) => {
    const uid = requireAuth(context);
    const { patientId, disease, voiceInput } = data;
    if (!patientId || !disease || !voiceInput) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields",
      );
    }

    const allowed = await canAccessPatientData(uid, patientId);
    if (!allowed) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only the patient or linked caregiver can submit voice logs",
      );
    }

    const logRef = await firestore.collection("symptom_logs").add({
      patientId,
      disease,
      voiceInput,
      dangerSigns: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      triage: "Green",
    });

    // Optional: auto-detect danger signs from keywords
    const dangerKeywords = ["bleeding", "severe pain", "jaundice", "hospital"];
    const detectedDanger = dangerKeywords.some((word) =>
      voiceInput.toLowerCase().includes(word),
    );
    if (detectedDanger) {
      await logRef.update({ dangerSigns: true });
    }

    return { success: true, logId: logRef.id };
  },
);

/////////////////////////////////////////
// Automatic Triage
/////////////////////////////////////////
exports.checkTriage = functions.firestore
  .document("symptom_logs/{logId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    let triage = "Green";

    if (data.disease === "dengue") {
      if (data.dangerSigns || data.temperature > 40 || data.urineOutput < 300)
        triage = "Red";
      else if (data.temperature >= 39 || data.urineOutput < 400)
        triage = "Yellow";
    } else if (data.disease === "rat_fever") {
      if (
        data.dangerSigns ||
        data.musclePain === "severe" ||
        data.urineColor === "dark"
      )
        triage = "Red";
      else if (data.musclePain === "moderate" || data.urineColor === "brownish")
        triage = "Yellow";
    }

    await snap.ref.update({ triage });

    if (triage === "Red") {
      await firestore.collection("alerts").add({
        patientId: data.patientId,
        level: "RED",
        message: "Immediate hospital visit required",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

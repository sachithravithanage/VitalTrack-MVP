const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const PDFDocument = require("pdfkit");
const { v4: uuidv4 } = require("uuid");

admin.initializeApp();
const firestore = admin.firestore();
const adminStorage = admin.storage();

// ─────────────────────────────────────────────
// Auth helpers
// ─────────────────────────────────────────────

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

async function getPatientProfile(patientId) {
  const patientDoc = await firestore.collection("users").doc(patientId).get();
  if (!patientDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Patient not found");
  }

  const patientData = patientDoc.data();
  if (patientData.role !== "patient") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Specified patientId does not belong to a patient",
    );
  }

  return patientData;
}

async function assertPatientAssignedDisease(patientId, expectedDisease) {
  const patientData = await getPatientProfile(patientId);
  if (!patientData.assignedDisease) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Patient does not have an assigned disease",
    );
  }

  if (patientData.assignedDisease !== expectedDisease) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Patient is assigned to ${patientData.assignedDisease} tracking, not ${expectedDisease}`,
    );
  }

  return patientData;
}

// ─────────────────────────────────────────────
// Triage helpers
// ─────────────────────────────────────────────

/**
 * Dengue triage rules based on the full tracking list.
 *
 * RED  – any danger sign confirmed, very high temp, very low urine output,
 *        active bleeding, extreme mental state change, or severe abdominal pain.
 * YELLOW – elevated temp, reduced urine output, moderate symptoms.
 * GREEN – everything else.
 */
function triageDengue(d) {
  const redConditions =
    d.dangerSigns === true ||
    (d.temperature != null && d.temperature > 40) ||
    (d.urineOutput != null && d.urineOutput < 300) ||
    d.bleedingPresent === true ||
    d.mentalStateChange === true ||
    d.abdominalPainSeverity === "severe";

  if (redConditions) return "Red";

  const yellowConditions =
    (d.temperature != null && d.temperature >= 38.5) ||
    (d.urineOutput != null && d.urineOutput < 500) ||
    (d.vomitingEpisodes != null && d.vomitingEpisodes >= 3) ||
    d.abdominalPainSeverity === "moderate";

  if (yellowConditions) return "Yellow";

  return "Green";
}

/**
 * Rat fever (Leptospirosis) triage rules based on the full tracking list.
 *
 * RED  – any danger sign, severe muscle pain, dark urine, jaundice,
 *        respiratory symptoms, or neurological symptoms.
 * YELLOW – moderate muscle pain, brownish urine, second temperature spike.
 * GREEN – everything else.
 */
function triageRatFever(d) {
  const redConditions =
    d.dangerSigns === true ||
    d.musclePainSeverity === "severe" ||
    d.urineColor === "dark" ||
    d.urineColor === "blood_tinged" ||
    d.jaundicePresent === true ||
    d.respiratorySymptoms === true ||
    d.neurologicalSymptoms === true;

  if (redConditions) return "Red";

  const yellowConditions =
    d.musclePainSeverity === "moderate" ||
    d.urineColor === "tea_colored" ||
    d.urineColor === "brownish" ||
    d.secondTemperatureSpike === true ||
    d.urineFrequencyDecreased === true;

  if (yellowConditions) return "Yellow";

  return "Green";
}

function computeTriage(data) {
  if (data.disease === "dengue") return triageDengue(data);
  if (data.disease === "rat_fever") return triageRatFever(data);
  return "Green";
}

// ─────────────────────────────────────────────
// Generate Caregiver Code
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// Link Caregiver to Patient  (caregiver-initiated, using patient's 6-digit code)
// A caregiver can be linked to MULTIPLE patients.
// A patient can have MULTIPLE caregivers.
// Duplicate links are prevented by the duplicate-check below.
// ─────────────────────────────────────────────
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

    // Resolve patient from code
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

    const patientId = patientSnapshot.docs[0].id;

    // Prevent duplicate links
    const alreadyLinked = await isCaregiverLinkedToPatient(
      caregiverId,
      patientId,
    );
    if (alreadyLinked) {
      return { success: false, reason: "already_linked", patientId };
    }

    // Create link document – one doc per caregiver–patient pair
    await firestore.collection("patient_links").add({
      patientId,
      caregiverId,
      linkedAt: FieldValue.serverTimestamp(),
    });

    // Keep a denormalised list on the caregiver doc for fast reads
    await firestore
      .collection("users")
      .doc(caregiverId)
      .update({
        linkedPatients: FieldValue.arrayUnion(patientId),
      });

    // Keep a denormalised list on the patient doc for fast reads
    await firestore
      .collection("users")
      .doc(patientId)
      .update({
        linkedCaregivers: FieldValue.arrayUnion(caregiverId),
      });

    return { success: true, patientId };
  },
);

// ─────────────────────────────────────────────
// Caregiver: get all linked patients with basic profile
// ─────────────────────────────────────────────
exports.getCaregiverPatients = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const { caregiverId } = data;
  if (!caregiverId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing caregiverId",
    );
  }
  if (uid !== caregiverId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Authenticated user must match caregiverId",
    );
  }

  const links = await firestore
    .collection("patient_links")
    .where("caregiverId", "==", caregiverId)
    .get();

  if (links.empty) return { patients: [] };

  const patientDocs = await Promise.all(
    links.docs.map((l) =>
      firestore.collection("users").doc(l.data().patientId).get(),
    ),
  );

  const patients = patientDocs
    .filter((d) => d.exists)
    .map((d) => ({
      patientId: d.id,
      email: d.data().email || null,
      displayName: d.data().displayName || null,
      assignedDisease: d.data().assignedDisease || null,
    }));

  return { patients };
});

// ─────────────────────────────────────────────
// Patient: get all linked caregivers with basic profile
// ─────────────────────────────────────────────
exports.getPatientCaregivers = functions.https.onCall(async (data, context) => {
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
      "Authenticated user must match patientId",
    );
  }

  const links = await firestore
    .collection("patient_links")
    .where("patientId", "==", patientId)
    .get();

  if (links.empty) return { caregivers: [] };

  const caregiverDocs = await Promise.all(
    links.docs.map((l) =>
      firestore.collection("users").doc(l.data().caregiverId).get(),
    ),
  );

  const caregivers = caregiverDocs
    .filter((d) => d.exists)
    .map((d) => ({
      caregiverId: d.id,
      email: d.data().email || null,
      displayName: d.data().displayName || null,
    }));

  return { caregivers };
});

// ─────────────────────────────────────────────
// Submit Symptom Log – Dengue
//
// Dengue tracking fields:
//   fluidIntakeVolume (ml)       – total fluid consumed
//   fluidIntakeType (string)     – e.g. "water", "ORS", "juice"
//   urineOutput (ml)             – estimated volume per day
//   urineFrequency (number)      – times per day
//   temperature (°C)
//   bleedingPresent (yes/no bool)
//   abdominalPainPresent (bool)
//   abdominalPainSeverity        – "none" | "mild" | "moderate" | "severe"
//   vomitingEpisodes (number)    – count in last 24 h
//   mentalStateChange (bool)     – extreme lethargy/confusion/restlessness
//   dangerSigns (bool)           – overall clinician danger flag
// ─────────────────────────────────────────────
exports.submitDengueLog = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const { patientId } = data;
  if (!patientId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing patientId",
    );
  }

  const allowed = await canAccessPatientData(uid, patientId);
  if (!allowed) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the patient or a linked caregiver can submit logs",
    );
  }

  await assertPatientAssignedDisease(patientId, "dengue");

  const logData = {
    patientId,
    disease: "dengue",
    submittedBy: uid,
    // Fluid
    fluidIntakeVolume:
      data.fluidIntakeVolume != null ? data.fluidIntakeVolume : null,
    fluidIntakeType: data.fluidIntakeType || null,
    // Urine
    urineOutput: data.urineOutput != null ? data.urineOutput : null,
    urineFrequency: data.urineFrequency != null ? data.urineFrequency : null,
    // Temperature
    temperature: data.temperature != null ? data.temperature : null,
    // Bleeding (yes/no)
    bleedingPresent: data.bleedingPresent === true,
    // Abdominal pain
    abdominalPainPresent: data.abdominalPainPresent === true,
    abdominalPainSeverity: data.abdominalPainSeverity || "none",
    // Vomiting
    vomitingEpisodes: data.vomitingEpisodes != null ? data.vomitingEpisodes : 0,
    // Mental state
    mentalStateChange: data.mentalStateChange === true,
    // Overall danger flag
    dangerSigns: data.dangerSigns === true,
    // Notes
    notes: data.notes || null,
    timestamp: FieldValue.serverTimestamp(),
    triage: "Green", // overwritten immediately by checkTriage trigger
  };

  const logRef = await firestore.collection("symptom_logs").add(logData);
  return { success: true, logId: logRef.id };
});

// ─────────────────────────────────────────────
// Submit Symptom Log – Rat Fever (Leptospirosis)
//
// Rat fever tracking fields:
//   urineOutput (ml)
//   urineFrequency (number)
//   urineFrequencyDecreased (bool)  – sudden decrease vs. baseline
//   urineColor                      – "normal" | "tea_colored" | "brownish" | "dark" | "blood_tinged"
//   temperature (°C)
//   secondTemperatureSpike (bool)   – fever dropped then spiked again
//   musclePainPresent (bool)
//   musclePainSeverity              – "none" | "mild" | "moderate" | "severe"
//   musclePainLocation              – e.g. "calves", "thighs", "lower_back", or combination string
//   jaundicePresent (bool)          – yellowing of eyes/skin
//   respiratorySymptoms (bool)      – cough or shortness of breath
//   neurologicalSymptoms (bool)     – severe headache or stiff neck
//   dangerSigns (bool)
// ─────────────────────────────────────────────
exports.submitRatFeverLog = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const { patientId } = data;
  if (!patientId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing patientId",
    );
  }

  const allowed = await canAccessPatientData(uid, patientId);
  if (!allowed) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the patient or a linked caregiver can submit logs",
    );
  }

  await assertPatientAssignedDisease(patientId, "rat_fever");

  const logData = {
    patientId,
    disease: "rat_fever",
    submittedBy: uid,
    // Urine
    urineOutput: data.urineOutput != null ? data.urineOutput : null,
    urineFrequency: data.urineFrequency != null ? data.urineFrequency : null,
    urineFrequencyDecreased: data.urineFrequencyDecreased === true,
    urineColor: data.urineColor || "normal",
    // Temperature
    temperature: data.temperature != null ? data.temperature : null,
    secondTemperatureSpike: data.secondTemperatureSpike === true,
    // Muscle pain
    musclePainPresent: data.musclePainPresent === true,
    musclePainSeverity: data.musclePainSeverity || "none",
    musclePainLocation: data.musclePainLocation || null,
    // Jaundice (yes/no)
    jaundicePresent: data.jaundicePresent === true,
    // Respiratory (yes/no)
    respiratorySymptoms: data.respiratorySymptoms === true,
    // Neurological (yes/no)
    neurologicalSymptoms: data.neurologicalSymptoms === true,
    // Overall danger flag
    dangerSigns: data.dangerSigns === true,
    // Notes
    notes: data.notes || null,
    timestamp: FieldValue.serverTimestamp(),
    triage: "Green", // overwritten immediately by checkTriage trigger
  };

  const logRef = await firestore.collection("symptom_logs").add(logData);
  return { success: true, logId: logRef.id };
});

// ─────────────────────────────────────────────
// Submit Voice-to-Text Symptom Log (disease-agnostic)
// ─────────────────────────────────────────────
exports.submitVoiceSymptomLog = functions.https.onCall(
  async (data, context) => {
    const uid = requireAuth(context);
    const { patientId, disease, voiceInput } = data;
    if (!patientId || !disease || !voiceInput) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: patientId, disease, voiceInput",
      );
    }
    if (!["dengue", "rat_fever"].includes(disease)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "disease must be 'dengue' or 'rat_fever'",
      );
    }

    const allowed = await canAccessPatientData(uid, patientId);
    if (!allowed) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only the patient or a linked caregiver can submit voice logs",
      );
    }

    await assertPatientAssignedDisease(patientId, disease);

    // Keyword-based auto-detection of danger signs
    const dangerKeywords = [
      "bleeding",
      "severe pain",
      "jaundice",
      "hospital",
      "unconscious",
      "confusion",
      "shortness of breath",
      "stiff neck",
    ];
    const detectedDanger = dangerKeywords.some((word) =>
      voiceInput.toLowerCase().includes(word),
    );

    const logRef = await firestore.collection("symptom_logs").add({
      patientId,
      disease,
      submittedBy: uid,
      voiceInput,
      dangerSigns: detectedDanger,
      timestamp: FieldValue.serverTimestamp(),
      triage: "Green",
    });

    return {
      success: true,
      logId: logRef.id,
      dangerSignsDetected: detectedDanger,
    };
  },
);

// ─────────────────────────────────────────────
// Automatic Triage (Firestore trigger)
// ─────────────────────────────────────────────
exports.checkTriage = functions.firestore
  .document("symptom_logs/{logId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const triage = computeTriage(data);

    await snap.ref.update({ triage });

    if (triage === "Red") {
      await firestore.collection("alerts").add({
        patientId: data.patientId,
        disease: data.disease,
        level: "RED",
        message: "Immediate hospital visit required",
        logId: snap.id,
        timestamp: FieldValue.serverTimestamp(),
      });
    } else if (triage === "Yellow") {
      await firestore.collection("alerts").add({
        patientId: data.patientId,
        disease: data.disease,
        level: "YELLOW",
        message: "Monitor closely – symptoms are worsening",
        logId: snap.id,
        timestamp: FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

// ─────────────────────────────────────────────
// Emergency Push Notifications
// ─────────────────────────────────────────────
exports.sendEmergencyNotification = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const alertData = snap.data();
    const { patientId, message, level } = alertData;
    if (!patientId) return null;

    const patientDoc = await firestore.collection("users").doc(patientId).get();
    const patientToken = patientDoc.data()?.fcmToken;

    const caregiverLinks = await firestore
      .collection("patient_links")
      .where("patientId", "==", patientId)
      .get();

    const caregiverTokenPromises = caregiverLinks.docs.map((linkDoc) =>
      firestore
        .collection("users")
        .doc(linkDoc.data().caregiverId)
        .get()
        .then((doc) => doc.data()?.fcmToken),
    );

    const allTokens = [];
    if (patientToken) allTokens.push(patientToken);
    const caregiverTokens = await Promise.all(caregiverTokenPromises);
    caregiverTokens.forEach((t) => {
      if (t) allTokens.push(t);
    });

    if (allTokens.length === 0) return null;

    const payload = {
      notification: {
        title:
          level === "RED"
            ? "VitalTrack Emergency Alert!"
            : "VitalTrack Warning",
        body: message || "Please check the patient's condition",
        sound: "default",
      },
    };

    try {
      await admin.messaging().sendToDevice(allTokens, payload);
    } catch (err) {
      console.error("Error sending push notifications:", err);
    }

    return null;
  });

// ─────────────────────────────────────────────
// PDF Report Generation
// ─────────────────────────────────────────────
exports.generatePDFReport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const { patientId, startDate, endDate } = data;
  if (!patientId || !startDate || !endDate) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing parameters",
    );
  }

  const allowed = await canAccessPatientData(uid, patientId);
  if (!allowed) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the patient or linked caregiver can export reports",
    );
  }

  const start = new Date(startDate);
  const end = new Date(endDate);

  const logsSnapshot = await firestore
    .collection("symptom_logs")
    .where("patientId", "==", patientId)
    .where("timestamp", ">=", start)
    .where("timestamp", "<=", end)
    .orderBy("timestamp")
    .get();

  if (logsSnapshot.empty) {
    throw new functions.https.HttpsError("not-found", "No logs found");
  }

  const doc = new PDFDocument();

  doc.fontSize(18).text("VitalTrack Health Report", { align: "center" });
  doc.moveDown();

  logsSnapshot.forEach((logDoc) => {
    const log = logDoc.data();
    const date = log.timestamp
      ? log.timestamp.toDate().toLocaleString()
      : "N/A";
    doc
      .fontSize(13)
      .text(
        `── ${log.disease === "dengue" ? "Dengue Fever" : "Rat Fever"} Log ──`,
        { underline: true },
      );
    doc
      .fontSize(11)
      .text(`Date: ${date}`)
      .text(`Triage: ${log.triage}`)
      .text(`Danger Signs: ${log.dangerSigns ? "Yes" : "No"}`);

    if (log.disease === "dengue") {
      doc
        .text(
          `Temperature: ${log.temperature != null ? log.temperature + " °C" : "N/A"}`,
        )
        .text(
          `Fluid Intake: ${log.fluidIntakeVolume != null ? log.fluidIntakeVolume + " ml" : "N/A"} (${log.fluidIntakeType || "N/A"})`,
        )
        .text(
          `Urine Output: ${log.urineOutput != null ? log.urineOutput + " ml" : "N/A"}`,
        )
        .text(
          `Urine Frequency: ${log.urineFrequency != null ? log.urineFrequency + " times/day" : "N/A"}`,
        )
        .text(`Bleeding Present: ${log.bleedingPresent ? "Yes" : "No"}`)
        .text(
          `Abdominal Pain: ${log.abdominalPainPresent ? "Yes" : "No"} (${log.abdominalPainSeverity || "N/A"})`,
        )
        .text(
          `Vomiting Episodes (24h): ${log.vomitingEpisodes != null ? log.vomitingEpisodes : "N/A"}`,
        )
        .text(`Mental State Change: ${log.mentalStateChange ? "Yes" : "No"}`);
    } else if (log.disease === "rat_fever") {
      doc
        .text(
          `Temperature: ${log.temperature != null ? log.temperature + " °C" : "N/A"}`,
        )
        .text(`Second Temp Spike: ${log.secondTemperatureSpike ? "Yes" : "No"}`)
        .text(
          `Urine Output: ${log.urineOutput != null ? log.urineOutput + " ml" : "N/A"}`,
        )
        .text(
          `Urine Frequency: ${log.urineFrequency != null ? log.urineFrequency + " times/day" : "N/A"}`,
        )
        .text(
          `Urine Frequency Decreased: ${log.urineFrequencyDecreased ? "Yes" : "No"}`,
        )
        .text(`Urine Color: ${log.urineColor || "N/A"}`)
        .text(
          `Muscle Pain: ${log.musclePainPresent ? "Yes" : "No"} (${log.musclePainSeverity || "N/A"}) – ${log.musclePainLocation || "N/A"}`,
        )
        .text(`Jaundice: ${log.jaundicePresent ? "Yes" : "No"}`)
        .text(`Respiratory Symptoms: ${log.respiratorySymptoms ? "Yes" : "No"}`)
        .text(
          `Neurological Symptoms: ${log.neurologicalSymptoms ? "Yes" : "No"}`,
        );
    }

    if (log.voiceInput) doc.text(`Voice Notes: ${log.voiceInput}`);
    if (log.notes) doc.text(`Notes: ${log.notes}`);
    doc.moveDown();
  });

  doc.end();

  const pdfBuffer = await new Promise((resolve) => {
    const chunks = [];
    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
  });

  const fileName = `reports/${patientId}_${uuidv4()}.pdf`;
  const file = adminStorage.bucket().file(fileName);

  await file.save(pdfBuffer, {
    contentType: "application/pdf",
    resumable: false,
  });

  if (process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
    const emulatorHost = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
    const encodedFileName = encodeURIComponent(fileName);
    const emulatorUrl = `http://${emulatorHost}/v0/b/${file.bucket.name}/o/${encodedFileName}?alt=media`;
    return { downloadUrl: emulatorUrl };
  }

  const [url] = await file.getSignedUrl({
    action: "read",
    expires: Date.now() + 1000 * 60 * 60 * 24,
  });

  return { downloadUrl: url };
});

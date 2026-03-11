"use strict";

const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const PROJECT_ID = "vitaltrack-vcode";
const REGION = "us-central1";
const AUTH_EMULATOR_HOST = "127.0.0.1:9099";
const FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
const FUNCTIONS_BASE_URL = `http://127.0.0.1:5001/${PROJECT_ID}/${REGION}`;

process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_EMULATOR_HOST;
process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;
process.env.GCLOUD_PROJECT = PROJECT_ID;

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

function logStep(step, message) {
  console.log(`\n[${step}] ${message}`);
}

async function authRequest(endpoint, body) {
  const url = `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/${endpoint}?key=fake-api-key`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const json = await res.json();
  if (!res.ok) {
    const msg = json?.error?.message || JSON.stringify(json);
    throw new Error(`Auth request failed (${endpoint}): ${msg}`);
  }
  return json;
}

async function signUp(email, password) {
  const result = await authRequest("accounts:signUp", {
    email,
    password,
    returnSecureToken: true,
  });

  return {
    uid: result.localId,
    idToken: result.idToken,
    refreshToken: result.refreshToken,
  };
}

async function signIn(email, password) {
  const result = await authRequest("accounts:signInWithPassword", {
    email,
    password,
    returnSecureToken: true,
  });

  return {
    uid: result.localId,
    idToken: result.idToken,
    refreshToken: result.refreshToken,
  };
}

async function callFunction(functionName, data, idToken) {
  const res = await fetch(`${FUNCTIONS_BASE_URL}/${functionName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ data }),
  });

  const raw = await res.text();
  let json;
  try {
    json = raw ? JSON.parse(raw) : {};
  } catch (err) {
    throw new Error(
      `${functionName} failed: non-JSON response (status ${res.status}) -> ${raw}`,
    );
  }

  if (!res.ok || json.error) {
    const msg = json?.error?.message || JSON.stringify(json);
    throw new Error(`${functionName} failed: ${msg}`);
  }

  return json.result;
}

async function waitForFunctionsReady(functionName, timeoutMs = 30000) {
  const started = Date.now();

  while (Date.now() - started < timeoutMs) {
    try {
      const res = await fetch(`${FUNCTIONS_BASE_URL}/${functionName}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: {} }),
      });

      const raw = await res.text();
      let parsed;
      try {
        parsed = raw ? JSON.parse(raw) : {};
      } catch (err) {
        parsed = null;
      }

      // Once callable endpoint is loaded, it responds with JSON
      // (typically unauthenticated for this probe).
      if (parsed && (parsed.error || parsed.result || res.ok)) {
        return;
      }
    } catch (err) {
      // Ignore transient startup failures during warm-up polling.
    }

    await wait(1000);
  }

  throw new Error(
    `Functions emulator not ready after ${timeoutMs}ms for ${functionName}`,
  );
}

async function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function run() {
  const patientEmail = "patient.local@vitaltrack.test";
  const caregiverEmail = "caregiver.local@vitaltrack.test";
  const password = "Password123!";

  let patient;
  let caregiver;

  logStep("0", "Wait for Functions emulator readiness");
  await waitForFunctionsReady("generateCaregiverCode");
  console.log("functions emulator: ready");

  logStep("1", "Sign up patient");
  patient = await signUp(patientEmail, password);
  console.log(`patient uid: ${patient.uid}`);

  await db.collection("users").doc(patient.uid).set({
    email: patientEmail,
    role: "patient",
    createdAt: FieldValue.serverTimestamp(),
  });

  logStep("2", "Patient login");
  patient = await signIn(patientEmail, password);
  console.log("patient login: ok");

  logStep("3", "Generate caregiver code");
  const codeResult = await callFunction(
    "generateCaregiverCode",
    { patientId: patient.uid },
    patient.idToken,
  );
  const caregiverCode = codeResult.caregiverCode;
  console.log(`caregiver code: ${caregiverCode}`);

  logStep("4", "Sign up caregiver");
  caregiver = await signUp(caregiverEmail, password);
  console.log(`caregiver uid: ${caregiver.uid}`);

  await db.collection("users").doc(caregiver.uid).set({
    email: caregiverEmail,
    role: "caregiver",
    createdAt: FieldValue.serverTimestamp(),
  });

  logStep("5", "Caregiver login");
  caregiver = await signIn(caregiverEmail, password);
  console.log("caregiver login: ok");

  logStep("6", "Link caregiver to patient");
  const linkResult = await callFunction(
    "linkCaregiverToPatient",
    { caregiverId: caregiver.uid, code: caregiverCode },
    caregiver.idToken,
  );
  console.log(`linked patient: ${linkResult.patientId}`);

  logStep("7", "Patient submits normal symptom log");
  const logA = await callFunction(
    "submitSymptomLog",
    {
      patientId: patient.uid,
      disease: "dengue",
      temperature: 39.3,
      fluidIntake: 1800,
      urineOutput: 390,
      musclePain: "moderate",
      urineColor: "normal",
      dangerSigns: false,
    },
    patient.idToken,
  );
  console.log(`symptom log id: ${logA.logId}`);

  logStep("8", "Patient submits voice symptom log");
  const logB = await callFunction(
    "submitVoiceSymptomLog",
    {
      patientId: patient.uid,
      disease: "dengue",
      voiceInput: "I have severe pain and dizziness",
    },
    patient.idToken,
  );
  console.log(`voice log id: ${logB.logId}`);

  logStep("9", "Caregiver submits severe symptom log");
  const logC = await callFunction(
    "submitSymptomLog",
    {
      patientId: patient.uid,
      disease: "dengue",
      temperature: 40.2,
      fluidIntake: 1200,
      urineOutput: 280,
      musclePain: "severe",
      urineColor: "dark",
      dangerSigns: true,
    },
    caregiver.idToken,
  );
  console.log(`caregiver log id: ${logC.logId}`);

  logStep("10", "Wait for Firestore triggers (triage + alerts)");
  await wait(3000);

  const triageDoc = await db.collection("symptom_logs").doc(logC.logId).get();
  console.log(`triage for severe log: ${triageDoc.data()?.triage}`);

  const alerts = await db
    .collection("alerts")
    .where("patientId", "==", patient.uid)
    .get();
  console.log(`alerts generated: ${alerts.size}`);

  logStep("11", "Generate PDF as patient");
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  try {
    const pdfAsPatient = await callFunction(
      "generatePDFReport",
      {
        patientId: patient.uid,
        startDate: sevenDaysAgo.toISOString(),
        endDate: now.toISOString(),
      },
      patient.idToken,
    );
    console.log(`patient PDF url: ${pdfAsPatient.downloadUrl}`);
  } catch (err) {
    console.log("patient PDF generation failed (see reason below):");
    console.log(err.message);
  }

  logStep("12", "Generate PDF as caregiver");
  try {
    const pdfAsCaregiver = await callFunction(
      "generatePDFReport",
      {
        patientId: patient.uid,
        startDate: sevenDaysAgo.toISOString(),
        endDate: now.toISOString(),
      },
      caregiver.idToken,
    );
    console.log(`caregiver PDF url: ${pdfAsCaregiver.downloadUrl}`);
  } catch (err) {
    console.log("caregiver PDF generation failed (see reason below):");
    console.log(err.message);
  }

  logStep("DONE", "All callable flows executed");
  console.log(
    "If PDF failed, check Storage emulator/bucket configuration and generatePDFReport implementation.",
  );
}

run().catch((err) => {
  console.error("\nTest run failed:");
  console.error(err.message);
  process.exitCode = 1;
});

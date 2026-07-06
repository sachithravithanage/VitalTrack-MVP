/**
 * VitalTrack – end-to-end population script
 *
 * Users created:
 *   Patients  : Alice (dengue), Bob (rat fever), Carol (dengue), Farah (rat fever)
 *   Caregivers: Dave (linked to Alice + Carol), Eve (linked to Bob + Carol + Farah)
 *
 * What gets populated:
 *   users            – 6 documents
 *   patient_links    – 5 documents
 *   symptom_logs     – 16 documents (separate single-disease patients)
 *   alerts           – created automatically by checkTriage trigger (Red + Yellow)
 */

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

async function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
  return { uid: result.localId, idToken: result.idToken };
}

async function signIn(email, password) {
  const result = await authRequest("accounts:signInWithPassword", {
    email,
    password,
    returnSecureToken: true,
  });
  return { uid: result.localId, idToken: result.idToken };
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
  } catch {
    throw new Error(
      `${functionName}: non-JSON response (${res.status}) -> ${raw}`,
    );
  }
  if (!res.ok || json.error) {
    const msg = json?.error?.message || JSON.stringify(json);
    throw new Error(`${functionName} failed: ${msg}`);
  }
  return json.result;
}

async function waitForFunctionsReady(timeoutMs = 40000) {
  const probe = "generateCaregiverCode";
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    try {
      const res = await fetch(`${FUNCTIONS_BASE_URL}/${probe}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: {} }),
      });
      const raw = await res.text();
      const parsed = raw ? JSON.parse(raw) : null;
      if (parsed && (parsed.error || parsed.result !== undefined || res.ok))
        return;
    } catch {
      /* emulator still starting */
    }
    await wait(1000);
  }
  throw new Error(`Functions emulator not ready after ${timeoutMs}ms`);
}

async function createUser(
  email,
  password,
  role,
  displayName,
  assignedDisease = null,
) {
  const user = await signUp(email, password);
  await db.collection("users").doc(user.uid).set({
    email,
    displayName,
    role,
    assignedDisease,
    createdAt: FieldValue.serverTimestamp(),
  });
  const refreshed = await signIn(email, password);
  return {
    uid: user.uid,
    idToken: refreshed.idToken,
    displayName,
    assignedDisease,
  };
}

async function linkCaregiverToPatient(patient, caregiver) {
  const codeRes = await callFunction(
    "generateCaregiverCode",
    { patientId: patient.uid },
    patient.idToken,
  );
  const linkRes = await callFunction(
    "linkCaregiverToPatient",
    { caregiverId: caregiver.uid, code: codeRes.caregiverCode },
    caregiver.idToken,
  );
  console.log(
    `    linked ${caregiver.displayName} -> ${patient.displayName} (code ${codeRes.caregiverCode})`,
  );
  return linkRes;
}

async function run() {
  logStep("0", "Waiting for Functions emulator...");
  await waitForFunctionsReady();
  console.log("  emulator ready");

  logStep("1", "Creating users (4 patients, 2 caregivers)");
  const alice = await createUser(
    "alice@vitaltrack.test",
    "Password123!",
    "patient",
    "Alice",
    "dengue",
  );
  const bob = await createUser(
    "bob@vitaltrack.test",
    "Password123!",
    "patient",
    "Bob",
    "rat_fever",
  );
  const carol = await createUser(
    "carol@vitaltrack.test",
    "Password123!",
    "patient",
    "Carol",
    "dengue",
  );
  const farah = await createUser(
    "farah@vitaltrack.test",
    "Password123!",
    "patient",
    "Farah",
    "rat_fever",
  );
  const dave = await createUser(
    "dave@vitaltrack.test",
    "Password123!",
    "caregiver",
    "Dave",
  );
  const eve = await createUser(
    "eve@vitaltrack.test",
    "Password123!",
    "caregiver",
    "Eve",
  );
  console.log(
    `  alice: ${alice.uid} (${alice.assignedDisease})  bob: ${bob.uid} (${bob.assignedDisease})`,
  );
  console.log(
    `  carol: ${carol.uid} (${carol.assignedDisease})  farah: ${farah.uid} (${farah.assignedDisease})`,
  );
  console.log(`  dave : ${dave.uid}  eve : ${eve.uid}`);

  logStep("2", "Linking caregivers to patients");
  await linkCaregiverToPatient(alice, dave);
  await linkCaregiverToPatient(carol, dave);
  await linkCaregiverToPatient(bob, eve);
  await linkCaregiverToPatient(carol, eve);
  await linkCaregiverToPatient(farah, eve);

  logStep("3", "Verifying getCaregiverPatients / getPatientCaregivers");
  const davePatientsRes = await callFunction(
    "getCaregiverPatients",
    { caregiverId: dave.uid },
    dave.idToken,
  );
  console.log(
    `  Dave patients (${davePatientsRes.patients.length}): ${davePatientsRes.patients.map((p) => p.email).join(", ")}`,
  );
  const evesPatientsRes = await callFunction(
    "getCaregiverPatients",
    { caregiverId: eve.uid },
    eve.idToken,
  );
  console.log(
    `  Eve patients  (${evesPatientsRes.patients.length}): ${evesPatientsRes.patients.map((p) => p.email).join(", ")}`,
  );
  const carolCaregiversRes = await callFunction(
    "getPatientCaregivers",
    { patientId: carol.uid },
    carol.idToken,
  );
  console.log(
    `  Carol caregivers (${carolCaregiversRes.caregivers.length}): ${carolCaregiversRes.caregivers.map((c) => c.email).join(", ")}`,
  );

  logStep("4", "Alice - Dengue logs");
  const a1 = await callFunction(
    "submitDengueLog",
    {
      patientId: alice.uid,
      temperature: 37.8,
      fluidIntakeVolume: 2200,
      fluidIntakeType: "water",
      urineOutput: 650,
      urineFrequency: 6,
      bleedingPresent: false,
      abdominalPainPresent: false,
      abdominalPainSeverity: "none",
      vomitingEpisodes: 0,
      mentalStateChange: false,
      dangerSigns: false,
      notes: "Day 1 - mild fever, feeling tired",
    },
    alice.idToken,
  );
  console.log(`  A1 (Green expected)       logId: ${a1.logId}`);

  const a2 = await callFunction(
    "submitDengueLog",
    {
      patientId: alice.uid,
      temperature: 39.1,
      fluidIntakeVolume: 1600,
      fluidIntakeType: "ORS",
      urineOutput: 420,
      urineFrequency: 4,
      bleedingPresent: false,
      abdominalPainPresent: true,
      abdominalPainSeverity: "moderate",
      vomitingEpisodes: 2,
      mentalStateChange: false,
      dangerSigns: false,
      notes: "Day 2 - fever rising, less fluids",
    },
    alice.idToken,
  );
  console.log(`  A2 (Yellow expected)      logId: ${a2.logId}`);

  const a3 = await callFunction(
    "submitDengueLog",
    {
      patientId: alice.uid,
      temperature: 40.5,
      fluidIntakeVolume: 900,
      fluidIntakeType: "water",
      urineOutput: 230,
      urineFrequency: 2,
      bleedingPresent: true,
      abdominalPainPresent: true,
      abdominalPainSeverity: "severe",
      vomitingEpisodes: 5,
      mentalStateChange: true,
      dangerSigns: true,
      notes: "Day 3 - bleeding gums visible, confusion",
    },
    dave.idToken,
  );
  console.log(`  A3 (Red expected, by Dave) logId: ${a3.logId}`);

  const a4 = await callFunction(
    "submitVoiceSymptomLog",
    {
      patientId: alice.uid,
      disease: "dengue",
      voiceInput: "I have severe pain in my abdomen and my gums are bleeding",
    },
    alice.idToken,
  );
  console.log(
    `  A4 (voice, danger=${a4.dangerSignsDetected}) logId: ${a4.logId}`,
  );

  logStep("5", "Bob - Rat Fever logs");
  const b1 = await callFunction(
    "submitRatFeverLog",
    {
      patientId: bob.uid,
      temperature: 37.5,
      secondTemperatureSpike: false,
      urineOutput: 700,
      urineFrequency: 7,
      urineFrequencyDecreased: false,
      urineColor: "normal",
      musclePainPresent: true,
      musclePainSeverity: "mild",
      musclePainLocation: "calves",
      jaundicePresent: false,
      respiratorySymptoms: false,
      neurologicalSymptoms: false,
      dangerSigns: false,
      notes: "Day 1 - mild calf soreness after outdoor work near flooded area",
    },
    bob.idToken,
  );
  console.log(`  B1 (Green expected)       logId: ${b1.logId}`);

  const b2 = await callFunction(
    "submitRatFeverLog",
    {
      patientId: bob.uid,
      temperature: 38.9,
      secondTemperatureSpike: true,
      urineOutput: 480,
      urineFrequency: 4,
      urineFrequencyDecreased: true,
      urineColor: "tea_colored",
      musclePainPresent: true,
      musclePainSeverity: "moderate",
      musclePainLocation: "calves, thighs",
      jaundicePresent: false,
      respiratorySymptoms: false,
      neurologicalSymptoms: false,
      dangerSigns: false,
      notes: "Day 2 - second fever spike, urine now tea-coloured",
    },
    bob.idToken,
  );
  console.log(`  B2 (Yellow expected)      logId: ${b2.logId}`);

  const b3 = await callFunction(
    "submitRatFeverLog",
    {
      patientId: bob.uid,
      temperature: 39.8,
      secondTemperatureSpike: true,
      urineOutput: 200,
      urineFrequency: 2,
      urineFrequencyDecreased: true,
      urineColor: "dark",
      musclePainPresent: true,
      musclePainSeverity: "severe",
      musclePainLocation: "calves, thighs, lower_back",
      jaundicePresent: true,
      respiratorySymptoms: true,
      neurologicalSymptoms: false,
      dangerSigns: true,
      notes: "Day 3 - yellow eyes visible, shortness of breath",
    },
    eve.idToken,
  );
  console.log(`  B3 (Red expected, by Eve)  logId: ${b3.logId}`);

  const b4 = await callFunction(
    "submitVoiceSymptomLog",
    {
      patientId: bob.uid,
      disease: "rat_fever",
      voiceInput:
        "severe headache that won't go away and my neck feels stiff, also have jaundice",
    },
    bob.idToken,
  );
  console.log(
    `  B4 (voice, danger=${b4.dangerSignsDetected}) logId: ${b4.logId}`,
  );

  logStep("6", "Carol - Dengue logs");
  const c1 = await callFunction(
    "submitDengueLog",
    {
      patientId: carol.uid,
      temperature: 38.6,
      fluidIntakeVolume: 1900,
      fluidIntakeType: "juice",
      urineOutput: 450,
      urineFrequency: 5,
      bleedingPresent: false,
      abdominalPainPresent: true,
      abdominalPainSeverity: "mild",
      vomitingEpisodes: 3,
      mentalStateChange: false,
      dangerSigns: false,
      notes: "Nausea and mild stomach cramps",
    },
    carol.idToken,
  );
  console.log(`  C1 dengue (Yellow expected) logId: ${c1.logId}`);

  const c2 = await callFunction(
    "submitDengueLog",
    {
      patientId: carol.uid,
      temperature: 37.6,
      fluidIntakeVolume: 2300,
      fluidIntakeType: "water",
      urineOutput: 680,
      urineFrequency: 6,
      bleedingPresent: false,
      abdominalPainPresent: false,
      abdominalPainSeverity: "none",
      vomitingEpisodes: 0,
      mentalStateChange: false,
      dangerSigns: false,
      notes: "Day 1 - stable recovery pattern",
    },
    carol.idToken,
  );
  console.log(`  C2 dengue (Green expected) logId: ${c2.logId}`);

  const c3 = await callFunction(
    "submitDengueLog",
    {
      patientId: carol.uid,
      temperature: 40.8,
      fluidIntakeVolume: 700,
      fluidIntakeType: "ORS",
      urineOutput: 150,
      urineFrequency: 1,
      bleedingPresent: true,
      abdominalPainPresent: true,
      abdominalPainSeverity: "severe",
      vomitingEpisodes: 7,
      mentalStateChange: true,
      dangerSigns: true,
      notes: "Petechiae visible on arms, very lethargic",
    },
    dave.idToken,
  );
  console.log(`  C3 dengue (Red expected, by Dave) logId: ${c3.logId}`);

  const c4 = await callFunction(
    "submitVoiceSymptomLog",
    {
      patientId: carol.uid,
      disease: "dengue",
      voiceInput: "I have bleeding from my nose and severe stomach pain",
    },
    eve.idToken,
  );
  console.log(
    `  C4 (voice, danger=${c4.dangerSignsDetected}) logId: ${c4.logId}`,
  );

  logStep("7", "Farah - Rat Fever logs");
  const f1 = await callFunction(
    "submitRatFeverLog",
    {
      patientId: farah.uid,
      temperature: 37.4,
      secondTemperatureSpike: false,
      urineOutput: 720,
      urineFrequency: 7,
      urineFrequencyDecreased: false,
      urineColor: "normal",
      musclePainPresent: true,
      musclePainSeverity: "mild",
      musclePainLocation: "calves",
      jaundicePresent: false,
      respiratorySymptoms: false,
      neurologicalSymptoms: false,
      dangerSigns: false,
      notes: "Day 1 - mild muscle pain only",
    },
    farah.idToken,
  );
  console.log(`  F1 rat_fever (Green expected) logId: ${f1.logId}`);

  const f2 = await callFunction(
    "submitRatFeverLog",
    {
      patientId: farah.uid,
      temperature: 38.7,
      secondTemperatureSpike: true,
      urineOutput: 460,
      urineFrequency: 4,
      urineFrequencyDecreased: true,
      urineColor: "brownish",
      musclePainPresent: true,
      musclePainSeverity: "moderate",
      musclePainLocation: "thighs",
      jaundicePresent: false,
      respiratorySymptoms: false,
      neurologicalSymptoms: false,
      dangerSigns: false,
      notes: "Day 2 - darker urine and recurring fever",
    },
    farah.idToken,
  );
  console.log(`  F2 rat_fever (Yellow expected) logId: ${f2.logId}`);

  const f3 = await callFunction(
    "submitRatFeverLog",
    {
      patientId: farah.uid,
      temperature: 39.9,
      secondTemperatureSpike: true,
      urineOutput: 210,
      urineFrequency: 2,
      urineFrequencyDecreased: true,
      urineColor: "dark",
      musclePainPresent: true,
      musclePainSeverity: "severe",
      musclePainLocation: "calves, lower_back",
      jaundicePresent: true,
      respiratorySymptoms: true,
      neurologicalSymptoms: false,
      dangerSigns: true,
      notes: "Day 3 - worsening breathing and jaundice",
    },
    eve.idToken,
  );
  console.log(`  F3 rat_fever (Red expected, by Eve) logId: ${f3.logId}`);

  const f4 = await callFunction(
    "submitVoiceSymptomLog",
    {
      patientId: farah.uid,
      disease: "rat_fever",
      voiceInput:
        "I have shortness of breath and severe headache with jaundice",
    },
    farah.idToken,
  );
  console.log(
    `  F4 (voice, danger=${f4.dangerSignsDetected}) logId: ${f4.logId}`,
  );

  logStep("8", "Waiting 5 s for Firestore triggers (triage + alerts)...");
  await wait(5000);

  const checks = [
    { id: a1.logId, expected: "Green", label: "A1 Alice dengue mild" },
    { id: a2.logId, expected: "Yellow", label: "A2 Alice dengue moderate" },
    { id: a3.logId, expected: "Red", label: "A3 Alice dengue severe" },
    { id: b1.logId, expected: "Green", label: "B1 Bob rat_fever mild" },
    { id: b2.logId, expected: "Yellow", label: "B2 Bob rat_fever moderate" },
    { id: b3.logId, expected: "Red", label: "B3 Bob rat_fever severe" },
    { id: c1.logId, expected: "Yellow", label: "C1 Carol dengue moderate" },
    { id: c2.logId, expected: "Green", label: "C2 Carol dengue mild" },
    { id: c3.logId, expected: "Red", label: "C3 Carol dengue severe" },
    { id: f1.logId, expected: "Green", label: "F1 Farah rat_fever mild" },
    { id: f2.logId, expected: "Yellow", label: "F2 Farah rat_fever moderate" },
    { id: f3.logId, expected: "Red", label: "F3 Farah rat_fever severe" },
  ];

  let allPassed = true;
  for (const check of checks) {
    const snap = await db.collection("symptom_logs").doc(check.id).get();
    const actual = snap.data()?.triage;
    const ok = actual === check.expected ? "+" : "X";
    if (actual !== check.expected) allPassed = false;
    console.log(
      `  [${ok}] ${check.label}: ${actual} (expected ${check.expected})`,
    );
  }

  for (const [patient, label] of [
    [alice, "Alice"],
    [bob, "Bob"],
    [carol, "Carol"],
    [farah, "Farah"],
  ]) {
    const alertSnap = await db
      .collection("alerts")
      .where("patientId", "==", patient.uid)
      .get();
    console.log(`  Alerts for ${label}: ${alertSnap.size}`);
  }

  logStep("9", "Generate PDF report for Carol (as Dave - linked caregiver)");
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  try {
    const pdf = await callFunction(
      "generatePDFReport",
      {
        patientId: carol.uid,
        startDate: sevenDaysAgo.toISOString(),
        endDate: now.toISOString(),
      },
      dave.idToken,
    );
    console.log(`  PDF URL: ${pdf.downloadUrl}`);
  } catch (err) {
    console.log(`  PDF skipped: ${err.message}`);
  }

  logStep(
    "DONE",
    allPassed
      ? "All triage checks passed"
      : "Some triage checks failed - review above",
  );
  const [totalLogs, totalAlerts, totalLinks] = await Promise.all([
    db.collection("symptom_logs").get(),
    db.collection("alerts").get(),
    db.collection("patient_links").get(),
  ]);
  console.log("\n  Database summary:");
  console.log("    users         : 6");
  console.log(`    patient_links : ${totalLinks.size}`);
  console.log(`    symptom_logs  : ${totalLogs.size}`);
  console.log(`    alerts        : ${totalAlerts.size}`);
}

run().catch((err) => {
  console.error("\nTest run failed:");
  console.error(err.message);
  process.exitCode = 1;
});

import admin, { db } from "../config/dataLayer.js";
import { generateId, formatTimestamp } from "../utils/helpers.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";

/**
 * Create medical record
 */
export async function createRecord(patientId, recordData) {
  const recordId = generateId();
  const timestamp = new Date();

  const values =
    recordData.values && typeof recordData.values === "object"
      ? { ...recordData.values }
      : {};

  const symptoms =
    recordData.symptoms && typeof recordData.symptoms === "object"
      ? { ...recordData.symptoms }
      : {};

  const record = {
    id: recordId,
    patientId,
    disease: recordData.disease,
    temperature: recordData.temperature || null,
    fluidIntake: recordData.fluidIntake || null,
    urineOutput: recordData.urineOutput || null,
    urineColor: recordData.urineColor || null,
    values,
    symptoms,
    notes: recordData.notes || "",
    createdAt: timestamp,
    updatedAt: timestamp,
    createdBy: recordData.createdBy || patientId,
  };

  await db.collection("medicalRecords").doc(recordId).set(record);

  // Update patient's medical history
  await db
    .collection("patients")
    .doc(patientId)
    .update({
      ["medicalHistory"]: admin.firestore.FieldValue.arrayUnion(recordId),
    });

  return record;
}

/**
 * Get record by ID
 */
export async function getRecord(recordId) {
  const recordDoc = await db.collection("medicalRecords").doc(recordId).get();

  if (!recordDoc.exists) {
    throw new NotFoundError("Record not found");
  }

  return recordDoc.data();
}

/**
 * List patient records with filters
 */
export async function listRecords(patientId, filters = {}) {
  let query = db
    .collection("medicalRecords")
    .where("patientId", "==", patientId);

  // Filter by disease
  if (filters.disease) {
    query = query.where("disease", "==", filters.disease);
  }

  // Filter by date range (last 24h, 3 days, 7 days)
  if (filters.timelineFilter) {
    const now = Date.now();
    let startTime;

    switch (filters.timelineFilter) {
      case "last24h":
        startTime = new Date(now - 24 * 60 * 60 * 1000);
        break;
      case "last3Days":
        startTime = new Date(now - 3 * 24 * 60 * 60 * 1000);
        break;
      case "last7Days":
        startTime = new Date(now - 7 * 24 * 60 * 60 * 1000);
        break;
      default:
        startTime = new Date(0); // All time
    }

    query = query.where("createdAt", ">=", startTime);
  }

  // Order by creation date
  query = query.orderBy("createdAt", "desc");

  const snapshot = await query.get();

  return snapshot.docs.map((doc) => doc.data());
}

/**
 * Update record
 */
export async function updateRecord(recordId, updates) {
  const existing = await getRecord(recordId);

  const validUpdates = {};

  if (updates.temperature !== undefined) {
    validUpdates.temperature = updates.temperature;
  }

  if (updates.fluidIntake !== undefined) {
    validUpdates.fluidIntake = updates.fluidIntake;
  }

  if (updates.urineOutput !== undefined) {
    validUpdates.urineOutput = updates.urineOutput;
  }

  if (updates.urineColor !== undefined) {
    validUpdates.urineColor = updates.urineColor;
  }

  if (updates.symptoms !== undefined) {
    validUpdates.symptoms = updates.symptoms;
  }

  if (updates.notes !== undefined) {
    validUpdates.notes = updates.notes;
  }

  validUpdates.updatedAt = new Date();

  await db.collection("medicalRecords").doc(recordId).update(validUpdates);

  return {
    ...existing,
    ...validUpdates,
  };
}

/**
 * Delete record
 */
export async function deleteRecord(recordId, patientId) {
  const record = await getRecord(recordId);

  if (record.patientId !== patientId) {
    throw new ValidationError("Cannot delete record from another patient");
  }

  await db.collection("medicalRecords").doc(recordId).delete();

  // Remove from patient's medical history
  await db
    .collection("patients")
    .doc(patientId)
    .update({
      ["medicalHistory"]: admin.firestore.FieldValue.arrayRemove(recordId),
    });

  return true;
}

/**
 * Get records statistics
 */
export async function getRecordStats(patientId, timelineFilter = "last7Days") {
  const records = await listRecords(patientId, { timelineFilter });

  if (records.length === 0) {
    return {
      totalRecords: 0,
      avgTemperature: null,
      diseaseBreakdown: {},
      symptomFrequency: {},
    };
  }

  const symptomFrequency = {};

  const diseases = {};
  let totalTemp = 0;
  let tempCount = 0;

  records.forEach((record) => {
    // Temperature average
    if (record.temperature) {
      totalTemp += parseFloat(record.temperature);
      tempCount++;
    }

    // Disease breakdown
    diseases[record.disease] = (diseases[record.disease] || 0) + 1;

    // Symptom frequency
    if (record.symptoms && typeof record.symptoms === "object") {
      Object.entries(record.symptoms).forEach(([key, value]) => {
        if (value) {
          symptomFrequency[key] = (symptomFrequency[key] || 0) + 1;
        }
      });
    }
  });

  return {
    totalRecords: records.length,
    avgTemperature: tempCount > 0 ? (totalTemp / tempCount).toFixed(1) : null,
    diseaseBreakdown: diseases,
    symptomFrequency,
  };
}

export default {
  createRecord,
  getRecord,
  listRecords,
  updateRecord,
  deleteRecord,
  getRecordStats,
};

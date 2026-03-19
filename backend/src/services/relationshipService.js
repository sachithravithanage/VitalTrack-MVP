import admin, { db } from "../config/firebase.js";
import {
  generateLinkCode as createLinkCode,
  generateId,
  isExpired,
} from "../utils/helpers.js";
import {
  ValidationError,
  NotFoundError,
  ConflictError,
} from "../utils/errors.js";
import * as emailService from "./emailService.js";

const LINK_CODE_EXPIRY_HOURS = 7 * 24; // 7 days

/**
 * Generate caregiver link code for patient
 */
export async function generateLinkCode(patientId) {
  const code = createLinkCode();
  const timestamp = Date.now();

  await db
    .collection("linkCodes")
    .doc(code)
    .set({
      code,
      patientId,
      createdAt: timestamp,
      expiresAt: timestamp + LINK_CODE_EXPIRY_HOURS * 60 * 60 * 1000,
      used: false,
      usedBy: null,
      usedAt: null,
    });

  return code;
}

/**
 * Validate and use link code
 */
export async function useLinkCode(code, caregiverId) {
  const codeDoc = await db.collection("linkCodes").doc(code).get();

  if (!codeDoc.exists) {
    throw new NotFoundError("Invalid link code");
  }

  const codeData = codeDoc.data();

  // Check if code is already used
  if (codeData.used) {
    throw new ValidationError("Link code has already been used");
  }

  // Check if code is expired
  if (isExpired(codeData.createdAt, LINK_CODE_EXPIRY_HOURS * 60)) {
    throw new ValidationError("Link code has expired");
  }

  const patientId = codeData.patientId;

  // Get patient info
  const patientDoc = await db.collection("users").doc(patientId).get();
  if (!patientDoc.exists) {
    throw new NotFoundError("Patient not found");
  }

  const patient = patientDoc.data();

  // Get caregiver info
  const caregiverDoc = await db.collection("users").doc(caregiverId).get();
  if (!caregiverDoc.exists) {
    throw new NotFoundError("Caregiver not found");
  }

  const caregiver = caregiverDoc.data();

  // Check if already linked
  const existingLink = await db
    .collection("relationships")
    .where("patientId", "==", patientId)
    .where("caregiverId", "==", caregiverId)
    .get();

  if (!existingLink.empty) {
    throw new ConflictError("Patient is already linked to this caregiver");
  }

  // Create relationship
  const relationshipId = `${patientId}-${caregiverId}`;

  await db.collection("relationships").doc(relationshipId).set({
    patientId,
    caregiverId,
    patientName: patient.name,
    disease: "pending", // Will be set when caregiver adds patient
    createdAt: new Date(),
    status: "active",
  });

  // Update patient's linked caregivers
  await db
    .collection("patients")
    .doc(patientId)
    .update({
      linkedCaregivers: admin.firestore.FieldValue.arrayUnion(caregiverId),
    });

  // Update caregiver's linked patients
  const existingCaregiverDoc = await db
    .collection("caregivers")
    .doc(caregiverId)
    .get();
  if (!existingCaregiverDoc.exists) {
    // Create caregiver doc if doesn't exist
    await db
      .collection("caregivers")
      .doc(caregiverId)
      .set({
        uid: caregiverId,
        linkedPatients: [patientId],
      });
  } else {
    await db
      .collection("caregivers")
      .doc(caregiverId)
      .update({
        linkedPatients: admin.firestore.FieldValue.arrayUnion(patientId),
      });
  }

  // Mark code as used
  await codeDoc.ref.update({
    used: true,
    usedBy: caregiverId,
    usedAt: new Date(),
  });

  // Send email notification to patient if they have an email
  if (patient.email) {
    try {
      await emailService.sendCaregiverLinkingEmail(
        patient.email,
        patient.name,
        caregiver.name,
      );
    } catch (emailError) {
      console.error("Failed to send caregiver linking email:", emailError);
      // Don't fail the linking process if email fails
    }
  }

  return {
    patientId,
    patientName: patient.name,
    caregiverId,
    linkedAt: new Date(),
  };
}

/**
 * Caregiver creates and links a managed patient profile
 */
export async function createManagedPatient(caregiverId, { name, disease }) {
  const trimmedName = String(name || "").trim();
  if (trimmedName.length < 2) {
    throw new ValidationError("Patient name must be at least 2 characters");
  }

  const allowedDiseases = ["dengue", "ratFever"];
  if (!allowedDiseases.includes(disease)) {
    throw new ValidationError("Invalid disease type");
  }

  const caregiverDoc = await db.collection("users").doc(caregiverId).get();
  if (!caregiverDoc.exists) {
    throw new NotFoundError("Caregiver not found");
  }

  const caregiver = caregiverDoc.data();
  if (caregiver.role !== "caregiver") {
    throw new ValidationError("Only caregivers can create managed patients");
  }

  const patientId = generateId();
  const relationshipId = `${patientId}-${caregiverId}`;
  const now = new Date();

  await db
    .collection("users")
    .doc(patientId)
    .set({
      uid: patientId,
      name: trimmedName,
      role: "patient",
      email: null,
      phone: null,
      emailVerified: false,
      managedByCaregiver: true,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      profile: {
        avatar: null,
        bio: "",
      },
    });

  await db
    .collection("patients")
    .doc(patientId)
    .set({
      uid: patientId,
      linkedCaregivers: [caregiverId],
      medicalHistory: [],
    });

  await db.collection("relationships").doc(relationshipId).set({
    patientId,
    caregiverId,
    patientName: trimmedName,
    disease,
    createdAt: now,
    status: "active",
    managed: true,
  });

  const existingCaregiverDoc = await db
    .collection("caregivers")
    .doc(caregiverId)
    .get();

  if (!existingCaregiverDoc.exists) {
    await db
      .collection("caregivers")
      .doc(caregiverId)
      .set({
        uid: caregiverId,
        linkedPatients: [patientId],
      });
  } else {
    await db
      .collection("caregivers")
      .doc(caregiverId)
      .update({
        linkedPatients: admin.firestore.FieldValue.arrayUnion(patientId),
      });
  }

  return {
    patientId,
    patientName: trimmedName,
    caregiverId,
    disease,
    linkedAt: now,
  };
}

/**
 * Get patient's linked caregivers
 */
export async function getPatientCaregivers(patientId) {
  const caregiverIds = [];

  const relationships = await db
    .collection("relationships")
    .where("patientId", "==", patientId)
    .where("status", "==", "active")
    .get();

  for (const doc of relationships.docs) {
    caregiverIds.push(doc.data().caregiverId);
  }

  if (caregiverIds.length === 0) {
    return [];
  }

  // Get caregiver details
  const caregivers = [];
  for (const caregiverId of caregiverIds) {
    const userDoc = await db.collection("users").doc(caregiverId).get();
    if (userDoc.exists) {
      caregivers.push(userDoc.data());
    }
  }

  return caregivers;
}

/**
 * Get caregiver's linked patients
 */
export async function getCaregiverPatients(caregiverId) {
  const patientIds = [];

  const relationships = await db
    .collection("relationships")
    .where("caregiverId", "==", caregiverId)
    .where("status", "==", "active")
    .get();

  for (const doc of relationships.docs) {
    patientIds.push({
      patientId: doc.data().patientId,
      disease: doc.data().disease,
      patientName: doc.data().patientName,
    });
  }

  if (patientIds.length === 0) {
    return [];
  }

  // Get patient details
  const patients = [];
  for (const patientInfo of patientIds) {
    const userDoc = await db
      .collection("users")
      .doc(patientInfo.patientId)
      .get();
    if (userDoc.exists) {
      patients.push({
        ...userDoc.data(),
        disease: patientInfo.disease,
      });
    }
  }

  return patients;
}

/**
 * Check whether a caregiver is actively linked to a patient
 */
export async function isCaregiverLinkedToPatient(patientId, caregiverId) {
  if (!patientId || !caregiverId) {
    return false;
  }

  const relationshipId = `${patientId}-${caregiverId}`;
  const relationshipDoc = await db
    .collection("relationships")
    .doc(relationshipId)
    .get();

  if (!relationshipDoc.exists) {
    return false;
  }

  const relationship = relationshipDoc.data();
  return relationship.status === "active";
}

/**
 * Remove patient-caregiver relationship
 */
export async function removeRelationship(patientId, caregiverId) {
  const relationshipId = `${patientId}-${caregiverId}`;
  const relationshipDoc = await db
    .collection("relationships")
    .doc(relationshipId)
    .get();

  if (!relationshipDoc.exists) {
    throw new NotFoundError("Relationship not found");
  }

  // Delete relationship
  await relationshipDoc.ref.delete();

  // Update patient's linked caregivers
  await db
    .collection("patients")
    .doc(patientId)
    .update({
      linkedCaregivers: admin.firestore.FieldValue.arrayRemove(caregiverId),
    });

  // Update caregiver's linked patients
  await db
    .collection("caregivers")
    .doc(caregiverId)
    .update({
      linkedPatients: admin.firestore.FieldValue.arrayRemove(patientId),
    });

  return true;
}

export default {
  generateLinkCode,
  useLinkCode,
  createManagedPatient,
  getPatientCaregivers,
  getCaregiverPatients,
  isCaregiverLinkedToPatient,
  removeRelationship,
};

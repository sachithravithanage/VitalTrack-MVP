import admin, { db } from "../config/dataLayer.js";
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
      usedBy: [],
      lastUsedAt: null,
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

  // Check if code is expired
  if (isExpired(codeData.createdAt, LINK_CODE_EXPIRY_HOURS * 60)) {
    throw new ValidationError("Link code has expired");
  }

  const patientId = codeData.patientId;

  // Parallelize: get patient and caregiver docs + check existing link
  const [patientDoc, caregiverDoc, existingLink] = await Promise.all([
    db.collection("users").doc(patientId).get(),
    db.collection("users").doc(caregiverId).get(),
    db
      .collection("relationships")
      .where("patientId", "==", patientId)
      .where("caregiverId", "==", caregiverId)
      .get(),
  ]);

  if (!patientDoc.exists) {
    throw new NotFoundError("Patient not found");
  }

  if (!caregiverDoc.exists) {
    throw new NotFoundError("Caregiver not found");
  }

  if (!existingLink.empty) {
    throw new ConflictError("Patient is already linked to this caregiver");
  }

  const patient = patientDoc.data();
  const caregiver = caregiverDoc.data();
  const relationshipId = `${patientId}-${caregiverId}`;
  const now = new Date();

  // Parallelize: all write operations
  const writeOps = [
    // Create relationship
    db.collection("relationships").doc(relationshipId).set({
      patientId,
      caregiverId,
      patientName: patient.name,
      disease: "pending",
      createdAt: now,
      status: "active",
    }),
    // Update patient's linked caregivers
    db
      .collection("patients")
      .doc(patientId)
      .set(
        {
          linkedCaregivers: admin.firestore.FieldValue.arrayUnion(caregiverId),
        },
        { merge: true },
      ),
    // Update code usage
    codeDoc.ref.update({
      usedBy: admin.firestore.FieldValue.arrayUnion(caregiverId),
      lastUsedAt: now,
    }),
  ];

  // Handle caregiver doc separately since it needs a read
  const existingCaregiverDoc = await db
    .collection("caregivers")
    .doc(caregiverId)
    .get();

  if (!existingCaregiverDoc.exists) {
    writeOps.push(
      db
        .collection("caregivers")
        .doc(caregiverId)
        .set({
          uid: caregiverId,
          linkedPatients: [patientId],
        }),
    );
  } else {
    writeOps.push(
      db
        .collection("caregivers")
        .doc(caregiverId)
        .update({
          linkedPatients: admin.firestore.FieldValue.arrayUnion(patientId),
        }),
    );
  }

  // Run all write operations in parallel
  await Promise.all(writeOps);

  // Send email notification asynchronously (non-blocking)
  if (patient.email) {
    emailService
      .sendCaregiverLinkingEmail(patient.email, patient.name, caregiver.name)
      .catch((emailError) => {
        console.error("Failed to send caregiver linking email:", emailError);
      });
  }

  return {
    patientId,
    patientName: patient.name,
    caregiverId,
    linkedAt: now,
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
  const caregiverRoles = Array.isArray(caregiver.roles)
    ? caregiver.roles.map((role) => String(role || "").toLowerCase())
    : [String(caregiver.role || "").toLowerCase()];
  if (!caregiverRoles.includes("caregiver")) {
    throw new ValidationError("Only caregivers can create managed patients");
  }

  const patientId = generateId();
  const relationshipId = `${patientId}-${caregiverId}`;
  const now = new Date();

  // Parallelize: create patient doc and relationship doc
  const writeOps = [
    db
      .collection("users")
      .doc(patientId)
      .set({
        uid: patientId,
        name: trimmedName,
        role: "patient",
        roles: ["patient"],
        activeRole: "patient",
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
      }),
    db
      .collection("patients")
      .doc(patientId)
      .set({
        uid: patientId,
        linkedCaregivers: [caregiverId],
        medicalHistory: [],
      }),
    db.collection("relationships").doc(relationshipId).set({
      patientId,
      caregiverId,
      patientName: trimmedName,
      disease,
      createdAt: now,
      status: "active",
      managed: true,
    }),
  ];

  // Process caregiver doc separately since it needs a read
  const existingCaregiverDoc = await db
    .collection("caregivers")
    .doc(caregiverId)
    .get();

  if (!existingCaregiverDoc.exists) {
    writeOps.push(
      db
        .collection("caregivers")
        .doc(caregiverId)
        .set({
          uid: caregiverId,
          linkedPatients: [patientId],
        }),
    );
  } else {
    writeOps.push(
      db
        .collection("caregivers")
        .doc(caregiverId)
        .update({
          linkedPatients: admin.firestore.FieldValue.arrayUnion(patientId),
        }),
    );
  }

  // Execute all writes in parallel
  await Promise.all(writeOps);

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
  const relationships = await db
    .collection("relationships")
    .where("patientId", "==", patientId)
    .where("status", "==", "active")
    .get();

  if (relationships.empty) {
    return [];
  }

  const caregiverIds = relationships.docs.map((doc) => doc.data().caregiverId);

  // Parallelize: fetch all caregiver docs in parallel
  const caregiverDocs = await Promise.all(
    caregiverIds.map((caregiverId) =>
      db.collection("users").doc(caregiverId).get(),
    ),
  );

  return caregiverDocs.filter((doc) => doc.exists).map((doc) => doc.data());
}

/**
 * Get caregiver's linked patients
 */
export async function getCaregiverPatients(caregiverId) {
  const relationships = await db
    .collection("relationships")
    .where("caregiverId", "==", caregiverId)
    .where("status", "==", "active")
    .get();

  if (relationships.empty) {
    return [];
  }

  const patientInfos = relationships.docs.map((doc) => ({
    patientId: doc.data().patientId,
    disease: doc.data().disease,
    patientName: doc.data().patientName,
  }));

  // Parallelize: fetch all patient docs in parallel
  const patientDocs = await Promise.all(
    patientInfos.map((info) =>
      db.collection("users").doc(info.patientId).get(),
    ),
  );

  return patientDocs
    .map((doc, index) => ({
      ...doc.data(),
      disease: patientInfos[index].disease,
    }))
    .filter((patient) => patient && patient.uid);
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

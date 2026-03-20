import { db, messaging } from "../config/firebase.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";

/**
 * Save FCM token for user
 */
export async function saveFCMToken(uid, token, platform) {
  await db
    .collection("fcmTokens")
    .doc(uid)
    .update({
      [platform]: token,
      updatedAt: new Date(),
    });

  return true;
}

/**
 * Send notification to user
 */
export async function sendNotification(uid, title, body, data = {}) {
  const tokenDoc = await db.collection("fcmTokens").doc(uid).get();

  const tokenData = tokenDoc.exists ? tokenDoc.data() : null;
  const token =
    tokenData?.token ||
    tokenData?.flutter ||
    tokenData?.android ||
    tokenData?.ios ||
    tokenData?.web;

  if (!token) {
    // User hasn't registered FCM token
    return {
      sent: false,
      reason: "No FCM token registered",
    };
  }

  try {
    const messageId = await messaging.send({
      notification: {
        title,
        body,
      },
      data,
      token,
    });

    // Log notification in database
    await db.collection("notifications").add({
      uid,
      title,
      body,
      data,
      sentAt: new Date(),
      messageId,
      status: "sent",
    });

    return {
      sent: true,
      messageId,
    };
  } catch (error) {
    console.error("Error sending notification:", error);

    // Log failed notification
    await db.collection("notifications").add({
      uid,
      title,
      body,
      data,
      sentAt: new Date(),
      status: "failed",
      error: error.message,
    });

    return {
      sent: false,
      error: error.message,
    };
  }
}

/**
 * Send notifications to multiple users (bulk)
 */
export async function sendBulkNotifications(uids, title, body, data = {}) {
  const results = [];

  for (const uid of uids) {
    const result = await sendNotification(uid, title, body, data);
    results.push({ uid, ...result });
  }

  return results;
}

/**
 * Send notification for new record (to caregivers)
 */
export async function notifyNewRecord(patientId, patientName, disease) {
  // Get patient's caregivers
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
    return { sent: 0 };
  }

  const results = await sendBulkNotifications(
    caregiverIds,
    "New Medical Record",
    `${patientName} has submitted a new ${disease} record`,
    {
      type: "new_record",
      patientId,
      disease,
    },
  );

  return {
    sent: results.filter((r) => r.sent).length,
    failed: results.filter((r) => !r.sent).length,
  };
}

/**
 * Send alert notification for high temperature
 */
export async function notifyHighTemperature(
  patientId,
  patientName,
  temperature,
) {
  // Get patient's caregivers
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
    return { sent: 0 };
  }

  const results = await sendBulkNotifications(
    caregiverIds,
    "⚠️ High Temperature Alert",
    `${patientName}'s temperature is ${temperature}°C`,
    {
      type: "high_temperature_alert",
      patientId,
      temperature,
    },
  );

  return {
    sent: results.filter((r) => r.sent).length,
    failed: results.filter((r) => !r.sent).length,
  };
}

/**
 * Get user's notification history
 */
export async function getNotificationHistory(uid, limit = 50) {
  const snapshot = await db
    .collection("notifications")
    .where("uid", "==", uid)
    .orderBy("sentAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * Mark notification as read
 */
export async function markNotificationAsRead(notificationId) {
  await db.collection("notifications").doc(notificationId).update({
    read: true,
    readAt: new Date(),
  });

  return true;
}

/**
 * Generate inactivity notifications for a patient when no records are submitted
 * for 2h, 5h, 12h and 24h windows.
 */
export async function generateMissingRecordNotifications(patientId) {
  const latestSnapshot = await db
    .collection("medicalRecords")
    .where("patientId", "==", patientId)
    .orderBy("createdAt", "desc")
    .limit(1)
    .get();

  if (latestSnapshot.empty) {
    return { generated: 0, reason: "No records yet" };
  }

  const latestDoc = latestSnapshot.docs[0];
  const latestRecord = latestDoc.data();
  const createdAtRaw = latestRecord.createdAt;
  const createdAt = createdAtRaw?.toDate
    ? createdAtRaw.toDate()
    : new Date(createdAtRaw);

  if (!(createdAt instanceof Date) || Number.isNaN(createdAt.getTime())) {
    return { generated: 0, reason: "Invalid record timestamp" };
  }

  const elapsedMs = Date.now() - createdAt.getTime();
  const thresholds = [
    {
      hours: 2,
      title: "Record Reminder (2 Hours)",
      body: "No medical record has been added in the last 2 hours.",
    },
    {
      hours: 5,
      title: "Record Reminder (5 Hours)",
      body: "No medical record has been added in the last 5 hours.",
    },
    {
      hours: 12,
      title: "Record Reminder (12 Hours)",
      body: "No medical record has been added in the last 12 hours.",
    },
    {
      hours: 24,
      title: "Record Reminder (1 Day)",
      body: "No medical record has been added for 1 day.",
    },
  ];

  let generated = 0;

  for (const threshold of thresholds) {
    const thresholdMs = threshold.hours * 60 * 60 * 1000;
    if (elapsedMs < thresholdMs) {
      continue;
    }

    const notificationId = `missing_${patientId}_${latestDoc.id}_${threshold.hours}`;
    const notificationRef = db.collection("notifications").doc(notificationId);
    const notificationDoc = await notificationRef.get();

    if (notificationDoc.exists) {
      continue;
    }

    await notificationRef.set({
      uid: patientId,
      title: threshold.title,
      body: threshold.body,
      data: {
        type: "missing_record",
        thresholdHours: String(threshold.hours),
        patientId,
        sinceRecordId: latestDoc.id,
        sinceRecordAt: createdAt.toISOString(),
      },
      sentAt: new Date(),
      status: "generated",
      read: false,
    });

    generated += 1;
  }

  return { generated };
}

/**
 * Generate inactivity notifications for all patient users.
 */
export async function generateMissingRecordNotificationsForAllPatients() {
  const generatedByPatient = [];

  const withRoles = await db
    .collection("users")
    .where("roles", "array-contains", "patient")
    .get();

  const withoutRoles = await db
    .collection("users")
    .where("role", "==", "patient")
    .get();

  const patientIds = new Set([
    ...withRoles.docs.map((doc) => doc.id),
    ...withoutRoles.docs.map((doc) => doc.id),
  ]);

  for (const patientId of patientIds) {
    try {
      const result = await generateMissingRecordNotifications(patientId);
      generatedByPatient.push({ patientId, ...result });
    } catch (error) {
      generatedByPatient.push({
        patientId,
        generated: 0,
        error: error.message,
      });
    }
  }

  return {
    patientsChecked: patientIds.size,
    generatedTotal: generatedByPatient.reduce(
      (sum, item) => sum + (item.generated || 0),
      0,
    ),
    generatedByPatient,
  };
}

export default {
  saveFCMToken,
  sendNotification,
  sendBulkNotifications,
  notifyNewRecord,
  notifyHighTemperature,
  getNotificationHistory,
  markNotificationAsRead,
  generateMissingRecordNotifications,
  generateMissingRecordNotificationsForAllPatients,
};

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

  if (!tokenDoc.exists || !tokenDoc.data().token) {
    // User hasn't registered FCM token
    return {
      sent: false,
      reason: "No FCM token registered",
    };
  }

  const token = tokenDoc.data().token;

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

export default {
  saveFCMToken,
  sendNotification,
  sendBulkNotifications,
  notifyNewRecord,
  notifyHighTemperature,
  getNotificationHistory,
  markNotificationAsRead,
};

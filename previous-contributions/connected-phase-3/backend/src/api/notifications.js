import express from "express";
import * as notificationService from "../services/notificationService.js";
import * as authService from "../services/authService.js";
import { verifyAuthToken } from "../middleware/auth.js";
import { handleError } from "../utils/errors.js";

const router = express.Router();

// Require authentication for all routes
router.use(verifyAuthToken);

/**
 * POST /api/v1/notifications/register-token
 * Register FCM token for push notifications
 */
router.post("/register-token", async (req, res) => {
  try {
    const { token, platform } = req.body;

    if (!token || !platform) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Token and platform required",
        },
      });
    }

    // Create FCM tokens doc if doesn't exist
    const { db } = await import("../config/dataLayer.js");
    const tokenDoc = await db.collection("fcmTokens").doc(req.user.uid).get();

    if (!tokenDoc.exists) {
      await db.collection("fcmTokens").doc(req.user.uid).set({
        uid: req.user.uid,
      });
    }

    await notificationService.saveFCMToken(req.user.uid, token, platform);

    res.json({
      success: true,
      message: "FCM token registered successfully",
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/notifications/history
 * Get notification history for user
 */
router.get("/history", async (req, res) => {
  try {
    const { limit } = req.query;

    const userProfile = await authService.getUserProfile(req.user.uid);
    if (userProfile.role === "patient") {
      await notificationService.generateMissingRecordNotifications(
        req.user.uid,
      );
    }

    const notifications = await notificationService.getNotificationHistory(
      req.user.uid,
      parseInt(limit) || 50,
    );

    res.json({
      success: true,
      data: { notifications },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * PUT /api/v1/notifications/:notificationId/read
 * Mark notification as read
 */
router.put("/:notificationId/read", async (req, res) => {
  try {
    await notificationService.markNotificationAsRead(req.params.notificationId);

    res.json({
      success: true,
      message: "Notification marked as read",
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/notifications/test
 * Send test notification (dev only)
 */
router.post("/test", verifyAuthToken, async (req, res) => {
  try {
    if (process.env.NODE_ENV !== "development") {
      return res.status(403).json({
        success: false,
        error: {
          code: "FORBIDDEN",
          message: "Only available in development",
        },
      });
    }

    const result = await notificationService.sendNotification(
      req.user.uid,
      "Test Notification",
      "This is a test notification from VitalTrack",
      { type: "test" },
    );

    res.json({
      success: true,
      data: { result },
    });
  } catch (error) {
    handleError(error, res);
  }
});

export default router;

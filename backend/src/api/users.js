import express from "express";
import * as authService from "../services/authService.js";
import * as emailService from "../services/emailService.js";
import { verifyFirebaseToken } from "../middleware/auth.js";
import { handleError } from "../utils/errors.js";
import {
  validateName,
  validateEmail,
  validatePhone,
} from "../utils/validators.js";

const router = express.Router();

// Require authentication for all routes
router.use(verifyFirebaseToken);

/**
 * GET /api/v1/users/profile
 * Get user profile
 */
router.get("/profile", async (req, res) => {
  try {
    const profile = await authService.getUserProfile(req.user.uid);

    res.json({
      success: true,
      data: { profile },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * PUT /api/v1/users/profile
 * Update user profile
 */
router.put("/profile", async (req, res) => {
  try {
    const { name, phone, email } = req.body;

    // Validate inputs
    const updates = {};

    if (name !== undefined) {
      updates.name = validateName(name);
    }

    if (phone !== undefined) {
      updates.phone = validatePhone(phone);
    }

    if (email !== undefined) {
      updates.email = validateEmail(email);
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "At least one field must be provided",
        },
      });
    }

    const profile = await authService.updateUserProfile(req.user.uid, updates);

    res.json({
      success: true,
      data: { profile },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/users/verify-email
 * Send email verification OTP
 */
router.post("/verify-email", async (req, res) => {
  try {
    const userProfile = await authService.getUserProfile(req.user.uid);

    if (!userProfile.email) {
      return res.status(400).json({
        success: false,
        error: {
          code: "NO_EMAIL",
          message: "User does not have an email address",
        },
      });
    }

    const otp = await authService.createOTP(userProfile.email, "email");

    // Send OTP via email
    try {
      await emailService.sendOtpEmail(userProfile.email, otp, "email");
    } catch (emailError) {
      console.error("Failed to send verification email:", emailError);
      // Continue anyway, return OTP in dev mode
    }

    res.json({
      success: true,
      message: "Verification OTP sent to email",
      // Remove in production:
      ...(process.env.NODE_ENV === "development" && { otp }),
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/users/confirm-email-verification
 * Confirm email verification with OTP
 */
router.post("/confirm-email-verification", async (req, res) => {
  try {
    const { otp } = req.body;

    if (!otp) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "OTP required",
        },
      });
    }

    const userProfile = await authService.getUserProfile(req.user.uid);

    if (!userProfile.email) {
      return res.status(400).json({
        success: false,
        error: {
          code: "NO_EMAIL",
          message: "User does not have an email address",
        },
      });
    }

    await authService.verifyOTP(userProfile.email, otp);
    await authService.markEmailVerified(req.user.uid);

    res.json({
      success: true,
      message: "Email verified successfully",
    });
  } catch (error) {
    handleError(error, res);
  }
});

export default router;

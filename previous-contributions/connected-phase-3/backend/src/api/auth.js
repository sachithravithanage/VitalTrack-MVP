import express from "express";
import * as authService from "../services/authService.js";
import * as emailService from "../services/emailService.js";
import { verifyAuthToken } from "../middleware/auth.js";
import {
  validateEmail,
  validatePhone,
  validatePassword,
  validateOTP,
  validateUserRole,
} from "../utils/validators.js";
import { handleError } from "../utils/errors.js";

const router = express.Router();

/**
 * POST /api/v1/auth/signup
 * Register a new user
 */
router.post("/signup", async (req, res) => {
  try {
    const {
      email,
      phone,
      identifier,
      password,
      name,
      role,
      verifiedCredentialType,
    } = req.body;
    const normalizedRole = role ? String(role).toLowerCase() : "patient";

    // Validate inputs
    let normalizedEmail = email ? validateEmail(email) : null;
    let normalizedPhone = phone ? validatePhone(phone) : null;

    if (identifier) {
      const identifierText = String(identifier).trim();
      if (identifierText.includes("@")) {
        normalizedEmail = validateEmail(identifierText);
      } else {
        normalizedPhone = validatePhone(identifierText);
      }
    }

    if (!normalizedEmail && !normalizedPhone) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Either email or phone is required",
        },
      });
    }

    if (
      verifiedCredentialType &&
      !["email", "phone"].includes(String(verifiedCredentialType))
    ) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid verified credential type",
        },
      });
    }

    if (verifiedCredentialType === "email" && !normalizedEmail) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Verified credential must exist on account",
        },
      });
    }

    if (verifiedCredentialType === "phone" && !normalizedPhone) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Verified credential must exist on account",
        },
      });
    }

    validatePassword(password);
    validateUserRole(normalizedRole);

    if (!name || name.trim().length < 2) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Name is required",
        },
      });
    }

    const user = await authService.registerUser({
      email: normalizedEmail,
      phone: normalizedPhone,
      password,
      name,
      role: normalizedRole,
      verifiedCredentialType:
        verifiedCredentialType &&
        ["email", "phone"].includes(verifiedCredentialType)
          ? verifiedCredentialType
          : null,
    });
    const customToken = await authService.createCustomAuthToken(user.uid);

    res.status(201).json({
      success: true,
      data: {
        user,
        customToken,
      },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/send-otp
 * Send OTP to phone or email
 */
router.post("/send-otp", async (req, res) => {
  try {
    const { credential, type, purpose } = req.body;
    const selectedType = ["phone", "email"].includes(type)
      ? type
      : String(credential || "").includes("@")
        ? "email"
        : "phone";

    if (!credential) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid credential",
        },
      });
    }

    let normalizedCredential = credential;

    // Validate based on type
    if (selectedType === "email") {
      normalizedCredential = validateEmail(credential);
      if (String(purpose || "login").toLowerCase() !== "signup") {
        await authService.ensureVerifiedEmailCredential(normalizedCredential);
      }
    } else {
      normalizedCredential = validatePhone(credential);
    }

    const otpPayload = await authService.createOTP(
      normalizedCredential,
      selectedType,
    );
    const { otp, remainingAttempts, maxAttempts } = otpPayload;

    if (
      selectedType === "email" &&
      (process.env.NODE_ENV || "development") !== "production"
    ) {
      console.log(`Email OTP for ${normalizedCredential}: ${otp}`);
    }

    // Send OTP via email or SMS
    if (selectedType === "email") {
      try {
        await emailService.sendOtpEmail(normalizedCredential, otp, "email");
      } catch (emailError) {
        console.error("Failed to send email:", emailError);
        // Continue anyway, return OTP in dev mode
      }
    } else {
      // For SMS, you would integrate with Twilio or similar
      console.log(`SMS OTP for ${normalizedCredential}: ${otp}`);
    }

    res.json({
      success: true,
      message: `OTP sent to ${selectedType}`,
      remainingAttempts,
      maxAttempts,
      // Remove in production:
      ...(process.env.NODE_ENV === "development" && { otp }),
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/forgot-password/send-otp
 * Send OTP for password reset
 */
router.post("/forgot-password/send-otp", async (req, res) => {
  try {
    const { credential, type } = req.body;
    const selectedType = ["phone", "email"].includes(type)
      ? type
      : String(credential || "").includes("@")
        ? "email"
        : "phone";

    if (!credential) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid credential",
        },
      });
    }

    const normalizedCredential =
      selectedType === "email"
        ? validateEmail(credential)
        : validatePhone(credential);

    const user = await authService.findUserByCredential(normalizedCredential);
    if (selectedType === "email" && user.emailVerified !== true) {
      return res.status(401).json({
        success: false,
        error: {
          code: "AUTHENTICATION_ERROR",
          message: "Email is not verified for password recovery",
        },
      });
    }
    if (selectedType === "phone" && user.phoneVerified === false) {
      return res.status(401).json({
        success: false,
        error: {
          code: "AUTHENTICATION_ERROR",
          message: "Phone number is not verified for password recovery",
        },
      });
    }

    const otpPayload = await authService.createOTP(
      normalizedCredential,
      selectedType,
    );
    const { otp, remainingAttempts, maxAttempts } = otpPayload;

    if (selectedType === "email") {
      try {
        await emailService.sendOtpEmail(
          normalizedCredential,
          otp,
          "password reset",
        );
      } catch (emailError) {
        console.error("Failed to send reset email:", emailError);
      }
    } else {
      console.log(`Password reset SMS OTP for ${normalizedCredential}: ${otp}`);
    }

    res.json({
      success: true,
      message: `Password reset OTP sent to ${selectedType}`,
      remainingAttempts,
      maxAttempts,
      ...(process.env.NODE_ENV === "development" && { otp }),
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/forgot-password/reset
 * Reset password using OTP
 */
router.post("/forgot-password/reset", async (req, res) => {
  try {
    const { credential, otp, newPassword } = req.body;

    if (!credential || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Credential, OTP, and new password required",
        },
      });
    }

    validateOTP(otp);
    validatePassword(newPassword);

    const normalizedCredential = credential.includes("@")
      ? validateEmail(credential)
      : validatePhone(credential);

    if (normalizedCredential.includes("@")) {
      await authService.ensureVerifiedEmailCredential(normalizedCredential);
    }

    await authService.verifyOTP(normalizedCredential, otp);
    const user = await authService.resetPasswordByCredential(
      normalizedCredential,
      newPassword,
    );

    res.json({
      success: true,
      message: "Password reset successful",
      data: {
        uid: user.uid,
      },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/verify-otp
 * Verify OTP sent to phone or email
 */
router.post("/verify-otp", async (req, res) => {
  try {
    const { credential, otp } = req.body;

    if (!credential || !otp) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Credential and OTP required",
        },
      });
    }

    validateOTP(otp);

    const normalizedCredential = credential.includes("@")
      ? validateEmail(credential)
      : validatePhone(credential);

    const verified = await authService.verifyOTP(normalizedCredential, otp);

    res.json({
      success: true,
      message: "OTP verified successfully",
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/login/check
 * Validate login credentials before OTP dispatch
 */
router.post("/login/check", async (req, res) => {
  try {
    const { credential, password } = req.body;

    if (!credential || !password) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Credential and password required",
        },
      });
    }

    await authService.loginUser(credential, password);

    res.json({
      success: true,
      data: {
        valid: true,
      },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/login
 * Login user with email/phone and password
 */
router.post("/login", async (req, res) => {
  try {
    const { credential, password } = req.body;

    if (!credential || !password) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Credential and password required",
        },
      });
    }

    const user = await authService.loginUser(credential, password);
    const customToken = await authService.createCustomAuthToken(user.uid);

    res.json({
      success: true,
      data: {
        user,
        customToken,
      },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/logout
 * Logout user (optional - mainly for client-side)
 */
router.post("/logout", verifyAuthToken, (req, res) => {
  // Token lifecycle is primarily handled on the client side.
  // This endpoint can be used to invalidate tokens or clean up sessions
  res.json({
    success: true,
    message: "Logged out successfully",
  });
});

/**
 * GET /api/v1/auth/profile
 * Get current user's profile
 */
router.get("/profile", verifyAuthToken, async (req, res) => {
  try {
    const profile = await authService.getUserProfile(req.user.uid);

    res.json({
      success: true,
      data: {
        profile,
      },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/step-up/send-otp
 * Send OTP for step-up verification (authenticated users only)
 */
router.post("/step-up/send-otp", verifyAuthToken, async (req, res) => {
  try {
    const { purpose, channel } = req.body;
    const selectedChannel = channel === "email" ? "email" : "phone";

    if (!purpose || String(purpose).trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Purpose is required",
        },
      });
    }

    const userProfile = await authService.getUserProfile(req.user.uid);

    let credential;
    if (selectedChannel === "email") {
      if (!userProfile.email || userProfile.emailVerified !== true) {
        return res.status(401).json({
          success: false,
          error: {
            code: "AUTHENTICATION_ERROR",
            message: "Verified email is required for email step-up",
          },
        });
      }
      credential = validateEmail(userProfile.email);
    } else {
      if (!userProfile.phone) {
        return res.status(400).json({
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Phone number is required for step-up",
          },
        });
      }
      credential = validatePhone(userProfile.phone);
    }

    const otpPayload = await authService.createOTP(credential, selectedChannel);
    const { otp, remainingAttempts, maxAttempts } = otpPayload;

    if (selectedChannel === "email") {
      try {
        await emailService.sendOtpEmail(
          credential,
          otp,
          "security verification",
        );
      } catch (emailError) {
        console.error("Failed to send step-up email:", emailError);
      }
    } else {
      console.log(`Step-up SMS OTP for ${credential}: ${otp}`);
    }

    res.json({
      success: true,
      message: `Step-up OTP sent to ${selectedChannel}`,
      remainingAttempts,
      maxAttempts,
      ...(process.env.NODE_ENV === "development" && { otp }),
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * POST /api/v1/auth/step-up/verify
 * Verify step-up OTP and issue short-lived action token
 */
router.post("/step-up/verify", verifyAuthToken, async (req, res) => {
  try {
    const { purpose, otp, channel } = req.body;
    const selectedChannel = channel === "email" ? "email" : "phone";

    if (!purpose || !otp) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Purpose and OTP are required",
        },
      });
    }

    validateOTP(otp);

    const userProfile = await authService.getUserProfile(req.user.uid);

    let credential;
    if (selectedChannel === "email") {
      if (!userProfile.email || userProfile.emailVerified !== true) {
        return res.status(401).json({
          success: false,
          error: {
            code: "AUTHENTICATION_ERROR",
            message: "Verified email is required for email step-up",
          },
        });
      }
      credential = validateEmail(userProfile.email);
    } else {
      if (!userProfile.phone) {
        return res.status(400).json({
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Phone number is required for step-up",
          },
        });
      }
      credential = validatePhone(userProfile.phone);
    }

    await authService.verifyOTP(credential, otp);
    const stepUpToken = await authService.createStepUpToken(
      req.user.uid,
      String(purpose),
    );

    res.json({
      success: true,
      data: {
        stepUpToken,
        purpose: String(purpose),
      },
    });
  } catch (error) {
    handleError(error, res);
  }
});

export default router;

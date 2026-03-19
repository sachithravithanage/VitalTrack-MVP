import jwt from "jsonwebtoken";
import { config } from "../config/env.js";
import { AuthenticationError } from "../utils/errors.js";

/**
 * Verify Firebase ID token and attach user to request
 */
export async function verifyFirebaseToken(req, res, next) {
  try {
    const token = extractToken(req);

    if (!token) {
      throw new AuthenticationError("No token provided");
    }

    // Verify the Firebase ID token using the admin SDK
    const { auth } = await import("../config/firebase.js").then((m) => ({
      auth: m.auth,
    }));

    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
    };

    next();
  } catch (error) {
    if (error instanceof AuthenticationError) {
      return res.status(401).json({
        success: false,
        error: {
          code: "AUTHENTICATION_ERROR",
          message: error.message,
        },
      });
    }

    res.status(401).json({
      success: false,
      error: {
        code: "INVALID_TOKEN",
        message: "Invalid or expired token",
      },
    });
  }
}

/**
 * Verify JWT token (for custom tokens)
 */
export function verifyJWT(req, res, next) {
  try {
    const token = extractToken(req);

    if (!token) {
      throw new AuthenticationError("No token provided");
    }

    const decoded = jwt.verify(token, config.jwtSecret);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      error: {
        code: "INVALID_TOKEN",
        message: "Invalid or expired token",
      },
    });
  }
}

/**
 * Require specific user role
 */
export function requireRole(...roles) {
  return async (req, res, next) => {
    try {
      const { db } = await import("../config/firebase.js").then((m) => ({
        db: m.db,
      }));

      const userDoc = await db.collection("users").doc(req.user.uid).get();

      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          error: {
            code: "USER_NOT_FOUND",
            message: "User not found",
          },
        });
      }

      const userData = userDoc.data();

      const normalizedRequiredRoles = roles.map((r) =>
        String(r || "").toLowerCase(),
      );
      const userRoles = Array.isArray(userData.roles)
        ? userData.roles.map((role) => String(role || "").toLowerCase())
        : [String(userData.role || "patient").toLowerCase()];
      const activeRole = String(
        userData.activeRole || userData.role || userRoles[0] || "patient",
      ).toLowerCase();

      const hasAnyRequiredRole = normalizedRequiredRoles.some((role) =>
        userRoles.includes(role),
      );

      if (!hasAnyRequiredRole) {
        return res.status(403).json({
          success: false,
          error: {
            code: "AUTHORIZATION_ERROR",
            message: "Insufficient permissions",
          },
        });
      }

      req.userRole = normalizedRequiredRoles.includes(activeRole)
        ? activeRole
        : userRoles.find((role) => normalizedRequiredRoles.includes(role));
      next();
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: "INTERNAL_ERROR",
          message: "Error checking permissions",
        },
      });
    }
  };
}

/**
 * Require a valid one-time step-up token for sensitive actions
 */
export function requireStepUp(purpose) {
  return async (req, res, next) => {
    try {
      const tokenHeader = req.headers["x-step-up-token"];
      const token = Array.isArray(tokenHeader) ? tokenHeader[0] : tokenHeader;

      if (!token || String(token).trim().length === 0) {
        return res.status(403).json({
          success: false,
          error: {
            code: "STEP_UP_REQUIRED",
            message: "Step-up verification is required",
          },
        });
      }

      const authService = await import("../services/authService.js");
      await authService.consumeStepUpToken(
        req.user.uid,
        String(token),
        purpose,
      );
      next();
    } catch (error) {
      return res.status(403).json({
        success: false,
        error: {
          code: "STEP_UP_INVALID",
          message: error.message || "Invalid step-up token",
        },
      });
    }
  };
}

/**
 * Extract token from Authorization header
 */
function extractToken(req) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return null;
  }

  const parts = authHeader.split(" ");

  if (parts.length !== 2 || parts[0] !== "Bearer") {
    return null;
  }

  return parts[1];
}

export default {
  verifyFirebaseToken,
  verifyJWT,
  requireRole,
  requireStepUp,
};

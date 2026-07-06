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

      if (!roles.includes(userData.role)) {
        return res.status(403).json({
          success: false,
          error: {
            code: "AUTHORIZATION_ERROR",
            message: "Insufficient permissions",
          },
        });
      }

      req.userRole = userData.role;
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
};

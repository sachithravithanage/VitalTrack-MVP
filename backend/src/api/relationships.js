import express from "express";
import * as relationshipService from "../services/relationshipService.js";
import * as authService from "../services/authService.js";
import {
  verifyFirebaseToken,
  requireRole,
  requireStepUp,
} from "../middleware/auth.js";
import { handleError } from "../utils/errors.js";

const router = express.Router();

// Require authentication for all routes
router.use(verifyFirebaseToken);

/**
 * POST /api/v1/relationships/link-code
 * Generate a link code for a patient (patient only)
 */
router.post(
  "/link-code",
  requireRole("patient"),
  requireStepUp("manage_relationships"),
  async (req, res) => {
    try {
      const code = await relationshipService.generateLinkCode(req.user.uid);

      res.status(201).json({
        success: true,
        data: { code },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

/**
 * POST /api/v1/relationships/add-patient
 * Caregiver adds a patient using link code
 */
router.post(
  "/add-patient",
  requireRole("caregiver"),
  requireStepUp("manage_relationships"),
  async (req, res) => {
    try {
      const { code, disease } = req.body;

      if (!code) {
        return res.status(400).json({
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Link code required",
          },
        });
      }

      const result = await relationshipService.useLinkCode(code, req.user.uid);

      // Update disease if provided
      if (disease) {
        const relationshipId = `${result.patientId}-${req.user.uid}`;
        const db = (await import("../config/firebase.js")).db;

        await db.collection("relationships").doc(relationshipId).update({
          disease,
        });
      }

      res.status(201).json({
        success: true,
        data: { relationship: result },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

/**
 * POST /api/v1/relationships/create-patient
 * Caregiver creates a new managed patient and links immediately
 */
router.post(
  "/create-patient",
  requireRole("caregiver"),
  requireStepUp("manage_relationships"),
  async (req, res) => {
    try {
      const { name, disease } = req.body;

      if (!name || !disease) {
        return res.status(400).json({
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Patient name and disease are required",
          },
        });
      }

      const result = await relationshipService.createManagedPatient(
        req.user.uid,
        {
          name,
          disease,
        },
      );

      res.status(201).json({
        success: true,
        data: { relationship: result },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

/**
 * GET /api/v1/relationships/patients
 * Get list of patients (for caregivers)
 */
router.get("/patients", requireRole("caregiver"), async (req, res) => {
  try {
    const patients = await relationshipService.getCaregiverPatients(
      req.user.uid,
    );

    res.json({
      success: true,
      data: { patients },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/relationships/caregivers
 * Get list of caregivers (for patients)
 */
router.get("/caregivers", requireRole("patient"), async (req, res) => {
  try {
    const caregivers = await relationshipService.getPatientCaregivers(
      req.user.uid,
    );

    res.json({
      success: true,
      data: { caregivers },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * DELETE /api/v1/relationships/:userId
 * Remove relationship between patient and caregiver
 */
router.delete("/:userId", verifyFirebaseToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.uid;

    // Determine who is patient and who is caregiver
    const currentUserDoc = await (await import("../config/firebase.js")).db
      .collection("users")
      .doc(currentUserId)
      .get();

    const currentUserRole =
      currentUserDoc.data().activeRole || currentUserDoc.data().role;

    if (currentUserRole === "patient") {
      await relationshipService.removeRelationship(currentUserId, userId);
    } else {
      await relationshipService.removeRelationship(userId, currentUserId);
    }

    res.json({
      success: true,
      message: "Relationship removed successfully",
    });
  } catch (error) {
    handleError(error, res);
  }
});

export default router;

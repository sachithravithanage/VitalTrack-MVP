import express from "express";
import * as hotspotService from "../services/hotspotService.js";
import { verifyFirebaseToken, requireRole } from "../middleware/auth.js";
import { handleError } from "../utils/errors.js";
import { validateCoordinates } from "../utils/validators.js";

const router = express.Router();

// Require authentication for all routes
router.use(verifyFirebaseToken);

/**
 * POST /api/v1/hotspot/submit
 * Submit hotspot location data
 */
router.post(
  "/submit",
  requireRole("patient", "caregiver"),
  async (req, res) => {
    try {
      const {
        subject,
        subjectPatientId,
        hometown,
        workplace,
        places,
        disease,
        coordinates,
      } = req.body;

      if (!hometown) {
        return res.status(400).json({
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Hometown is required",
          },
        });
      }

      let patientId = req.user.uid;
      let resolvedSubject = subject;

      if (req.userRole === "caregiver") {
        if (!subjectPatientId || String(subjectPatientId).trim().length === 0) {
          return res.status(400).json({
            success: false,
            error: {
              code: "VALIDATION_ERROR",
              message: "Caregiver submissions must include subjectPatientId",
            },
          });
        }

        patientId = String(subjectPatientId).trim();
        await hotspotService.validateCaregiverPatientAccess(
          req.user.uid,
          patientId,
        );
      }

      if (!resolvedSubject || String(resolvedSubject).trim().length === 0) {
        const { db } = await import("../config/dataLayer.js").then((m) => ({
          db: m.db,
        }));
        const userDoc = await db.collection("users").doc(patientId).get();
        resolvedSubject = userDoc.exists
          ? String(userDoc.data()?.name || "patient")
          : "patient";
      }

      // Validate coordinates if provided
      let validCoordinates = null;
      if (coordinates?.latitude && coordinates?.longitude) {
        validCoordinates = validateCoordinates(
          coordinates.latitude,
          coordinates.longitude,
        );
      }

      const data = await hotspotService.submitHotspotData(patientId, {
        subject: resolvedSubject,
        subjectPatientId: patientId,
        submittedBy: req.user.uid,
        submittedByRole: req.userRole,
        hometown,
        workplace,
        places,
        disease,
        coordinates: validCoordinates,
      });

      res.status(201).json({
        success: true,
        data: { hotspot: data },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

/**
 * GET /api/v1/hotspot/patient/:patientId
 * Get hotspot data for a patient
 */
router.get(
  "/patient/:patientId",
  verifyFirebaseToken,
  requireRole("patient", "caregiver"),
  async (req, res) => {
    try {
      const patientId = req.params.patientId;
      const requestingUserId = req.user.uid;
      const requestingUserRole = req.userRole;

      // Patients can only access their own data
      if (requestingUserRole === "patient" && requestingUserId !== patientId) {
        return res.status(403).json({
          success: false,
          error: {
            code: "AUTHORIZATION_ERROR",
            message: "Patients can only access their own hotspot data",
          },
        });
      }

      // Caregivers must have an active relationship with the patient
      if (requestingUserRole === "caregiver") {
        await hotspotService.validateCaregiverPatientAccess(
          requestingUserId,
          patientId,
        );
      }

      const hotspots = await hotspotService.getPatientHotspots(patientId);

      res.json({
        success: true,
        data: { hotspots },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

/**
 * GET /api/v1/hotspot/heatmap
 * Get heatmap data (aggregated hotspot data)
 */
router.get("/heatmap/data", verifyFirebaseToken, async (req, res) => {
  try {
    const { disease } = req.query;

    const heatmapData = await hotspotService.getHeatmapData(null, disease);

    res.json({
      success: true,
      data: { heatmapData },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/hotspot/heatmap/regions
 * Get district-level hotspot risk summary for Sri Lanka
 */
router.get("/heatmap/regions", verifyFirebaseToken, async (req, res) => {
  try {
    const { disease } = req.query;

    const summary = await hotspotService.getRegionalHeatmapData(disease);

    res.json({
      success: true,
      data: summary,
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/hotspot/stats/:patientId
 * Get hotspot statistics for a patient
 */
router.get(
  "/stats/:patientId",
  verifyFirebaseToken,
  requireRole("patient", "caregiver"),
  async (req, res) => {
    try {
      const patientId = req.params.patientId;
      const requestingUserId = req.user.uid;
      const requestingUserRole = req.userRole;

      // Patients can only access their own stats
      if (requestingUserRole === "patient" && requestingUserId !== patientId) {
        return res.status(403).json({
          success: false,
          error: {
            code: "AUTHORIZATION_ERROR",
            message: "Patients can only access their own hotspot stats",
          },
        });
      }

      // Caregivers must have an active relationship with the patient
      if (requestingUserRole === "caregiver") {
        await hotspotService.validateCaregiverPatientAccess(
          requestingUserId,
          patientId,
        );
      }

      const stats = await hotspotService.getHotspotStats(patientId);

      res.json({
        success: true,
        data: { stats },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

/**
 * GET /api/v1/hotspot/potential
 * Find potential hotspots (high-frequency disease locations)
 */
router.get("/potential", verifyFirebaseToken, async (req, res) => {
  try {
    const { disease, minCases } = req.query;

    const hotspots = await hotspotService.findPotentialHotspots(
      disease,
      parseInt(minCases) || 3,
    );

    res.json({
      success: true,
      data: { hotspots },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/hotspot/nearby
 * Get nearby cases within a radius
 */
router.get("/nearby", verifyFirebaseToken, async (req, res) => {
  try {
    const { latitude, longitude, radius } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Latitude and longitude required",
        },
      });
    }

    validateCoordinates(latitude, longitude);

    const cases = await hotspotService.getNearByCases(
      parseFloat(latitude),
      parseFloat(longitude),
      parseFloat(radius) || 5,
    );

    res.json({
      success: true,
      data: { cases },
    });
  } catch (error) {
    handleError(error, res);
  }
});

export default router;

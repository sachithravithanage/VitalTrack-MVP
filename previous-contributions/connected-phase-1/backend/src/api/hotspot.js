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
router.post("/submit", requireRole("patient"), async (req, res) => {
  try {
    const { subject, hometown, workplace, places, disease, coordinates } =
      req.body;

    if (!subject || !hometown) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Subject and hometown are required",
        },
      });
    }

    // Validate coordinates if provided
    let validCoordinates = null;
    if (coordinates?.latitude && coordinates?.longitude) {
      validCoordinates = validateCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
    }

    const data = await hotspotService.submitHotspotData(req.user.uid, {
      subject,
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
});

/**
 * GET /api/v1/hotspot/patient/:patientId
 * Get hotspot data for a patient
 */
router.get("/patient/:patientId", verifyFirebaseToken, async (req, res) => {
  try {
    const hotspots = await hotspotService.getPatientHotspots(
      req.params.patientId,
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
 * GET /api/v1/hotspot/stats/:patientId
 * Get hotspot statistics for a patient
 */
router.get("/stats/:patientId", verifyFirebaseToken, async (req, res) => {
  try {
    const stats = await hotspotService.getHotspotStats(req.params.patientId);

    res.json({
      success: true,
      data: { stats },
    });
  } catch (error) {
    handleError(error, res);
  }
});

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

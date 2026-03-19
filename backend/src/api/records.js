import express from "express";
import * as recordService from "../services/recordService.js";
import * as pdfService from "../services/pdfService.js";
import * as notificationService from "../services/notificationService.js";
import * as authService from "../services/authService.js";
import * as relationshipService from "../services/relationshipService.js";
import {
  verifyFirebaseToken,
  requireRole,
  requireStepUp,
} from "../middleware/auth.js";
import {
  handleError,
  ValidationError,
  AuthenticationError,
} from "../utils/errors.js";

const router = express.Router();

// Require authentication for all routes
router.use(verifyFirebaseToken);

/**
 * POST /api/v1/records
 * Create a new medical record
 */
router.post("/", requireRole("patient", "caregiver"), async (req, res) => {
  try {
    const {
      patientId,
      disease,
      temperature,
      fluidIntake,
      urineOutput,
      urineColor,
      values,
      symptoms,
      notes,
    } = req.body;

    if (!disease) {
      return res.status(400).json({
        success: false,
        error: { code: "VALIDATION_ERROR", message: "Disease required" },
      });
    }

    let targetPatientId = req.user.uid;

    if (req.userRole === "caregiver") {
      if (!patientId) {
        throw new ValidationError("Patient ID is required for caregivers");
      }

      const isLinked = await relationshipService.isCaregiverLinkedToPatient(
        patientId,
        req.user.uid,
      );

      if (!isLinked) {
        throw new AuthenticationError(
          "Caregiver is not linked to this patient",
        );
      }

      targetPatientId = patientId;
    }

    const record = await recordService.createRecord(targetPatientId, {
      disease,
      temperature,
      fluidIntake,
      urineOutput,
      urineColor,
      values,
      symptoms,
      notes,
      createdBy: req.user.uid,
    });

    // Send notification to caregivers
    const userProfile = await authService.getUserProfile(targetPatientId);
    await notificationService.notifyNewRecord(
      targetPatientId,
      userProfile.name,
      disease,
    );

    // Check for high temperature alert
    if (temperature && parseFloat(temperature) > 38.5) {
      await notificationService.notifyHighTemperature(
        targetPatientId,
        userProfile.name,
        temperature,
      );
    }

    res.status(201).json({
      success: true,
      data: { record },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/records
 * List records with filters
 */
router.get("/", requireRole("patient", "caregiver"), async (req, res) => {
  try {
    const { disease, timelineFilter, patientId } = req.query;

    // Patients can only view their own records
    // Caregivers can view linked patients' records
    let targetPatientId = req.user.uid;

    if (req.userRole === "caregiver") {
      if (!patientId) {
        throw new ValidationError("Patient ID is required for caregivers");
      }

      const isLinked = await relationshipService.isCaregiverLinkedToPatient(
        patientId,
        req.user.uid,
      );

      if (!isLinked) {
        throw new AuthenticationError(
          "Caregiver is not linked to this patient",
        );
      }

      targetPatientId = patientId;
    }

    const records = await recordService.listRecords(targetPatientId, {
      disease,
      timelineFilter,
    });

    res.json({
      success: true,
      data: { records },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/records/:recordId
 * Get a specific record
 */
router.get("/:recordId", verifyFirebaseToken, async (req, res) => {
  try {
    const userProfile = await authService.getUserProfile(req.user.uid);
    const record = await recordService.getRecord(req.params.recordId);

    if (userProfile.role === "patient" && record.patientId !== req.user.uid) {
      throw new AuthenticationError("Not authorized to access this record");
    }

    if (userProfile.role === "caregiver") {
      const isLinked = await relationshipService.isCaregiverLinkedToPatient(
        record.patientId,
        req.user.uid,
      );

      if (!isLinked) {
        throw new AuthenticationError("Not authorized to access this record");
      }
    }

    res.json({
      success: true,
      data: { record },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * PUT /api/v1/records/:recordId
 * Update a record
 */
router.put("/:recordId", requireRole("patient"), async (req, res) => {
  try {
    const {
      temperature,
      fluidIntake,
      urineOutput,
      urineColor,
      symptoms,
      notes,
    } = req.body;

    const record = await recordService.updateRecord(req.params.recordId, {
      temperature,
      fluidIntake,
      urineOutput,
      urineColor,
      symptoms,
      notes,
    });

    res.json({
      success: true,
      data: { record },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * DELETE /api/v1/records/:recordId
 * Delete a record
 */
router.delete("/:recordId", requireRole("patient"), async (req, res) => {
  try {
    await recordService.deleteRecord(req.params.recordId, req.user.uid);

    res.json({
      success: true,
      message: "Record deleted successfully",
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/records/stats/:patientId
 * Get record statistics
 */
router.get("/stats/:patientId", verifyFirebaseToken, async (req, res) => {
  try {
    const { timelineFilter } = req.query;
    const userProfile = await authService.getUserProfile(req.user.uid);

    if (
      userProfile.role === "patient" &&
      req.params.patientId !== req.user.uid
    ) {
      throw new AuthenticationError("Not authorized to view these statistics");
    }

    if (userProfile.role === "caregiver") {
      const isLinked = await relationshipService.isCaregiverLinkedToPatient(
        req.params.patientId,
        req.user.uid,
      );

      if (!isLinked) {
        throw new AuthenticationError(
          "Not authorized to view these statistics",
        );
      }
    }

    const stats = await recordService.getRecordStats(
      req.params.patientId,
      timelineFilter,
    );

    res.json({
      success: true,
      data: { stats },
    });
  } catch (error) {
    handleError(error, res);
  }
});

/**
 * GET /api/v1/records/export/pdf
 * Export records as PDF
 */
router.get(
  "/export/pdf",
  requireRole("patient", "caregiver"),
  requireStepUp("export_records"),
  async (req, res) => {
    try {
      const { timelineFilter, patientId } = req.query;

      let targetPatientId = req.user.uid;

      if (req.userRole === "caregiver") {
        if (!patientId) {
          throw new ValidationError("Patient ID is required for caregivers");
        }

        const isLinked = await relationshipService.isCaregiverLinkedToPatient(
          patientId,
          req.user.uid,
        );

        if (!isLinked) {
          throw new AuthenticationError(
            "Caregiver is not linked to this patient",
          );
        }

        targetPatientId = patientId;
      }

      const records = await recordService.listRecords(targetPatientId, {
        timelineFilter,
      });
      const userProfile = await authService.getUserProfile(targetPatientId);

      if (records.length === 0) {
        return res.status(400).json({
          success: false,
          error: {
            code: "NO_RECORDS",
            message: "No records found to export",
          },
        });
      }

      const pdfInfo = await pdfService.generatePDFReport(
        targetPatientId,
        records,
        userProfile,
      );
      const signedUrl = await pdfService.getPDFDownloadUrl(pdfInfo.filePath);

      res.json({
        success: true,
        data: {
          pdf: {
            ...pdfInfo,
            url: signedUrl,
          },
        },
      });
    } catch (error) {
      handleError(error, res);
    }
  },
);

export default router;

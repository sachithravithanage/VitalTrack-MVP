import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { config, validateConfig } from "./config/env.js";

// API routes
import authRoutes from "./api/auth.js";
import usersRoutes from "./api/users.js";
import recordsRoutes from "./api/records.js";
import relationshipsRoutes from "./api/relationships.js";
import notificationsRoutes from "./api/notifications.js";
import hotspotRoutes from "./api/hotspot.js";
import { generateMissingRecordNotificationsForAllPatients } from "./services/notificationService.js";
import { initDataLayer, getDataLayerHealth } from "./config/dataLayer.js";

// Load environment variables
dotenv.config();

// Validate configuration
try {
  validateConfig();
} catch (error) {
  console.error("Configuration error:", error.message);
  process.exit(1);
}

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: "16mb" }));
app.use(express.urlencoded({ limit: "16mb", extended: true }));

// Request logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get("/health", async (req, res) => {
  const dataLayer = await getDataLayerHealth();
  const status = dataLayer.connected ? "ok" : "degraded";
  res.status(dataLayer.connected ? 200 : 503).json({
    status,
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    dataLayer,
  });
});

// API routes
const apiPrefix = `/api/${config.apiVersion}`;

app.use(`${apiPrefix}/auth`, authRoutes);
app.use(`${apiPrefix}/users`, usersRoutes);
app.use(`${apiPrefix}/records`, recordsRoutes);
app.use(`${apiPrefix}/relationships`, relationshipsRoutes);
app.use(`${apiPrefix}/notifications`, notificationsRoutes);
app.use(`${apiPrefix}/hotspot`, hotspotRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: "NOT_FOUND",
      message: "Endpoint not found",
    },
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error("Unhandled error:", error);

  res.status(error.statusCode || 500).json({
    success: false,
    error: {
      code: error.code || "INTERNAL_ERROR",
      message: error.message || "An unexpected error occurred",
    },
  });
});

// Start server
const PORT = config.port || 5000;

initDataLayer()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`VitalTrack Backend Server running on port ${PORT}`);
      console.log(`Environment: ${config.nodeEnv}`);
      console.log(`API Version: ${config.apiVersion}`);
      console.log(
        `Available at: http://localhost:${PORT}/api/${config.apiVersion}`,
      );

      const runInactivitySweep = async () => {
        try {
          const result = await generateMissingRecordNotificationsForAllPatients();
          console.log(
            `[notifications] inactivity sweep checked ${result.patientsChecked} patients, generated ${result.generatedTotal}`,
          );
        } catch (error) {
          console.error("[notifications] inactivity sweep failed:", error);
        }
      };

      runInactivitySweep();
      setInterval(runInactivitySweep, 15 * 60 * 1000);
    });
  })
  .catch((error) => {
    console.error("Failed to initialize data layer:", error);
    process.exit(1);
  });

export default app;

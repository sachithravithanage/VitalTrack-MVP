# VitalTrack - Backend Engine

This is the Python-based backend for the VitalTrack project, designed to handle real-time data processing for Dengue tracking in Sri Lanka.

## Features
* **Automated Tallying:** Listens for new entries in the `patient_logs` Firestore collection.
* **Heatmap Updates:** Automatically increments district-level statistics in the `heatmap_statistics` collection whenever a new Dengue case is logged.
* **Local Development:** Configured to run using the Firebase Emulator Suite for safe, cost-free testing.

## Tech Stack
* **Language:** Python 3.14
* **Platform:** Firebase Cloud Functions
* **Database:** Google Cloud Firestore

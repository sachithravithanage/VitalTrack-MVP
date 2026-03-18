# VitalTrack - Backend Engine

This is the Python-based backend for the VitalTrack project, designed to handle real-time data processing for tracking multiple regional diseases (including Dengue and Leptospirosis) in Sri Lanka.

## Features

* **Universal Event Listener:** Listens for new patient entries in the `patient_logs` Firestore collection and dynamically categorizes them based on the `disease` field.
* **Automated Heatmap Updates:** Automatically increments district-level statistics in the `heatmap_statistics` collection. It smartly routes and updates the correct disease document (e.g., Dengue or Leptospirosis) whenever a new case is logged.
* **REST APIs:** Exposes dedicated API endpoints (like `get_dengue_data` and `get_lepto_data`) to serve compiled regional statistics directly to the Flutter frontend map.
* **Local Development:** Configured to run using the Firebase Emulator Suite (Functions & Firestore) with persistence commands for safe, cost-free, and continuous offline testing.

## Tech Stack

* **Language:** Python 3.14
* **Platform:** Firebase Cloud Functions
* **Database:** Google Cloud Firestore
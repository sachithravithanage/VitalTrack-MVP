# VitalTrack 💚

**Geo-spatial disease monitoring and patient care. Real-time health tracking, critical alerts, and community-driven heatmap visualization.**

VitalTrack is a comprehensive mobile application designed to assist in the monitoring and care of patients diagnosed with **Dengue** and **Rat Fever (Leptospirosis)**. By digitizing the manual logging of critical daily health parameters, VitalTrack helps prevent sudden critical situations, reduces human error, and provides doctors with accurate, exportable data.

Built by **Team vCode**.

---

## 📱 Key Features

* **Role-Based User Accounts:** * **Patient Profile:** For independent users to log their daily health metrics.
    * **Caregiver Profile:** For users assisting patients who are unable to log data themselves. Caregiver accounts can be securely linked to Patient accounts.
* **Daily Vitals Tracking:** Easily record critical daily parameters specifically advised by doctors for Dengue and Rat Fever, including:
    * Body Temperature
    * Fluid Intake
    * Urine Output
* **PDF Report Generation:** Export recorded health data into a clean, professional PDF report to present to medical professionals during consultations.
* **Disease Heatmap:** Community-driven heatmap visualization for geo-spatial disease monitoring.
* **Critical Alerts:** Automated notifications to keep tracking on schedule and alert users of potential critical health trends.

---

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart) for a beautiful, responsive, and cross-platform mobile experience.
* **Backend:** [Firebase](https://firebase.google.com/) 
    * **Firebase Authentication:** Secure user sign-up and login.
    * **Cloud Firestore:** NoSQL cloud database to store patient logs, user profiles, and linked account data.
    * **Firebase Storage:** (Optional) For storing generated PDFs or user avatars.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (latest stable version)
* Dart SDK
* Android Studio / VS Code with Flutter plugins
* A Firebase account

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/sachithravithanage/VitalTrack-MVP.git
    cd VitalTrack
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup:**
    * Create a new project in the [Firebase Console](https://console.firebase.google.com/).
    * Register your Android/iOS apps within the Firebase project.
    * Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) and place them in their respective directories (`android/app/` and `ios/Runner/`).
    * Enable **Authentication** (Email/Password) and **Cloud Firestore** in your Firebase console.

4.  **Run the application:**
    ```bash
    flutter run
    ```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

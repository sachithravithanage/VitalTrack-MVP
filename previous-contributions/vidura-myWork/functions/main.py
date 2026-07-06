from firebase_functions import firestore_fn, https_fn
from firebase_admin import initialize_app, firestore
import json

# This specific import is the "magic fix" for the Increment error
from google.cloud import firestore as google_firestore

# Initialize the Firebase Admin SDK
initialize_app()

# === 1. THE UNIVERSAL PATIENT LISTENER ===
# This function watches 'patient_logs' and updates the correct disease scoreboard
@firestore_fn.on_document_created(document="patient_logs/{logId}")
def process_new_patient_log(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    if event.data is None:
        return

    # Pull data from the new document
    patient_data = event.data.to_dict()
    disease = patient_data.get("disease")  # e.g., "Dengue" or "Leptospirosis"
    district = patient_data.get("district")

    if not disease or not district:
        print("Log ignored: Missing disease or district fields.")
        return

    db = firestore.client()
    # Path: heatmap_statistics -> [Disease Name]
    stats_ref = db.collection("heatmap_statistics").document(disease)
    
    # Use google_firestore.Increment to safely add 1 to the district count
    stats_ref.set({
        district: google_firestore.Increment(1)
    }, merge=True)
    
    print(f"Verified: 1 case of {disease} added to {district} scoreboard.")

# === 2. DENGUE POSTMAN API ===
@https_fn.on_request()
def get_dengue_data(req: https_fn.Request) -> https_fn.Response:
    db = firestore.client()
    doc = db.collection("heatmap_statistics").document("Dengue").get()
    
    data = doc.to_dict() if doc.exists else {}
    return https_fn.Response(
        json.dumps({"status": "success", "disease": "Dengue", "data": data}),
        status=200, mimetype="application/json"
    )

# === 3. LEPTOSPIROSIS POSTMAN API ===
@https_fn.on_request()
def get_lepto_data(req: https_fn.Request) -> https_fn.Response:
    db = firestore.client()
    doc = db.collection("heatmap_statistics").document("Leptospirosis").get()
    
    data = doc.to_dict() if doc.exists else {}
    return https_fn.Response(
        json.dumps({"status": "success", "disease": "Leptospirosis", "data": data}),
        status=200, mimetype="application/json"
    )
from firebase_functions import firestore_fn, https_fn
from firebase_admin import initialize_app, firestore
from google.cloud.firestore import Increment
import json

# Wakes up the Firebase admin privileges so we can edit the database
initialize_app()

# === FUNCTION 1: The Heatmap Background Engine ===
@firestore_fn.on_document_created(document="patient_logs/{logId}")
def update_dengue_heatmap(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:

    # If there is no data, stop the function
    if event.data is None:
        return

    # Grab the data from the newly submitted log
    patient_data = event.data.to_dict()
    disease = patient_data.get("disease")
    district = patient_data.get("district")

    # Check if the disease is Dengue and a district was provided
    if disease == "Dengue" and district:

        # Connect to your Firestore database
        db = firestore.client()

        # Point directly to your Dengue scoreboard
        stats_ref = db.collection("heatmap_statistics").document("Dengue")

        # Increment that specific district's tally by exactly 1
        stats_ref.set({
            district: Increment(1)
        }, merge=True)

        print(f"Successfully added 1 to {district} for Dengue!")


# === FUNCTION 2: The Postman API Endpoint ===
@https_fn.on_request()
def get_dengue_data(req: https_fn.Request) -> https_fn.Response:
    """An API endpoint that Postman can call to fetch data."""
    db = firestore.client()
    logs = db.collection("patient_logs").stream()
    
    # Gather all the patient data
    patient_list = []
    for doc in logs:
        patient_list.append(doc.to_dict())
        
    # Send it back to Postman as JSON
    return https_fn.Response(
        response=json.dumps({
            "status": "success", 
            "total_patients": len(patient_list), 
            "data": patient_list
        }),
        status=200,
        headers={"Content-Type": "application/json"}
    )
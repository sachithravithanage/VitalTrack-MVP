from firebase_functions import firestore_fn
from firebase_admin import initialize_app, firestore
from google.cloud.firestore import Increment

# Wakes up the Firebase admin privileges so we can edit the database
initialize_app()

# This tells Google's servers to listen for ANY new document added to 'patient_logs'
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
        # merge=True ensures it doesn't overwrite your other districts
        stats_ref.set({
            district: Increment(1)
        }, merge=True)
        
        print(f"Successfully added 1 to {district} for Dengue!")
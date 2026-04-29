library vital_track.globals;

// We are keeping the HealthRecord class because your history screens
// likely use it to format the UI cards!
class HealthRecord {
  HealthRecord(
    this.value,
    this.time,
    this.status,
    this.isAlert, {
    this.notes = '',
    this.hasVoiceNote = false,
    this.details = const [],
  });

  final String value;
  final String time;
  final String status;
  final bool isAlert;
  final String notes;
  final bool hasVoiceNote;
  final List<String> details;
}

// ALL STATIC GLOBAL LISTS AND USER VARIABLES HAVE BEEN DELETED!
// Your app will now correctly rely 100% on PatientProvider and HealthDataProvider.

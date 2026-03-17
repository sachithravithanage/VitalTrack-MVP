library vital_track.globals;

String globalUserName = '';
String globalUserRole = 'Patient';
String globalUserDOB = '';
String globalUserWeight = '';
String globalUserBloodType = '';

class HealthRecord {
  final String value;
  final String time;
  final String status;
  final bool isAlert;
  final String notes;
  final bool hasVoiceNote;

  // NEW: A list to hold specific details (like specific symptoms!)
  final List<String> details;

  HealthRecord(
    this.value,
    this.time,
    this.status,
    this.isAlert, {
    this.notes = '',
    this.hasVoiceNote = false,
    this.details = const [], // Defaults to empty for normal vitals
  });
}

// ==========================================
// DENGUE PATIENT HISTORY (Amila)
// ==========================================
List<HealthRecord> globalTempHistory = [];
List<HealthRecord> globalPlateletHistory = [];
List<HealthRecord> globalFluidHistory = [];
List<HealthRecord> globalUrineHistory = [];

// ==========================================
// LEPTOSPIROSIS PATIENT HISTORY (Saman)
// ==========================================
List<HealthRecord> globalLeptoTempHistory = []; // SEPARATED!
List<HealthRecord> globalLeptoUrineHistory = []; // SEPARATED!
List<HealthRecord> globalBPHistory = [];
List<HealthRecord> globalSymptomsHistory = [];

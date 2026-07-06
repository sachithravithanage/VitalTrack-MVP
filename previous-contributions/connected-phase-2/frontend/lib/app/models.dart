enum AppLanguage { english, sinhala }

enum UserRole { patient, caregiver }

enum LoginMethod { number4n, email }

enum DiseaseType { dengue, ratFever }

enum TimelineFilter { last24h, last3Days, last7Days }

class RecordEntry {
  RecordEntry({
    required this.patientId,
    required this.disease,
    required this.createdAt,
    required this.values,
    required this.notes,
    required this.createdBy,
  });

  final String patientId;
  final DiseaseType disease;
  final DateTime createdAt;
  final Map<String, String> values;
  final String notes;
  final String createdBy;
}

class PatientSummary {
  PatientSummary({
    required this.id,
    required this.name,
    required this.disease,
    this.linkCode,
  });

  final String id;
  final String name;
  final DiseaseType disease;
  String? linkCode;
}

class UserProfileData {
  UserProfileData({
    required this.id,
    required this.role,
    required this.roles,
    required this.name,
    required this.phone,
    this.email,
    this.emailVerified = false,
  });

  final String id;
  final UserRole role;
  final List<UserRole> roles;
  String name;
  String phone;
  String? email;
  bool emailVerified;
}

class HotspotResponse {
  HotspotResponse({
    required this.subject,
    required this.patientId,
    required this.disease,
    required this.hometown,
    required this.workplace,
    required this.places,
    required this.createdAt,
  });

  final String subject;
  final String patientId;
  final String disease;
  final String hometown;
  final String workplace;
  final String places;
  final DateTime createdAt;
}

class HotspotRegionSummary {
  HotspotRegionSummary({
    required this.district,
    required this.score,
    required this.riskLevel,
    required this.totalEvents,
    required this.hometownCount,
    required this.workplaceCount,
    required this.visitCount,
    required this.patients,
  });

  final String district;
  final double score;
  final String riskLevel;
  final int totalEvents;
  final int hometownCount;
  final int workplaceCount;
  final int visitCount;
  final int patients;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.read,
    this.data = const <String, dynamic>{},
    this.status,
  });

  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
  final bool read;
  final Map<String, dynamic> data;
  final String? status;
}

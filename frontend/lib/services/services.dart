import 'api_client.dart';

/// Service for medical records operations
class RecordService {
  final ApiClient _apiClient = apiClient;

  /// Create a new medical record
  Future<Map<String, dynamic>> createRecord({
    required String disease,
    required String temperature,
    String? fluidIntake,
    String? urineOutput,
    String? urineColor,
    Map<String, bool>? symptoms,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.createRecord(
        disease: disease,
        temperature: temperature,
        fluidIntake: fluidIntake,
        urineOutput: urineOutput,
        urineColor: urineColor,
        symptoms: symptoms,
        notes: notes,
      );
      return response;
    } catch (e) {
      print("Error creating record: $e");
      rethrow;
    }
  }

  /// List medical records
  Future<Map<String, dynamic>> listRecords({
    String? disease,
    String? timelineFilter,
    String? patientId,
  }) async {
    try {
      final response = await _apiClient.listRecords(
        disease: disease,
        timelineFilter: timelineFilter,
        patientId: patientId,
      );
      return response;
    } catch (e) {
      print("Error listing records: $e");
      rethrow;
    }
  }

  /// Get statistics for records
  Future<Map<String, dynamic>> getRecordStats({
    required String patientId,
    String? timelineFilter,
  }) async {
    try {
      final response = await _apiClient.getRecordStats(
        patientId: patientId,
        timelineFilter: timelineFilter,
      );
      return response;
    } catch (e) {
      print("Error getting record stats: $e");
      rethrow;
    }
  }

  /// Export records as PDF
  Future<Map<String, dynamic>> exportRecordsPdf({
    String? timelineFilter,
  }) async {
    try {
      final response = await _apiClient.exportRecordsPdf(
        timelineFilter: timelineFilter,
      );
      return response;
    } catch (e) {
      print("Error exporting records: $e");
      rethrow;
    }
  }
}

/// Service for patient-caregiver relationships
class RelationshipService {
  final ApiClient _apiClient = apiClient;

  /// Generate a link code for patient
  Future<String> generateLinkCode() async {
    try {
      final response = await _apiClient.generateLinkCode();
      return response['code'] as String? ?? '';
    } catch (e) {
      print("Error generating link code: $e");
      rethrow;
    }
  }

  /// Add a patient using link code (caregiver action)
  Future<Map<String, dynamic>> addPatient({
    required String code,
    String? disease,
  }) async {
    try {
      final response = await _apiClient.addPatient(
        code: code,
        disease: disease,
      );
      return response;
    } catch (e) {
      print("Error adding patient: $e");
      rethrow;
    }
  }

  /// Get list of patients (for caregivers)
  Future<List<dynamic>> getPatients() async {
    try {
      final response = await _apiClient.getPatients();
      return response['patients'] as List<dynamic>? ?? [];
    } catch (e) {
      print("Error getting patients: $e");
      rethrow;
    }
  }

  /// Get list of caregivers (for patients)
  Future<List<dynamic>> getCaregivers() async {
    try {
      final response = await _apiClient.getCaregivers();
      return response['caregivers'] as List<dynamic>? ?? [];
    } catch (e) {
      print("Error getting caregivers: $e");
      rethrow;
    }
  }
}

/// Service for notifications
class NotificationService {
  final ApiClient _apiClient = apiClient;

  /// Get notification history
  Future<List<dynamic>> getNotificationHistory({int limit = 50}) async {
    try {
      final response = await _apiClient.getNotificationHistory(limit: limit);
      return response['notifications'] as List<dynamic>? ?? [];
    } catch (e) {
      print("Error getting notification history: $e");
      rethrow;
    }
  }
}

/// Service for hotspot location data
class HotspotService {
  final ApiClient _apiClient = apiClient;

  /// Submit hotspot data
  Future<Map<String, dynamic>> submitHotspot({
    required String subject,
    required String hometown,
    required String workplace,
    String? places,
    String? disease,
    Map<String, double>? coordinates,
  }) async {
    try {
      final response = await _apiClient.submitHotspot(
        subject: subject,
        hometown: hometown,
        workplace: workplace,
        places: places,
        disease: disease,
        coordinates: coordinates,
      );
      return response;
    } catch (e) {
      print("Error submitting hotspot: $e");
      rethrow;
    }
  }

  /// Get hotspots for a patient
  Future<List<dynamic>> getPatientHotspots({required String patientId}) async {
    try {
      final response = await _apiClient.getPatientHotspots(
        patientId: patientId,
      );
      return response['hotspots'] as List<dynamic>? ?? [];
    } catch (e) {
      print("Error getting patient hotspots: $e");
      rethrow;
    }
  }

  /// Get heatmap data
  Future<Map<String, dynamic>> getHeatmapData({String? disease}) async {
    try {
      final response = await _apiClient.getHeatmapData(disease: disease);
      return response;
    } catch (e) {
      print("Error getting heatmap data: $e");
      rethrow;
    }
  }
}

/// Singleton instances
final recordService = RecordService();
final relationshipService = RelationshipService();
final notificationService = NotificationService();
final hotspotService = HotspotService();

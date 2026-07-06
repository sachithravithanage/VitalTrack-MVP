import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Service for medical records operations
class RecordService {
  final ApiClient _apiClient = apiClient;

  /// Create a new medical record
  Future<Map<String, dynamic>> createRecord({
    String? patientId,
    required String disease,
    String? temperature,
    String? fluidIntake,
    String? urineOutput,
    String? urineColor,
    Map<String, String>? values,
    Map<String, bool>? symptoms,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.createRecord(
        patientId: patientId,
        disease: disease,
        temperature: temperature,
        fluidIntake: fluidIntake,
        urineOutput: urineOutput,
        urineColor: urineColor,
        values: values,
        symptoms: symptoms,
        notes: notes,
      );
      return response;
    } catch (e) {
      debugPrint("Error creating record: $e");
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
      debugPrint("Error listing records: $e");
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
      debugPrint("Error getting record stats: $e");
      rethrow;
    }
  }

  /// Export records as PDF
  Future<Map<String, dynamic>> exportRecordsPdf({
    String? timelineFilter,
    String? patientId,
    String? stepUpToken,
  }) async {
    try {
      final response = await _apiClient.exportRecordsPdf(
        timelineFilter: timelineFilter,
        patientId: patientId,
        stepUpToken: stepUpToken,
      );
      return response;
    } catch (e) {
      debugPrint("Error exporting records: $e");
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
      debugPrint("Error generating link code: $e");
      rethrow;
    }
  }

  /// Generate a link code for patient with step-up token
  Future<String> generateLinkCodeSecured({required String stepUpToken}) async {
    try {
      final response = await _apiClient.generateLinkCodeSecured(
        stepUpToken: stepUpToken,
      );
      return response['code'] as String? ?? '';
    } catch (e) {
      debugPrint("Error generating secured link code: $e");
      rethrow;
    }
  }

  /// Add a patient using link code (caregiver action)
  Future<Map<String, dynamic>> addPatient({
    required String code,
    String? disease,
    String? stepUpToken,
  }) async {
    try {
      final response = await _apiClient.addPatient(
        code: code,
        disease: disease,
        stepUpToken: stepUpToken,
      );
      return response;
    } catch (e) {
      debugPrint("Error adding patient: $e");
      rethrow;
    }
  }

  /// Create and link a new managed patient
  Future<Map<String, dynamic>> createPatient({
    required String name,
    required String disease,
    String? stepUpToken,
  }) async {
    try {
      final response = await _apiClient.createPatient(
        name: name,
        disease: disease,
        stepUpToken: stepUpToken,
      );
      return response;
    } catch (e) {
      debugPrint("Error creating patient: $e");
      rethrow;
    }
  }

  /// Get list of patients (for caregivers)
  Future<List<dynamic>> getPatients() async {
    try {
      final response = await _apiClient.getPatients();
      return response['patients'] as List<dynamic>? ?? [];
    } catch (e) {
      debugPrint("Error getting patients: $e");
      rethrow;
    }
  }

  /// Get list of caregivers (for patients)
  Future<List<dynamic>> getCaregivers() async {
    try {
      final response = await _apiClient.getCaregivers();
      return response['caregivers'] as List<dynamic>? ?? [];
    } catch (e) {
      debugPrint("Error getting caregivers: $e");
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
      debugPrint("Error getting notification history: $e");
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead({required String notificationId}) async {
    try {
      await _apiClient.markNotificationAsRead(notificationId: notificationId);
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
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
    String? subjectPatientId,
    required String hometown,
    required String workplace,
    String? places,
    String? disease,
    Map<String, double>? coordinates,
  }) async {
    try {
      final response = await _apiClient.submitHotspot(
        subject: subject,
        subjectPatientId: subjectPatientId,
        hometown: hometown,
        workplace: workplace,
        places: places,
        disease: disease,
        coordinates: coordinates,
      );
      return response;
    } catch (e) {
      debugPrint("Error submitting hotspot: $e");
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
      debugPrint("Error getting patient hotspots: $e");
      rethrow;
    }
  }

  /// Get heatmap data
  Future<Map<String, dynamic>> getHeatmapData({String? disease}) async {
    try {
      final response = await _apiClient.getHeatmapData(disease: disease);
      return response;
    } catch (e) {
      debugPrint("Error getting heatmap data: $e");
      rethrow;
    }
  }

  /// Get district-level regional heatmap summary
  Future<Map<String, dynamic>> getRegionalHeatmapData({String? disease}) async {
    try {
      final response = await _apiClient.getRegionalHeatmapData(
        disease: disease,
      );
      return response;
    } catch (e) {
      debugPrint("Error getting regional heatmap data: $e");
      rethrow;
    }
  }
}

/// Singleton instances
final recordService = RecordService();
final relationshipService = RelationshipService();
final notificationService = NotificationService();
final hotspotService = HotspotService();

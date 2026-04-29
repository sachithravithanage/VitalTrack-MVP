import 'package:cloud_firestore/cloud_firestore.dart';

class HealthLog {
  HealthLog({
    required this.id,
    required this.type,
    this.value1,
    this.value2,
    this.symptoms,
    required this.status,
    this.notes = '',
    this.hasVoiceNote = false,
    required this.timestamp,
  });

  factory HealthLog.fromFirestore(Map<String, dynamic> data, String id) {
    return HealthLog(
      id: id,
      type: data['type'] ?? '',
      // Safely parse numbers from Firestore (handles ints saved as doubles)
      value1:
          data['value1'] != null ? (data['value1'] as num).toDouble() : null,
      value2:
          data['value2'] != null ? (data['value2'] as num).toDouble() : null,
      symptoms:
          data['symptoms'] != null ? List<String>.from(data['symptoms']) : null,
      status: data['status'] ?? 'LOGGED',
      notes: data['notes'] ?? '',
      hasVoiceNote: data['hasVoiceNote'] ?? false,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
  final String id;
  final String type; // e.g., 'Temperature', 'Blood Pressure', 'Symptoms'
  final double? value1; // Temp, Systolic, Fluid, Urine, Platelets
  final double? value2; // Diastolic
  final List<String>? symptoms; // List of active symptoms
  final String status; // e.g., 'HIGH FEVER', 'NORMAL', 'Elevated'
  final String notes;
  final bool hasVoiceNote;
  final DateTime timestamp;

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      if (value1 != null) 'value1': value1,
      if (value2 != null) 'value2': value2,
      if (symptoms != null) 'symptoms': symptoms,
      'status': status,
      'notes': notes,
      'hasVoiceNote': hasVoiceNote,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

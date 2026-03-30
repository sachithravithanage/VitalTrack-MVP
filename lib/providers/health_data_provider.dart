import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_log.dart';
import 'patient_provider.dart';

class HealthDataProvider extends ChangeNotifier {
  final PatientProvider patientProvider;
  StreamSubscription? _logsSubscription;

  // We store the raw logs here. The UI will decide how to paint them.
  List<HealthLog> allLogs = [];

  HealthDataProvider({required this.patientProvider}) {
    // Whenever the PatientProvider changes (e.g., Caretaker clicks a new patient),
    // we reload the health logs for that specific patient's active episode.
    patientProvider.addListener(_onPatientStateChanged);
    _onPatientStateChanged();
  }

  @override
  void dispose() {
    patientProvider.removeListener(_onPatientStateChanged);
    _logsSubscription?.cancel();
    super.dispose();
  }

  void _onPatientStateChanged() {
    final patient = patientProvider.activePatient;
    final episode = patientProvider.activeEpisode;

    _logsSubscription?.cancel();
    allLogs.clear();

    if (patient == null || episode == null) {
      notifyListeners();
      return;
    }

    // Subscribe ONLY to the current active episode for this specific patient
    _logsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(patient.uid)
        .collection('episodes')
        .doc(episode.id)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      allLogs = snapshot.docs
          .map((doc) => HealthLog.fromFirestore(doc.data(), doc.id))
          .toList();

      notifyListeners();
    });
  }

  // Helper method for the UI to get logs filtered by type (e.g., 'Temperature')
  List<HealthLog> getLogsByType(String type) {
    return allLogs.where((log) => log.type == type).toList();
  }

  // Helper to get the absolute latest log for a specific type (for Dashboard cards)
  HealthLog? getLatestLog(String type) {
    final filtered = getLogsByType(type);
    if (filtered.isNotEmpty) return filtered.first;
    return null;
  }

  // Helper to get exactly 7 days of data for the Charts
  List<double> getChartData(String type, {bool isSecondary = false}) {
    final filtered = getLogsByType(type).take(7).toList();
    // We reverse it so the oldest is on the left of the chart, newest on the right
    return filtered.reversed.map((log) {
      if (isSecondary && log.value2 != null) return log.value2!;
      return log.value1 ?? 0.0;
    }).toList();
  }

  // THE MASTER SAVE METHOD
  Future<void> addEntry(
    String type, {
    double? value1,
    double? value2,
    List<String>? symptoms,
    String status = 'LOGGED',
    String notes = '',
    bool hasVoiceNote = false,
  }) async {
    final patient = patientProvider.activePatient;
    final episode = patientProvider.activeEpisode;

    if (patient == null || episode == null) {
      debugPrint("Cannot save: No active patient or episode.");
      return;
    }

    // Format numbers to prevent 37.23456789 decimal bloat (Requirement 3)
    double? cleanVal1 =
        value1 != null ? double.parse(value1.toStringAsFixed(1)) : null;
    double? cleanVal2 =
        value2 != null ? double.parse(value2.toStringAsFixed(1)) : null;

    final newLog = HealthLog(
      id: '', // Firestore will auto-generate
      type: type,
      value1: cleanVal1,
      value2: cleanVal2,
      symptoms: symptoms,
      status: status,
      notes: notes,
      hasVoiceNote: hasVoiceNote,
      timestamp: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patient.uid)
          .collection('episodes')
          .doc(episode.id)
          .collection('logs')
          .add(newLog.toFirestore());
    } catch (e) {
      debugPrint("Failed to save log: $e");
    }
  }
}

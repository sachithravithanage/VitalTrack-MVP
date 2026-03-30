import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum InputType { singleSlider, doubleSlider, checklist }

enum ChartType { curve, bar }

class LeptoMetricConfig {
  LeptoMetricConfig({
    required this.title,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.statusSub,
    required this.icon,
    required this.baseColor,
    required this.iconBgColor,
    required this.gradient,
    this.inputType = InputType.singleSlider,
    this.chartType = ChartType.curve,
    this.sliderMin1 = 0,
    this.sliderMax1 = 100,
    this.sliderMin2,
    this.sliderMax2,
    this.labelMin = '',
    this.labelMid = '',
    this.labelMax = '',
    this.checklistItems,
    required this.history,
    required this.chartData,
  });
  final String title;
  String currentValue;
  final String unit;
  String status;
  final String statusSub;
  final IconData icon;
  final Color baseColor;
  final Color iconBgColor;
  final List<Color> gradient;
  final InputType inputType;
  final ChartType chartType;
  final double sliderMin1;
  final double sliderMax1;
  final double? sliderMin2;
  final double? sliderMax2;
  final String labelMin;
  final String labelMid;
  final String labelMax;
  final List<Map<String, dynamic>>? checklistItems;
  List<Map<String, String>> history;
  List<double> chartData;
  List<double> secondaryChartData = []; // For Diastolic BP
}

class LeptoHealthDataProvider extends ChangeNotifier {
  String? _targetUid;
  StreamSubscription? _logSubscription;

  final Map<String, LeptoMetricConfig> metricsData = {
    'Blood Pressure': LeptoMetricConfig(
      title: 'Last Blood Pressure', currentValue: '--/--', unit: 'mmHg',
      status: 'WAITING', statusSub: '',
      icon: Icons.favorite_border, baseColor: const Color(0xFFEC5B13),
      iconBgColor: const Color(0xFFFEF2F2),
      gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
      inputType: InputType.doubleSlider,
      chartType: ChartType.curve, // Switched to Curve for BP
      sliderMin1: 80, sliderMax1: 200, sliderMin2: 40, sliderMax2: 130,
      chartData: [], history: [],
    ),
    'Symptoms': LeptoMetricConfig(
      title: 'Today\'s Symptoms',
      currentValue: '0/5',
      unit: 'Logged',
      status: 'WAITING',
      statusSub: '',
      icon: Icons.medical_services_outlined,
      baseColor: const Color(0xFF3B82F6),
      iconBgColor: const Color(0xFFFFF1F2),
      gradient: const [Color(0xFF14B8A6), Color(0xFF1D4ED8)],
      inputType: InputType.checklist,
      chartType: ChartType.bar,
      checklistItems: [
        {'name': 'Yellow Eyes', 'icon': Icons.visibility_outlined},
        {'name': 'Muscle Pain', 'icon': Icons.accessibility_new},
        {'name': 'Vomiting', 'icon': Icons.sick_outlined},
        {'name': 'Headache', 'icon': Icons.psychology_outlined},
        {'name': 'Joint Pain', 'icon': Icons.sports_gymnastics},
      ],
      chartData: [],
      history: [],
    ),
    // ... [Add your original Urine Output and Temperature configs here with empty history/chartData]
  };

  void setTargetUser(String uid) {
    if (_targetUid == uid) return;
    _targetUid = uid;
    _listenToHealthLogs();
  }

  void _listenToHealthLogs() {
    _logSubscription?.cancel();
    if (_targetUid == null) return;

    _logSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_targetUid)
        .collection('lepto_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var metric in metricsData.values) {
        metric.history.clear();
        metric.chartData.clear();
        metric.secondaryChartData.clear();
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tabName = data['type'] as String?;
        if (tabName == null || !metricsData.containsKey(tabName)) continue;

        final metric = metricsData[tabName]!;
        final time =
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final timeStr = DateFormat('MMM dd, hh:mm a').format(time);

        if (metric.inputType == InputType.singleSlider) {
          final v = (data['value'] as num).toDouble();
          metric.history.add({
            'val': '${v.toStringAsFixed(1)} ${metric.unit}',
            'time': timeStr
          });
          metric.chartData.insert(0, v);
        } else if (metric.inputType == InputType.doubleSlider) {
          final sys = (data['sys'] as num).toDouble();
          final dia = (data['dia'] as num).toDouble();
          metric.history.add({
            'val': '${sys.toInt()}/${dia.toInt()} ${metric.unit}',
            'time': timeStr,
            'status': data['status']
          });
          metric.chartData.insert(0, sys);
          metric.secondaryChartData.insert(0, dia);
        } else if (metric.inputType == InputType.checklist) {
          final count = (data['count'] as num).toInt();
          metric.history
              .add({'val': '$count Symptoms Logged', 'time': timeStr});
          metric.chartData.insert(0, count.toDouble());
        }
      }

      // Format Current Value from latest data
      for (var metric in metricsData.values) {
        if (metric.chartData.isNotEmpty) {
          if (metric.inputType == InputType.doubleSlider) {
            metric.currentValue =
                '${metric.chartData.last.toInt()}/${metric.secondaryChartData.last.toInt()}';
          } else if (metric.inputType == InputType.checklist) {
            metric.currentValue = '${metric.chartData.last.toInt()}/5';
          } else {
            metric.currentValue = metric.chartData.last.toStringAsFixed(1);
          }
        }
      }
      notifyListeners();
    });
  }

  Future<void> addEntry(String tabName, dynamic val1,
      [dynamic val2, String notes = '']) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final metric = metricsData[tabName]!;
    Map<String, dynamic> payload = {
      'type': tabName,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (metric.inputType == InputType.singleSlider) {
      payload['value'] = val1;
    } else if (metric.inputType == InputType.doubleSlider) {
      payload['sys'] = val1;
      payload['dia'] = val2;
      payload['status'] = (val1 > 120) ? 'Elevated' : 'Normal';
    } else if (metric.inputType == InputType.checklist) {
      payload['symptoms'] = val1; // Array of string names
      payload['count'] = (val1 as List).length;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lepto_logs')
        .add(payload);
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }
}

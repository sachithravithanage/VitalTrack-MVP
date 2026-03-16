import 'package:flutter/material.dart';

enum InputType { singleSlider, doubleSlider, checklist }
enum ChartType { curve, bar }

class LeptoMetricConfig {
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
  List<double> chartData; // Stores live data for the charts

  LeptoMetricConfig({
    required this.title, required this.currentValue, required this.unit,
    required this.status, required this.statusSub, required this.icon,
    required this.baseColor, required this.iconBgColor, required this.gradient,
    this.inputType = InputType.singleSlider, this.chartType = ChartType.curve,
    this.sliderMin1 = 0, this.sliderMax1 = 100, this.sliderMin2, this.sliderMax2,
    this.labelMin = '', this.labelMid = '', this.labelMax = '',
    this.checklistItems, required this.history, required this.chartData,
  });
}

class LeptoHealthDataProvider extends ChangeNotifier {
  final Map<String, LeptoMetricConfig> metricsData = {
    'Blood Pressure': LeptoMetricConfig(
      title: 'Last Blood Pressure', currentValue: '120/80', unit: 'mmHg',
      status: 'NORMAL', statusSub: '',
      icon: Icons.favorite_border, baseColor: const Color(0xFFEC5B13), iconBgColor: const Color(0xFFFEF2F2),
      gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
      inputType: InputType.doubleSlider, chartType: ChartType.bar,
      sliderMin1: 80, sliderMax1: 200, sliderMin2: 40, sliderMax2: 130,
      chartData: [115, 125, 118, 122, 119, 121, 120], // Tracks Systolic for the bar chart
      history: [
        {'val': '120/80 mmHg', 'time': 'Today, 08:30 AM', 'status': 'Normal', 'statusColor': 'green'},
        {'val': '125/84 mmHg', 'time': 'Yesterday, 09:15 PM', 'status': 'Elevated', 'statusColor': 'orange'},
      ],
    ),
    'Symptoms': LeptoMetricConfig(
      title: 'Today\'s Symptoms', currentValue: '3/5', unit: 'Logged',
      status: 'STABLE', statusSub: '',
      icon: Icons.medical_services_outlined, baseColor: const Color(0xFF3B82F6), iconBgColor: const Color(0xFFFFF1F2),
      gradient: const [Color(0xFF14B8A6), Color(0xFF1D4ED8)],
      inputType: InputType.checklist, chartType: ChartType.bar,
      checklistItems: [
        {'name': 'Yellow Eyes', 'icon': Icons.visibility_outlined},
        {'name': 'Muscle Pain', 'icon': Icons.accessibility_new},
        {'name': 'Vomiting', 'icon': Icons.sick_outlined},
        {'name': 'Headache', 'icon': Icons.psychology_outlined},
        {'name': 'Joint Pain', 'icon': Icons.sports_gymnastics},
      ],
      chartData: [1, 2, 4, 3, 2, 1, 3], // Tracks total count of symptoms checked
      history: [
        {'val': '3 Symptoms Logged', 'time': 'Yesterday, 8:45 PM'},
        {'val': '1 Symptom Logged', 'time': 'Oct 24, 9:15 AM'},
      ],
    ),
    'Urine Output': LeptoMetricConfig(
      title: 'Daily Urine Output', currentValue: '1.2', unit: 'L',
      status: 'NORMAL', statusSub: 'Goal: 1.5 L',
      icon: Icons.science_outlined, baseColor: const Color(0xFFEAB308), iconBgColor: const Color(0xFFFEFCE8),
      gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
      inputType: InputType.singleSlider, chartType: ChartType.curve,
      sliderMin1: 0, sliderMax1: 1500, labelMin: '0 ml', labelMid: '750 ml', labelMax: '1500 ml',
      chartData: [400, 350, 500, 450, 600, 800, 1200],
      history: [
        {'val': '1200 ml', 'time': 'Today, 11:15 AM'},
      ],
    ),
    'Temperature': LeptoMetricConfig(
      title: 'Latest Temperature', currentValue: '98.6', unit: '°F',
      status: 'NORMAL', statusSub: 'Status: Normal',
      icon: Icons.thermostat, baseColor: const Color(0xFFF97316), iconBgColor: const Color(0xFFFFF7ED),
      gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
      inputType: InputType.singleSlider, chartType: ChartType.curve,
      sliderMin1: 95, sliderMax1: 105, labelMin: '95°F', labelMid: '100°F', labelMax: '105°F',
      chartData: [101.5, 100.2, 99.5, 99.8, 99.0, 98.4, 98.6],
      history: [
        {'val': '98.6°F', 'time': 'Today, 10:30 AM'},
      ],
    ),
  };

  void addEntry(String tabName, dynamic val1, [dynamic val2]) {
    final metric = metricsData[tabName]!;
    final now = DateTime.now();
    String timeStr = 'Today, ${now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    if (metric.inputType == InputType.singleSlider) {
      double v = val1 as double;
      metric.currentValue = v >= 100 ? v.toInt().toString() : v.toStringAsFixed(1);
      metric.history.insert(0, {'val': '${metric.currentValue} ${metric.unit}', 'time': timeStr});
      metric.chartData.add(v);
    } else if (metric.inputType == InputType.doubleSlider) {
      int sys = (val1 as double).toInt();
      int dia = (val2 as double).toInt();
      metric.currentValue = '$sys/$dia';
      metric.history.insert(0, {
        'val': '$sys/$dia ${metric.unit}', 'time': timeStr,
        'status': sys > 120 ? 'Elevated' : 'Normal', 'statusColor': sys > 120 ? 'orange' : 'green'
      });
      metric.chartData.add(sys.toDouble());
    } else if (metric.inputType == InputType.checklist) {
      int count = (val1 as List<String>).length;
      metric.currentValue = '$count/5';
      metric.history.insert(0, {'val': '$count Symptoms Logged', 'time': timeStr});
      metric.chartData.add(count.toDouble());
    }

    if (metric.chartData.length > 7) metric.chartData.removeAt(0);
    notifyListeners();
  }
}
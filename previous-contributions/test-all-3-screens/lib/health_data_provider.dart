import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MetricConfig {
  final String title;
  String currentValue;
  final String unit;
  String status;
  final String statusSub;
  final IconData icon;
  final Color baseColor;
  final List<Color> gradient;
  final double sliderMin;
  final double sliderMax;
  final String labelMin;
  final String labelMid;
  final String labelMax;
  List<Map<String, String>> history;
  List<double> chartData; // NEW: Stores the actual numbers for the chart

  MetricConfig({
    required this.title, required this.currentValue, required this.unit,
    required this.status, required this.statusSub, required this.icon,
    required this.baseColor, required this.gradient,
    required this.sliderMin, required this.sliderMax,
    required this.labelMin, required this.labelMid, required this.labelMax,
    required this.history, required this.chartData,
  });
}

class HealthDataProvider extends ChangeNotifier {
  final Map<String, MetricConfig> metricsData = {
    'Platelets': MetricConfig(
      title: 'Current Platelet Count', currentValue: '145,000', unit: '/µL',
      status: 'STABLE', statusSub: 'Ref: 150k - 450k',
      icon: Icons.bloodtype, baseColor: const Color(0xFFEF4444),
      gradient: const [Color(0xFFFCA5A5), Color(0xFFDC2626)],
      sliderMin: 0, sliderMax: 500000,
      labelMin: '0', labelMid: '250k', labelMax: '500k',
      // Initial dummy data for the chart line
      chartData: [130000, 135000, 132000, 140000, 138000, 142000, 145000],
      history: [
        {'val': '145,000 /µL', 'time': 'Today, 10:30 AM'},
        {'val': '142,000 /µL', 'time': 'Today, 08:00 AM'},
        {'val': '138,000 /µL', 'time': 'Yesterday, 09:15 PM'},
      ],
    ),
    'Fluid Intake': MetricConfig(
      title: 'Daily Fluid Intake', currentValue: '1.8', unit: 'L',
      status: 'ON TRACK', statusSub: 'Goal: 2.5 L',
      icon: Icons.water_drop, baseColor: const Color(0xFF14B8A6),
      gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
      sliderMin: 0, sliderMax: 5,
      labelMin: '0 L', labelMid: '2.5 L', labelMax: '5 L',
      chartData: [1.2, 1.5, 1.3, 1.8, 2.0, 1.7, 1.8],
      history: [
        {'val': '0.5 L', 'time': 'Today, 10:30 AM'},
        {'val': '0.3 L', 'time': 'Today, 08:00 AM'},
        {'val': '0.2 L', 'time': 'Yesterday, 09:15 PM'},
      ],
    ),
    'Urine Output': MetricConfig(
      title: 'Daily Urine Output', currentValue: '1.2', unit: 'L',
      status: 'NORMAL', statusSub: 'Goal: 1.5 L',
      icon: Icons.science, baseColor: const Color(0xFFEAB308),
      gradient: const [Color(0xFFFACC15), Color(0xFFCA8A04)],
      sliderMin: 0, sliderMax: 1000,
      labelMin: '0 ml', labelMid: '500 ml', labelMax: '1000 ml',
      chartData: [300, 400, 350, 500, 450, 400, 400],
      history: [
        {'val': '400 ml', 'time': 'Today, 11:15 AM'},
        {'val': '350 ml', 'time': 'Today, 07:45 AM'},
        {'val': '450 ml', 'time': 'Yesterday, 10:30 PM'},
      ],
    ),
    'Temperature': MetricConfig(
      title: 'Latest Temperature', currentValue: '98.6', unit: '°F',
      status: 'NORMAL', statusSub: 'Status: Normal',
      icon: Icons.thermostat, baseColor: const Color(0xFFF97316),
      gradient: const [Color(0xFFFB923C), Color(0xFFEA580C)],
      sliderMin: 95, sliderMax: 105,
      labelMin: '95°F', labelMid: '100°F', labelMax: '105°F',
      chartData: [101.5, 100.2, 99.5, 99.8, 99.0, 98.4, 98.6],
      history: [
        {'val': '98.6 °F', 'time': 'Today, 10:30 AM'},
        {'val': '99.1 °F', 'time': 'Today, 08:00 AM'},
        {'val': '98.4 °F', 'time': 'Yesterday, 09:15 PM'},
      ],
    ),
  };

  void addEntry(String tabName, double value) {
    final metric = metricsData[tabName]!;

    // 1. Update Current Text Value
    String formattedValue;
    if (tabName == 'Platelets') {
      formattedValue = value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } else if (tabName == 'Temperature' || tabName == 'Fluid Intake') {
      formattedValue = value.toStringAsFixed(1);
    } else {
      formattedValue = value.toInt().toString();
    }
    metric.currentValue = formattedValue;

    // 2. Add to text history
    final now = DateTime.now();
    String timeString = 'Today, ${DateFormat('hh:mm a').format(now)}';
    metric.history.insert(0, {
      'val': '$formattedValue ${metric.unit}',
      'time': timeString,
    });

    // 3. UPDATE THE CHART DATA!
    // Add the new value to the end of the line, and remove the oldest day
    metric.chartData.add(value);
    if (metric.chartData.length > 7) {
      metric.chartData.removeAt(0);
    }

    notifyListeners();
  }
}
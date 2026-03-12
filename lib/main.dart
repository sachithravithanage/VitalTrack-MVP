import 'package:flutter/material.dart';
import 'screens/heatmap.dart';

void main() => runApp(const VitalTrackApp());

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEC5B13),
          primary: const Color(0xFFEC5B13),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
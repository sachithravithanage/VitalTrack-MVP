import 'package:flutter/material.dart';
import 'dengu.dart';

void main() {
  runApp(const VitalTrackApp());
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitalTrack Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF2D9C8D),
        fontFamily: 'Roboto', // Replace with 'Nunito' if added to pubspec.yaml
      ),
      home: const DashboardScreen(),
    );
  }
}

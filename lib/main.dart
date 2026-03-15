import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart'; // Changed import

void main() {
  runApp(const VitalTrackApp());
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF20B5A0),
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(), // Apply font globally
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20B5A0),
        ),
      ),
      home: const SplashScreen(), // Changed home to SplashScreen
    );
  }
}

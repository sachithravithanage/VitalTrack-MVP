import 'package:flutter/material.dart';
import 'screens/language_selection_screen.dart';

void main() {
  runApp(const VitalTrackApp());
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF20B5A0),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20B5A0),
        ),
      ),
      home: const LanguageSelectionScreen(),
    );
  }
}

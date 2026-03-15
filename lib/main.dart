import 'package:flutter/material.dart';
import 'screens/heatmap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {

  // This line is required before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // This wakes up the backend connection
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VitalTrackApp());
}

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
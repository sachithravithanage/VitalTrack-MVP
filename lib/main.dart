import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Providers
import 'providers/health_data_provider.dart';
import 'providers/patient_provider.dart';

// Screens
import 'screens/splash_screen.dart';

void main() async {
  // 1. Required to initialize Firebase before the app starts
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wake up Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // 3. Run the app wrapped in Praveen's Providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProxyProvider<PatientProvider, HealthDataProvider>(
          create: (context) => HealthDataProvider(
            patientProvider:
                Provider.of<PatientProvider>(context, listen: false),
          ),
          update: (context, patientProvider, previous) =>
              HealthDataProvider(patientProvider: patientProvider),
        ),
      ],
      child: const VitalTrackApp(),
    ),
  );
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(), // Thushan's Font Choice
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20B5A0), // Thushan's Primary Teal
          primary: const Color(0xFF20B5A0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F7FF),
      ),
      // 4. Start the app at the Splash Screen
      home: const SplashScreen(),
    );
  }
}

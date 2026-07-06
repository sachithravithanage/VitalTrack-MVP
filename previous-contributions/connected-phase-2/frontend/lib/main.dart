import 'package:flutter/material.dart';
import 'services/index.dart';
import 'app/vitaltrack_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await initializeFirebase();

  // Initialize storage service
  await storageService.init();

  runApp(const VitalTrackApp());
}

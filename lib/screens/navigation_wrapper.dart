import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/patient_provider.dart';
import 'dengue_dashboard_screen.dart';
import 'leptospirosis_dashboard_screen.dart';
import 'dashboard_no_data_screen.dart';
import 'patient_connections_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final patientProvider = context.watch<PatientProvider>();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'Patient';
        String? illness = userData['currentIllness'];

        // Logic for "Home"
        Widget homeScreen;
        if (role == 'Caretaker' && patientProvider.activePatient == null) {
          homeScreen = const PatientConnectionsScreen();
        } else {
          final activeEpisode = patientProvider.activeEpisode;
          final activeIllness = activeEpisode?.diseaseName ?? illness;

          if (activeIllness == 'Dengue') {
            homeScreen = const DengueDashboardScreen();
          } else if (activeIllness == 'Leptospirosis') {
            homeScreen = const LeptospirosisDashboardScreen();
          } else {
            homeScreen = const DashboardNoDataScreen();
          }
        }

        return homeScreen;
      },
    );
  }
}

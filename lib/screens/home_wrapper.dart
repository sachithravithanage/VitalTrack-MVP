import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/patient_provider.dart';
import 'dashboard_no_data_screen.dart';
import 'dengue_dashboard_screen.dart';
import 'leptospirosis_dashboard_screen.dart';
import 'patient_connections_screen.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    // 1. Show loading while fetching auth state
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F6F6),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF20B5A0))),
      );
    }

    // 2. Route the active patient context based on episode state
    final episode = provider.activeEpisode;

    if (episode == null || !episode.isActive) {
      return const DashboardNoDataScreen();
    }

    if (episode.diseaseName == 'Dengue') {
      return const DengueDashboardScreen();
    } else {
      return const LeptospirosisDashboardScreen();
    }
  }
}

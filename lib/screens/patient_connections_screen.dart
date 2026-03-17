import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dengue_patient_history_screen.dart';
import 'leptospirosis_patient_history_screen.dart';

class PatientConnectionsScreen extends StatelessWidget {
  const PatientConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Connections',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // PATIENT 1: MATCHING THE DASHBOARD
          _buildPatientCard(
            context,
            'Amila Perera',
            'DENGUE',
            '2 hours ago',
            const Color(0xFF147B85), // Teal
            'dengue', // Route identifier
          ),
          const SizedBox(height: 16),

          // PATIENT 2: MATCHING THE DASHBOARD
          _buildPatientCard(
            context,
            'Saman Kumara',
            'LEPTOSPIROSIS',
            '1 hour ago',
            Colors.orange, // Orange
            'lepto', // Route identifier
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, String name, String diagnosis,
      String lastSync, Color diagnosisColor, String routeId) {
    return GestureDetector(
      onTap: () {
        if (routeId == 'dengue') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DenguePatientHistoryScreen(
                patientName: name, // Passes the name into the screen
              ),
            ),
          );
        } else if (routeId == 'lepto') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LeptospirosisPatientHistoryScreen(patientName: name),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: diagnosisColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: diagnosisColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B))),
                  Text(diagnosis,
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: diagnosisColor,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('Last sync: $lastSync',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

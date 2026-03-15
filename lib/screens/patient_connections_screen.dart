import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// We will build these two files in the next step!
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
          _buildPatientCard(
            context,
            'Sarah Jenkins',
            'DENGUE',
            '2 hours ago',
            const Color(0xFF0EA5E9),
            'dengue', // Route identifier
          ),
          const SizedBox(height: 16),
          _buildPatientCard(
            context,
            'Michael Chen',
            'LEPTOSPIROSIS',
            '5 hours ago',
            const Color(0xFF0EA5E9),
            'lepto', // Route identifier
          ),
          const SizedBox(height: 16),
          _buildPatientCard(
            context,
            'Emma Thompson',
            'LEPTOSPIROSIS',
            '5 hours ago',
            const Color(0xFF0EA5E9),
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
            // Placeholder Avatar
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white),
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

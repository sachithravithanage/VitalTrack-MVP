import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../providers/patient_provider.dart'; // Added PatientProvider
import 'profile_screen.dart';
import 'heatmap.dart';
import 'dengue_patient_history_screen.dart';

class DengueDashboardScreen extends StatelessWidget {
  const DengueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthDataProvider>();
    final patientProvider =
        context.watch<PatientProvider>(); // Watch Patient State

    // Instantly get the active patient's name! No loading flicker!
    final activePatient = patientProvider.activePatient;
    final String lastName =
        activePatient?.fullName.trim().split(' ').last ?? '';

    // Fetch the latest logs
    final platelets = healthProvider.getLatestLog('Platelets');
    final fluid = healthProvider.getLatestLog('Fluid Intake');
    final temp = healthProvider.getLatestLog('Temperature');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good Morning,',
                          style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B))),
                      Text(lastName,
                          style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D9C8D))),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen())),
                    child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.person, color: Color(0xFF64748B))),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Dynamic Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2D9C8D), Color(0xFF1B7B85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF2D9C8D).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Status',
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('MONITORING',
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Dengue Fever',
                        style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor platelets closely today.',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                      child: _buildActionButton(
                          icon: Icons.add_circle,
                          label: 'Log Vitals',
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const DenguePatientHistoryScreen()));
                          })),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildActionButton(
                          icon: Icons.map,
                          label: 'Heatmap',
                          color: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEFF6FF),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HeatMapScreen()));
                          })),
                ],
              ),
              const SizedBox(height: 32),

              Text('Today\'s Summary',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              const SizedBox(height: 16),

              _buildSummaryRow(
                  'Platelets',
                  platelets != null ? '${platelets.value1?.toInt()} /µL' : '--',
                  platelets?.status ?? 'No Data',
                  0.5,
                  const Color(0xFFEF4444),
                  const Color(0xFFFEF2F2)),
              const SizedBox(height: 12),
              _buildSummaryRow(
                  'Fluid Intake',
                  fluid != null ? '${fluid.value1} L' : '--',
                  fluid?.status ?? 'No Data',
                  0.7,
                  const Color(0xFF10B981),
                  const Color(0xFFF0FDF4)),
              const SizedBox(height: 12),
              _buildSummaryRow(
                  'Temperature',
                  temp != null ? '${temp.value1}°F' : '--',
                  temp?.status ?? 'No Data',
                  0.9,
                  const Color(0xFFF59E0B),
                  const Color(0xFFFEF3C7)),
              const SizedBox(height: 100), // Padding for persistent nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required Color bgColor,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, String status,
      double progress, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.show_chart, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color)),
              ],
            ),
          ),
          Text(status,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

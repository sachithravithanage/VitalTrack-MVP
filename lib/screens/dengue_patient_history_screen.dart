import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../providers/patient_provider.dart';
import '../models/health_log.dart';
import 'temperature_history_screen.dart';
import 'platelets_history_screen.dart';
import 'fluid_intake_history_screen.dart';
import 'urine_output_history_screen.dart';

class DenguePatientHistoryScreen extends StatelessWidget {
  const DenguePatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch our providers for LIVE data
    final healthProvider = context.watch<HealthDataProvider>();
    final patientProvider = context.watch<PatientProvider>();

    // Securely get the active patient's correct details!
    final activePatient = patientProvider.activePatient;
    final patientName = activePatient?.fullName ?? 'Loading...';
    final patientId = activePatient?.uid.substring(0, 8).toUpperCase() ?? '...';

    final HealthLog? tempLog = healthProvider.getLatestLog('Temperature');
    final HealthLog? plateletsLog = healthProvider.getLatestLog('Platelets');
    final HealthLog? fluidLog = healthProvider.getLatestLog('Fluid Intake');
    final HealthLog? urineLog = healthProvider.getLatestLog('Urine Output');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B), size: 18),
            onPressed: () => Navigator.pop(context)),
        title: Text('Dengue Monitor',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                  child: const Icon(Icons.person,
                      color: Color(0xFF64748B), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName,
                          style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A))),
                      Text('Patient ID: $patientId',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Vital Signs',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMetricCard(
                  context: context,
                  title: 'Temperature',
                  value: tempLog != null ? '${tempLog.value1}°F' : '--°F',
                  statusText: tempLog?.status ?? 'No Data',
                  icon: Icons.thermostat,
                  iconColor: const Color(0xFFEA580C),
                  statusColor: (tempLog?.status == 'HIGH FEVER')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  targetScreen: const TemperatureHistoryScreen(),
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Platelets',
                  value: plateletsLog != null
                      ? '${plateletsLog.value1?.toInt()}'
                      : '--',
                  statusText: plateletsLog?.status ?? 'No Data',
                  icon: Icons.bloodtype,
                  iconColor: const Color(0xFFEF4444),
                  statusColor: (plateletsLog?.status == 'LOW / ALERT')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  targetScreen: const PlateletsHistoryScreen(),
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Fluid Intake',
                  value: fluidLog != null ? '${fluidLog.value1}L' : '--L',
                  statusText: fluidLog?.status ?? 'No Data',
                  icon: Icons.local_drink,
                  iconColor: const Color(0xFF06B6D4),
                  statusColor: (fluidLog?.status == 'LOW INTAKE')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  targetScreen: const FluidIntakeHistoryScreen(),
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Urine Output',
                  value: urineLog != null
                      ? '${urineLog.value1?.toInt()}ml'
                      : '--ml',
                  statusText: urineLog?.status ?? 'No Data',
                  icon: Icons.water_drop,
                  iconColor: const Color(0xFFEAB308),
                  statusColor: (urineLog?.status == 'LOW OUTPUT')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  targetScreen: const UrineOutputHistoryScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String statusText,
    required IconData icon,
    required Color iconColor,
    required Color statusColor,
    required Widget targetScreen,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => targetScreen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 20),
                Text(statusText,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }
}

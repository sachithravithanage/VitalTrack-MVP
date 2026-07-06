import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

import 'lepto_temperature_history_screen.dart';
import 'blood_pressure_history_screen.dart';
import 'lepto_urine_output_history_screen.dart';
import 'symptoms_history_screen.dart';

class LeptospirosisPatientHistoryScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const LeptospirosisPatientHistoryScreen({
    super.key,
    this.patientName = 'Saman Kumara',
    this.patientId = '4459102',
  });

  @override
  State<LeptospirosisPatientHistoryScreen> createState() =>
      _LeptospirosisPatientHistoryScreenState();
}

class _LeptospirosisPatientHistoryScreenState
    extends State<LeptospirosisPatientHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // NEW: Pulling from the separated Lepto lists!
    final latestTemp = globalLeptoTempHistory.isNotEmpty
        ? globalLeptoTempHistory.first
        : HealthRecord("--", "", "", false);
    final latestUrine = globalLeptoUrineHistory.isNotEmpty
        ? globalLeptoUrineHistory.first
        : HealthRecord("--", "", "", false);
    final latestBP = globalBPHistory.isNotEmpty
        ? globalBPHistory.first
        : HealthRecord("--/--", "", "", false);
    final latestSymptoms = globalSymptomsHistory.isNotEmpty
        ? globalSymptomsHistory.first
        : HealthRecord("0 Logged", "", "", false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF475569), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.person, color: Color(0xFFF59E0B)),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B)),
                ),
                Row(
                  children: [
                    Text('ID: ${widget.patientId}',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: const Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('ACTIVE',
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D9488))),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnosis Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFEDD5))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT CONDITION',
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEA580C),
                              letterSpacing: 1)),
                      Text('DIAGNOSIS: LEPTOSPIROSIS',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFC2410C))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    title: 'Temperature',
                    value: latestTemp.value,
                    statusText: latestTemp.status,
                    statusColor: latestTemp.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    icon: Icons.thermostat,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LeptoTemperatureHistoryScreen()))
                          .then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVitalCard(
                    title: 'Blood Pressure',
                    value: latestBP.value
                        .replaceAll(' mmHg', ''), // Clean up for the card view
                    statusText: latestBP.status,
                    statusColor: latestBP.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    icon: Icons.monitor_heart,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const BloodPressureHistoryScreen()))
                          .then((_) => setState(() {}));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    title: 'Urine Output',
                    value: latestUrine.value,
                    statusText: latestUrine.status,
                    statusColor: latestUrine.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    icon: Icons.science_outlined,
                    iconColor: const Color(0xFF14B8A6),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LeptoUrineOutputHistoryScreen()))
                          .then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVitalCard(
                    title: 'Symptoms',
                    value: latestSymptoms.value
                        .replaceAll(' Symptoms', '')
                        .replaceAll(' Symptom', ''), // Just show the number
                    statusText: latestSymptoms.status,
                    statusColor: latestSymptoms.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                    icon: Icons.sick,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SymptomsHistoryScreen()))
                          .then((_) => setState(() {}));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard({
    required String title,
    required String value,
    required String statusText,
    required Color statusColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

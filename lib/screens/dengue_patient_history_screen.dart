import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart'; // Import globals to read the latest data!

import 'temperature_history_screen.dart';
import 'platelets_history_screen.dart';
import 'fluid_intake_history_screen.dart';
import 'urine_output_history_screen.dart';

class DenguePatientHistoryScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const DenguePatientHistoryScreen({
    super.key,
    this.patientName = 'Amila Perera',
    this.patientId = '8839201',
  });

  @override
  State<DenguePatientHistoryScreen> createState() =>
      _DenguePatientHistoryScreenState();
}

class _DenguePatientHistoryScreenState
    extends State<DenguePatientHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the latest values from our global lists
    final latestTemp = globalTempHistory.isNotEmpty
        ? globalTempHistory.first
        : HealthRecord("--", "", "", false);
    final latestPlatelets = globalPlateletHistory.isNotEmpty
        ? globalPlateletHistory.first
        : HealthRecord("--", "", "", false);
    final latestFluid = globalFluidHistory.isNotEmpty
        ? globalFluidHistory.first
        : HealthRecord("--", "", "", false);
    final latestUrine = globalUrineHistory.isNotEmpty
        ? globalUrineHistory.first
        : HealthRecord("--", "", "", false);

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
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.person, color: Color(0xFF147B85)),
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEE2E2))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
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
                              color: const Color(0xFFEF4444),
                              letterSpacing: 1)),
                      Text('DIAGNOSIS: DENGUE',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFB91C1C))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vitals Grid (NOW DYNAMIC!)
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
                      // Navigate, then setState when we come back to refresh!
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const TemperatureHistoryScreen()))
                          .then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVitalCard(
                    title: 'Platelets',
                    value: latestPlatelets.value,
                    statusText: latestPlatelets.status,
                    statusColor: latestPlatelets.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    icon: Icons.bloodtype,
                    iconColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PlateletsHistoryScreen()))
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
                    title: 'Fluid Intake',
                    value: latestFluid.value,
                    statusText: latestFluid.status,
                    statusColor: latestFluid.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0EA5E9),
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const FluidIntakeHistoryScreen()))
                          .then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVitalCard(
                    title: 'Urine Output',
                    value: latestUrine.value,
                    statusText: latestUrine.status,
                    statusColor: latestUrine.isAlert
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    icon: Icons.science_outlined,
                    iconColor: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UrineOutputHistoryScreen()))
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

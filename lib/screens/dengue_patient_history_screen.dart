import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// We will build these history screens next! I will leave them commented out for now so your app doesn't crash.
import 'temperature_history_screen.dart';
import 'platelets_history_screen.dart';
import 'fluid_intake_history_screen.dart';
import 'urine_output_history_screen.dart';

class DenguePatientHistoryScreen extends StatelessWidget {
  final String patientName;
  final String patientId;

  const DenguePatientHistoryScreen({
    super.key,
    this.patientName = 'Sarah Jenkins',
    this.patientId = '8839201',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Off-white app background
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
            // Patient Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF94A3B8),
                  child: Icon(Icons.person,
                      color: Colors.white), // Placeholder for Sarah's photo
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Active green dot
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and ID
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B)),
                ),
                Row(
                  children: [
                    Text(
                      'ID: $patientId',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D9488)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red Diagnosis Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT CONDITION',
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                            letterSpacing: 1),
                      ),
                      Text(
                        'DIAGNOSIS: DENGUE',
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4-Block Vitals Grid
            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    context,
                    title: 'Temperature',
                    value: '98.6°F',
                    statusText: 'STABLE',
                    statusColor: const Color(0xFF10B981),
                    icon: Icons.thermostat,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const TemperatureHistoryScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVitalCard(
                    context,
                    title: 'Platelets',
                    value: '145K',
                    unit: '/µL',
                    statusText: 'STABLE',
                    statusColor: const Color(0xFF10B981),
                    icon: Icons.bloodtype,
                    iconColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PlateletsHistoryScreen()));
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
                    context,
                    title: 'Fluid Intake',
                    value: '1.8 L',
                    statusText: 'ON TRACK',
                    statusColor: const Color(0xFF0EA5E9),
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const FluidIntakeHistoryScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVitalCard(
                    context,
                    title: 'Urine Output',
                    value: '850 ml',
                    statusText: 'NORMAL',
                    statusColor: const Color(0xFF10B981),
                    icon: Icons.science_outlined, // Beaker alternative
                    iconColor: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const UrineOutputHistoryScreen()));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Patient Activity Log Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient Activity Log',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B)),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Text('Filter',
                      style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold)),
                  label: const Icon(Icons.filter_list,
                      color: Color(0xFF0EA5E9), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline List
            _buildTimelineItem(
              title: 'Temperature: 98.6°F',
              status: 'STABLE',
              statusColor: const Color(0xFF10B981),
              time: '10:30 AM',
              icon: Icons.thermostat,
              iconBgColor: const Color(0xFF0EA5E9),
              isFirst: true,
            ),
            _buildTimelineItem(
              title: 'Fluid Intake: 250ml Oral',
              status: 'NORMAL',
              statusColor: const Color(0xFF0EA5E9),
              time: '09:15 AM',
              icon: Icons.water_drop,
              iconBgColor: const Color(0xFF3B82F6),
            ),
            _buildTimelineItem(
              title: 'Platelets: 145,000 /µL',
              status: 'STABLE',
              statusColor: const Color(0xFF10B981),
              time: '08:00 AM',
              icon: Icons.bloodtype,
              iconBgColor: const Color(0xFFEF4444),
            ),
            _buildTimelineItem(
              title: 'Medication: Paracetamol',
              status: 'ADMINISTERED',
              statusColor: const Color(0xFF64748B),
              time: '06:00 AM',
              icon: Icons.medication,
              iconBgColor: const Color(0xFF94A3B8),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(
    BuildContext context, {
    required String title,
    required String value,
    String? unit,
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
                Text(
                  statusText,
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B)),
                ),
                if (unit != null)
                  Text(
                    unit,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String status,
    required Color statusColor,
    required String time,
    required IconData icon,
    required Color iconBgColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : const Color(0xFFE2E8F0),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isLast ? Colors.transparent : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
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
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              status,
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor),
                            ),
                            const SizedBox(width: 8),
                            Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFCBD5E1),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: GoogleFonts.nunito(
                                  fontSize: 12, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

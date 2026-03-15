import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SymptomsHistoryScreen extends StatelessWidget {
  const SymptomsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Symptoms History',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined,
                color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Symptoms Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                      Text('RECENT SYMPTOMS',
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('3/5',
                              style: GoogleFonts.nunito(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A))),
                          Text(' Logged',
                              style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Active monitoring',
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD97706))),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('Sarah Jenkins',
                            style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155))),
                        Text('Updated 12m ago',
                            style: GoogleFonts.nunito(
                                fontSize: 9, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7-Day Trend Bar Chart
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-Day Trend',
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: SymptomsBarChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildXAxisLabel('MON'), _buildXAxisLabel('TUE'),
                      _buildXAxisLabel('WED'),
                      _buildXAxisLabel('THU', isBold: true), // Highlighted day
                      _buildXAxisLabel('FRI'), _buildXAxisLabel('SAT'),
                      _buildXAxisLabel('SUN'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Logs
            Text('Daily Logs',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),

            _buildSymptomLogItem(
              symptoms: 'Vomiting, High Fever',
              time: 'Today, 02:30 PM',
              status: 'ACTION NEEDED',
              statusBg: const Color(0xFFFEF2F2),
              statusColor: const Color(0xFFDC2626),
              icon: Icons.warning_amber_rounded,
              iconBg: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
            ),
            _buildSymptomLogItem(
              symptoms: 'Yellow Eyes, Fatigue',
              time: 'Yesterday, 09:00 AM',
              status: 'OBSERVED',
              statusBg: const Color(0xFFFEFCE8),
              statusColor: const Color(0xFFD97706),
              icon: Icons.info_outline,
              iconBg: const Color(0xFFFEFCE8),
              iconColor: const Color(0xFFF59E0B),
            ),
            _buildSymptomLogItem(
              symptoms: 'Muscle Pain (Mild)',
              time: 'Oct 24, 08:15 PM',
              status: 'STABLE',
              statusBg: const Color(0xFFEFF6FF),
              statusColor: const Color(0xFF2563EB),
              icon: Icons.check_circle_outline,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXAxisLabel(String text, {bool isBold = false}) {
    return Text(
      text,
      style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: isBold ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
    );
  }

  Widget _buildSymptomLogItem({
    required String symptoms,
    required String time,
    required String status,
    required Color statusBg,
    required Color statusColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: iconBg, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(symptoms,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(time,
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusBg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              status.replaceFirst(
                  ' ', '\n'), // Wraps "ACTION NEEDED" to match your design
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class SymptomsBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Colors based on the screenshot
    final defaultBarPaint = Paint()
      ..color = const Color(0xFFF1F5F9) // Light grayish blue
      ..style = PaintingStyle.fill;

    final highlightBarPaint = Paint()
      ..color = const Color(0xFFEF4444) // Red
      ..style = PaintingStyle.fill;

    // Heights representing the number of symptoms (0.0 to 1.0)
    final barHeights = [0.35, 0.6, 0.25, 0.95, 0.7, 0.5, 0.25];

    // Calculate layout
    final barWidth = 8.0;
    final spacing = (size.width - (barWidth * 7)) / 6;

    for (int i = 0; i < 7; i++) {
      final xOffset = i * (barWidth + spacing);
      final height = size.height * barHeights[i];
      final yOffset = size.height - height;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xOffset, yOffset, barWidth, height),
        const Radius.circular(4), // Rounded tops and bottoms
      );

      // The 4th bar (Thursday) gets the red highlight paint
      canvas.drawRRect(rect, i == 3 ? highlightBarPaint : defaultBarPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

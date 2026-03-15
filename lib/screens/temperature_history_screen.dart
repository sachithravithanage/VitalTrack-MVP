import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemperatureHistoryScreen extends StatelessWidget {
  const TemperatureHistoryScreen({super.key});

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
          'Temperature History',
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
            // Current Temperature Card
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
                      Text('CURRENT TEMPERATURE',
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
                          Text('98.6',
                              style: GoogleFonts.nunito(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A))),
                          Text('°F',
                              style: GoogleFonts.nunito(
                                  fontSize: 24,
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
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Stable',
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('Sarah Jenkins',
                            style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F766E))),
                        Text('Updated 5m ago',
                            style: GoogleFonts.nunito(
                                fontSize: 9, color: const Color(0xFF14B8A6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7-Day Trend Chart
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
                  // The Custom Canvas Chart!
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: TrendChartPainter(
                          lineColor: const Color(0xFFEF4444),
                          fillColor: const Color(0xFFFEF2F2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // X-Axis Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                        .map((day) {
                      return Text(day,
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8)));
                    }).toList(),
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
            _buildDailyLogItem(
                temp: '102.1°F',
                time: 'Today, 02:30 PM',
                status: 'HIGH FEVER',
                isHigh: true),
            _buildDailyLogItem(
                temp: '98.6°F',
                time: 'Yesterday, 09:00 AM',
                status: 'STABLE',
                isHigh: false),
            _buildDailyLogItem(
                temp: '98.4°F',
                time: 'Oct 24, 08:15 PM',
                status: 'STABLE',
                isHigh: false),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogItem(
      {required String temp,
      required String time,
      required String status,
      required bool isHigh}) {
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isHigh
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.thermostat,
                    color: isHigh
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(temp,
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B))),
                  Text(time,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHigh
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF059669))),
          ),
        ],
      ),
    );
  }
}

// This handles the exact lines, curves, and gradients from your HTML Canvas!
class TrendChartPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;

  TrendChartPainter({required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor.withOpacity(0.8), fillColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Coordinates mimicking the HTML canvas points
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.16, size.height * 0.75),
      Offset(size.width * 0.33, size.height * 0.85),
      Offset(size.width * 0.5, size.height * 0.2), // The spike!
      Offset(size.width * 0.66, size.height * 0.45),
      Offset(size.width * 0.83, size.height * 0.75),
      Offset(size.width, size.height * 0.82),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Draw fill underneath the line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw the tiny dots on the data points
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

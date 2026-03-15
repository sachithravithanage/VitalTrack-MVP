import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UrineOutputHistoryScreen extends StatelessWidget {
  const UrineOutputHistoryScreen({super.key});

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
          'Urine Output History',
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
            // Current Urine Output Card
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
                      Text('DAILY URINE OUTPUT',
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
                          Text('1.2',
                              style: GoogleFonts.nunito(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A))),
                          Text(' L',
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
                          Text('Normal',
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
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: UrineChartPainter(
                          lineColor: const Color(0xFFFBBF24),
                          fillColor: const Color(0xFFFEF3C7)),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                amount: '400 ml', time: 'Today, 11:15 AM', status: 'NORMAL'),
            _buildDailyLogItem(
                amount: '350 ml',
                time: 'Yesterday, 06:45 PM',
                status: 'NORMAL'),
            _buildDailyLogItem(
                amount: '450 ml', time: 'Oct 24, 02:20 PM', status: 'NORMAL'),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogItem(
      {required String amount, required String time, required String status}) {
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
                  color:
                      const Color(0xFFFEFCE8), // Light amber/yellow background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.science_outlined,
                    color: Color(0xFFF59E0B)), // Amber beaker icon
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(amount,
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
              color: const Color(0xFFF0FDF4), // Light green pill
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF059669))), // Dark green text
          ),
        ],
      ),
    );
  }
}

class UrineChartPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;

  UrineChartPainter({required this.lineColor, required this.fillColor});

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

    // Exact coordinates from your HTML canvas script!
    final points = [
      Offset(size.width * 0.05, size.height * 0.8),
      Offset(size.width * 0.20, size.height * 0.75),
      Offset(size.width * 0.35, size.height * 0.85),
      Offset(size.width * 0.50, size.height * 0.3), // Peak output
      Offset(size.width * 0.65, size.height * 0.45),
      Offset(size.width * 0.82, size.height * 0.75),
      Offset(size.width * 0.95, size.height * 0.82),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(path, paint);

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

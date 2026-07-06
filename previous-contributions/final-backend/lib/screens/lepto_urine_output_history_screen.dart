import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/lepto_health_data_provider.dart';

class LeptoUrineOutputHistoryScreen extends StatefulWidget {
  const LeptoUrineOutputHistoryScreen({super.key});

  @override
  State<LeptoUrineOutputHistoryScreen> createState() =>
      _LeptoUrineOutputHistoryScreenState();
}

class _LeptoUrineOutputHistoryScreenState
    extends State<LeptoUrineOutputHistoryScreen> {
  double _currentOutput = 400;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    // Saves directly to Firebase using the Lepto Provider!
    // We pass 'null' for the second value because urine only uses one slider
    context.read<LeptoHealthDataProvider>().addEntry(
          'Urine Output',
          _currentOutput,
          null,
          _notesController.text.trim(),
        );

    setState(() {
      _notesController.clear();
      _hasRecordedVoice = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Urine output saved successfully!'),
          backgroundColor: Color(0xFF14B8A6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read live data from Firestore via Provider
    final provider = context.watch<LeptoHealthDataProvider>();
    final metric = provider.metricsData['Urine Output']!;

    // Infer alert state from the latest chart data if available
    final bool isCurrentlyAlert =
        metric.chartData.isNotEmpty && metric.chartData.last < 300;
    final String currentStatus = isCurrentlyAlert ? 'LOW OUTPUT' : 'NORMAL';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B), size: 18),
            onPressed: () => Navigator.pop(context)),
        title: Text('Health Data History',
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
            // Top Tabs specifically for Leptospirosis
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('Blood Pressure', false),
                    _buildTab('Symptoms', false),
                    _buildTab('Temperature', false),
                    _buildTab('Urine Output', true), // Active Tab
                  ],
                ),
              ),
            ),

            // Current Output Card
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
                  ]),
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
                          Text(metric.currentValue,
                              style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A))),
                          if (metric.currentValue != '--')
                            Text(' ml',
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (metric.history.isNotEmpty)
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: isCurrentlyAlert
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(currentStatus,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentlyAlert
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981))),
                          ],
                        )
                      else
                        Text('Goal: 1.5 L',
                            style: GoogleFonts.nunito(
                                fontSize: 14, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.science,
                        color: Color(0xFFEAB308), size: 32),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Entry Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Urine Output Entry',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A))),
                      Text('${_currentOutput.toInt()} ml',
                          style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF14B8A6))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF14B8A6),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white),
                    child: Slider(
                        value: _currentOutput,
                        min: 0,
                        max: 1000,
                        divisions: 100,
                        onChanged: (value) =>
                            setState(() => _currentOutput = value)),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: _saveEntry,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text('Save Entry',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFF1F5F9))),

                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        hintText: 'Add additional notes here...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 16),

                  // Voice Note Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          backgroundColor: _hasRecordedVoice
                              ? const Color(0xFFE6FFFA)
                              : const Color(0xFFF8FAFC),
                          side: BorderSide(
                              color: _hasRecordedVoice
                                  ? const Color(0xFF14B8A6)
                                  : Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () => setState(
                          () => _hasRecordedVoice = !_hasRecordedVoice),
                      icon: Icon(_hasRecordedVoice ? Icons.mic : Icons.mic_none,
                          color: const Color(0xFF14B8A6)),
                      label: Text(
                          _hasRecordedVoice
                              ? 'Voice Note Attached'
                              : 'Record Voice Note',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Chart
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
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-DAY TREND',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: const Color(0xFF0F172A))),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: AngularTrendChartPainter(
                          dataPoints: metric.chartData.isNotEmpty
                              ? metric.chartData
                              : [400],
                          minY: 0,
                          maxY: 1000,
                          lineColor: const Color(0xFFEAB308), // Gold
                          fillColor: const Color(0xFFFEF3C7) // Light Gold
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                        .map((day) => Text(day,
                            style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8))))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logs
            Text('Daily Logs',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),

            if (metric.history.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No entries yet.',
                          style: GoogleFonts.nunito(color: Colors.grey))))
            else
              ...metric.history.map(_buildDailyLogItem),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? const Color(0xFF14B8A6) : Colors.blueGrey)),
          const SizedBox(height: 8),
          if (isActive)
            Container(
                height: 3,
                width: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: const Color(0xFF14B8A6)))
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildDailyLogItem(Map<String, dynamic> record) {
    // Parse value to determine alert status since it's dynamic
    final String valStr = record['val'] ?? '--';
    final double outputVal =
        double.tryParse(valStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 400;
    final bool isAlert = outputVal < 300;

    final String notes = record['notes'] ?? '';
    final bool hasVoiceNote = record['hasVoiceNote'] ?? false;
    final String statusStr = isAlert ? 'LOW OUTPUT' : 'NORMAL';

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
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: isAlert
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.science,
                        color: isAlert
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFEAB308)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(valStr,
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      Text(record['time'] ?? '--',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: isAlert
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(statusStr,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAlert
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF059669))),
              ),
            ],
          ),
          if (notes.isNotEmpty || hasVoiceNote) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFF1F5F9), height: 1)),
            if (notes.isNotEmpty)
              Text('Note: "$notes"',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic)),
            if (notes.isNotEmpty && hasVoiceNote) const SizedBox(height: 8),
            if (hasVoiceNote)
              Row(children: [
                const Icon(Icons.play_circle_fill,
                    size: 16, color: Color(0xFF14B8A6)),
                const SizedBox(width: 6),
                Text('Voice note attached',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF14B8A6)))
              ]),
          ]
        ],
      ),
    );
  }
}

class AngularTrendChartPainter extends CustomPainter {
  AngularTrendChartPainter(
      {required this.lineColor,
      required this.fillColor,
      required this.dataPoints,
      required this.minY,
      required this.maxY});
  final Color lineColor;
  final Color fillColor;
  final List<double> dataPoints;
  final double minY;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [fillColor.withOpacity(0.8), fillColor.withOpacity(0)])
          .createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final double range = maxY - minY == 0 ? 1 : maxY - minY;
    final List<Offset> points = [];

    final int count = dataPoints.length;
    for (int i = 0; i < count; i++) {
      final double x =
          count == 1 ? size.width / 2 : size.width * (i / (count - 1));
      final double val = dataPoints[i].clamp(minY, maxY);
      final double normalizedY = 1.0 - ((val - minY) / range);
      final double y = size.height * 0.1 + (size.height * 0.8 * normalizedY);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (count > 1) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/health_data_provider.dart';
import '../models/health_log.dart';

class UrineOutputHistoryScreen extends StatefulWidget {
  const UrineOutputHistoryScreen({super.key});

  @override
  State<UrineOutputHistoryScreen> createState() =>
      _UrineOutputHistoryScreenState();
}

class _UrineOutputHistoryScreenState extends State<UrineOutputHistoryScreen> {
  double _currentOutput = 400;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final bool isAlert = _currentOutput < 300;
    final String status = isAlert ? 'LOW OUTPUT' : 'NORMAL';

    context.read<HealthDataProvider>().addEntry(
          'Urine Output',
          value1: _currentOutput,
          notes: _notesController.text.trim(),
          hasVoiceNote: _hasRecordedVoice,
          status: status,
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
    final provider = context.watch<HealthDataProvider>();
    final latestLog = provider.getLatestLog('Urine Output');
    final history = provider.getLogsByType('Urine Output');

    final bool isCurrentlyAlert = latestLog?.status == 'LOW OUTPUT';
    final String currentValue =
        latestLog != null ? '${latestLog.value1?.toInt()} ml' : '-- ml';

    List<double> chartData = provider.getChartData('Urine Output');
    if (chartData.isEmpty) chartData = [400.0];

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
                      Text('LATEST URINE OUTPUT',
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(currentValue,
                          style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      if (latestLog != null)
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
                            Text(latestLog.status,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentlyAlert
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981))),
                          ],
                        )
                      else
                        Text('Record an entry below',
                            style: GoogleFonts.nunito(
                                fontSize: 14, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.water_drop,
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
                      Text('New Urine Entry',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A))),
                      Text('${_currentOutput.toInt()} ml',
                          style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEAB308))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFEAB308),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white),
                    child: Slider(
                        value: _currentOutput,
                        min: 0,
                        max: 1000,
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
                        hintText: 'Color, frequency, or other notes...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 16),
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

            // Chart
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
                      painter: DynamicTrendChartPainter(
                          dataPoints: chartData,
                          lineColor: const Color(0xFFEAB308),
                          fillColor: const Color(0xFFFEFCE8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logs
            Text('Recent History',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),

            if (history.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No entries yet.',
                          style: GoogleFonts.nunito(color: Colors.grey))))
            else
              ...history.map((log) => _buildDailyLogItem(log)),
          ],
        ),
      ),
    );
  }

  // RESTORED: This now perfectly matches your original design for the history cards!
  Widget _buildDailyLogItem(HealthLog log) {
    final bool isAlert = log.status == 'LOW OUTPUT';
    final String formattedTime =
        DateFormat('MMM d, h:mm a').format(log.timestamp);

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
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(16)),
                    child:
                        const Icon(Icons.water_drop, color: Color(0xFFEAB308)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${log.value1?.toInt() ?? 0} ml',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      Text(formattedTime,
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
                child: Text(log.status,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAlert
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF059669))),
              ),
            ],
          ),
          // Restored Notes and Voice Notes UI
          if (log.notes.isNotEmpty || log.hasVoiceNote) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            if (log.notes.isNotEmpty)
              Text('Note: "${log.notes}"',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic)),
            if (log.notes.isNotEmpty && log.hasVoiceNote)
              const SizedBox(height: 8),
            if (log.hasVoiceNote)
              Row(
                children: [
                  const Icon(Icons.play_circle_fill,
                      size: 16, color: Color(0xFF14B8A6)),
                  const SizedBox(width: 6),
                  Text('Voice note attached',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF14B8A6))),
                ],
              ),
          ]
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// THE UNIVERSAL DYNAMIC CHART PAINTER
// ----------------------------------------------------
class DynamicTrendChartPainter extends CustomPainter {
  DynamicTrendChartPainter({
    required this.lineColor,
    required this.fillColor,
    required this.dataPoints,
  });

  final Color lineColor;
  final Color fillColor;
  final List<double> dataPoints;

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
        colors: [fillColor.withOpacity(0.8), fillColor.withOpacity(0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Dynamically calculate the Min and Max bounds based on the data provided!
    double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);

    // Add a 10% padding buffer to the top and bottom so the line doesn't hit the ceiling
    final double padding = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal) * 0.1;
    minVal -= padding;
    maxVal += padding;
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final List<Offset> points = [];
    final int count = dataPoints.length;

    for (int i = 0; i < count; i++) {
      final double x =
          count == 1 ? size.width / 2 : size.width * (i / (count - 1));
      final double normalizedY = 1.0 - ((dataPoints[i] - minVal) / range);
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

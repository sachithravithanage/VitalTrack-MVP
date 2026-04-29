import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/health_data_provider.dart';
import '../models/health_log.dart';

class TemperatureHistoryScreen extends StatefulWidget {
  const TemperatureHistoryScreen({super.key});

  @override
  State<TemperatureHistoryScreen> createState() =>
      _TemperatureHistoryScreenState();
}

class _TemperatureHistoryScreenState extends State<TemperatureHistoryScreen> {
  double _currentTemp = 98.6;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final bool isHighFever = _currentTemp >= 100.4;
    final String status = isHighFever ? 'HIGH FEVER' : 'STABLE';

    // Call the unified provider to push to Firestore
    context.read<HealthDataProvider>().addEntry(
          'Temperature',
          value1: _currentTemp,
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
        content: Text('Temperature entry saved successfully!'),
        backgroundColor: Color(0xFF14B8A6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live data from the unified provider
    final provider = context.watch<HealthDataProvider>();
    final latestLog = provider.getLatestLog('Temperature');
    final history = provider.getLogsByType('Temperature');

    final bool isCurrentlyAlert = latestLog?.status == 'HIGH FEVER';
    final String currentValue =
        latestLog != null ? '${latestLog.value1} °F' : '-- °F';

    List<double> chartData = provider.getChartData('Temperature');
    if (chartData.isEmpty) chartData = [98.6];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B), size: 18),
            onPressed: () => Navigator.pop(context)),
        title: Text('Temperature History',
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
                  ]),
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
                      // Display dynamic value
                      Text(currentValue,
                          style: GoogleFonts.nunito(
                              fontSize: 36,
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
                      Text('New Temperature Entry',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A))),
                      Text('${_currentTemp.toStringAsFixed(1)} °F',
                          style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEA580C))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFEA580C),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white),
                    child: Slider(
                        value: _currentTemp,
                        min: 95,
                        max: 105,
                        onChanged: (value) =>
                            setState(() => _currentTemp = value)),
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
                      onPressed: () {
                        setState(() {
                          _hasRecordedVoice = !_hasRecordedVoice;
                        });
                      },
                      icon: Icon(_hasRecordedVoice ? Icons.mic : Icons.mic_none,
                          color: const Color(0xFF14B8A6)),
                      label: Text(
                          _hasRecordedVoice
                              ? 'Voice Note Attached (Tap to remove)'
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

            // Dynamic Point-to-Point Trend Chart
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
                          dataPoints: chartData,
                          lineColor: const Color(0xFFEF4444),
                          fillColor: const Color(0xFFFEF2F2)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Daily Logs',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),

            if (history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                      'No entries yet. Save an entry above to see history.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(color: Colors.grey)),
                ),
              )
            else
              ...history.map(_buildDailyLogItem),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogItem(HealthLog log) {
    final bool isAlert = log.status == 'HIGH FEVER';
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
                        color: isAlert
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.thermostat,
                        color: isAlert
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${log.value1}',
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
// THE DYNAMIC CHART PAINTER
// ----------------------------------------------------
class AngularTrendChartPainter extends CustomPainter {
  AngularTrendChartPainter(
      {required this.lineColor,
      required this.fillColor,
      required this.dataPoints});
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

    const double minTemp = 95;
    const double maxTemp = 105;
    final double range = maxTemp - minTemp;

    final List<Offset> points = [];

    final int count = dataPoints.length;
    for (int i = 0; i < count; i++) {
      final double x =
          count == 1 ? size.width / 2 : size.width * (i / (count - 1));
      final double temp = dataPoints[i].clamp(minTemp, maxTemp);
      final double normalizedY = 1.0 - ((temp - minTemp) / range);
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

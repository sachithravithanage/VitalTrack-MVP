import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/health_data_provider.dart';
import '../models/health_log.dart';

class BloodPressureHistoryScreen extends StatefulWidget {
  const BloodPressureHistoryScreen({super.key});

  @override
  State<BloodPressureHistoryScreen> createState() =>
      _BloodPressureHistoryScreenState();
}

class _BloodPressureHistoryScreenState
    extends State<BloodPressureHistoryScreen> {
  double _systolic = 120;
  double _diastolic = 80;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final bool isElevated = _systolic > 120 || _diastolic > 80;
    final String status = isElevated ? 'Elevated' : 'Normal';

    // Save directly to Firestore using our unified HealthDataProvider
    context.read<HealthDataProvider>().addEntry(
          'Blood Pressure',
          value1: _systolic,
          value2: _diastolic,
          notes: _notesController.text.trim(),
          status: status,
          hasVoiceNote: _hasRecordedVoice,
        );

    setState(() {
      _notesController.clear();
      _hasRecordedVoice = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Blood pressure saved successfully!'),
          backgroundColor: Color(0xFF14B8A6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch live data from our new unified provider
    final provider = context.watch<HealthDataProvider>();
    final latestLog = provider.getLatestLog('Blood Pressure');
    final history = provider.getLogsByType('Blood Pressure');

    final bool isCurrentlyAlert = latestLog?.status == 'Elevated';

    // Format the current value string
    final String currentValue = latestLog != null
        ? '${latestLog.value1?.toInt()}/${latestLog.value2?.toInt()}'
        : '--/--';

    // Prepare chart data using the helper methods
    List<double> sysData = provider.getChartData('Blood Pressure');
    if (sysData.isEmpty) sysData = [120.0];

    List<double> diaData =
        provider.getChartData('Blood Pressure', isSecondary: true);
    if (diaData.isEmpty) diaData = [80.0];

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
            // Current BP Card
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
                      Text('LATEST BLOOD PRESSURE',
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
                          Text(currentValue,
                              style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFEA580C))),
                          if (currentValue != '--/--')
                            Text(' mmHg',
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B))),
                        ],
                      ),
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
                            Text(latestLog.status.toUpperCase(),
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentlyAlert
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981))),
                          ],
                        )
                      else
                        Text('Goal: 120/80',
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
                    child: const Icon(Icons.favorite,
                        color: Color(0xFFEA580C), size: 32),
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
                  Text('New Blood Pressure Entry',
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A))),
                  const SizedBox(height: 24),

                  // Systolic Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Systolic (Top)',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey)),
                      Text('${_systolic.toInt()} mmHg',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEA580C))),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFEA580C),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white),
                    child: Slider(
                        value: _systolic,
                        min: 80,
                        max: 200,
                        onChanged: (value) =>
                            setState(() => _systolic = value)),
                  ),
                  const SizedBox(height: 16),

                  // Diastolic Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diastolic (Bottom)',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey)),
                      Text('${_diastolic.toInt()} mmHg',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF97316))),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFF97316),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white),
                    child: Slider(
                        value: _diastolic,
                        min: 50,
                        max: 130,
                        onChanged: (value) =>
                            setState(() => _diastolic = value)),
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
                        hintText: 'How are you feeling?',
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

            // Dynamic Dual Line Chart
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('7-DAY TREND',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: const Color(0xFF0F172A))),
                      Row(
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              color: const Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          Text('Sys',
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(width: 8),
                          Container(
                              width: 8,
                              height: 8,
                              color: const Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text('Dia',
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: DualLineChartPainter(
                        dataPoints: [sysData, diaData],
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
              ...history.map(_buildDailyLogItem),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogItem(HealthLog log) {
    final bool isAlert = log.status == 'Elevated';
    final String formattedTime =
        DateFormat('MMM d, h:mm a').format(log.timestamp);
    final String valueText = '${log.value1?.toInt()}/${log.value2?.toInt()}';

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
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(valueText,
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
                child: Text(log.status.toUpperCase(),
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
                child: Divider(color: Color(0xFFF1F5F9), height: 1)),
            if (log.notes.isNotEmpty)
              Text('Note: "${log.notes}"',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic)),
            if (log.notes.isNotEmpty && log.hasVoiceNote)
              const SizedBox(height: 8),
            if (log.hasVoiceNote)
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

// ----------------------------------------------------
// THE DUAL LINE CHART PAINTER
// ----------------------------------------------------
class DualLineChartPainter extends CustomPainter {
  DualLineChartPainter({required this.dataPoints});
  final List<List<double>> dataPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || dataPoints[0].isEmpty || dataPoints[1].isEmpty) {
      return;
    }

    const double minY = 40;
    const double maxY = 220;
    final double range = maxY - minY;

    final List<Offset> sysPoints = [];
    final List<Offset> diaPoints = [];

    final int count = dataPoints[0].length;

    for (int i = 0; i < count; i++) {
      final double x =
          count == 1 ? size.width / 2 : size.width * (i / (count - 1));

      final double sysVal = dataPoints[0][i].clamp(minY, maxY);
      final double sysY = size.height * 0.1 +
          (size.height * 0.8 * (1.0 - ((sysVal - minY) / range)));
      sysPoints.add(Offset(x, sysY));

      final double diaVal =
          (i < dataPoints[1].length) ? dataPoints[1][i].clamp(minY, maxY) : 80;
      final double diaY = size.height * 0.1 +
          (size.height * 0.8 * (1.0 - ((diaVal - minY) / range)));
      diaPoints.add(Offset(x, diaY));
    }

    _drawLine(canvas, size, sysPoints, const Color(0xFFEA580C));
    _drawLine(canvas, size, diaPoints, const Color(0xFFFBBF24));
  }

  void _drawLine(
      Canvas canvas, Size size, List<Offset> points, Color lineColor) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
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

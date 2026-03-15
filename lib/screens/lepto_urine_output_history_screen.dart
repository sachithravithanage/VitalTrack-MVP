import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

class LeptoUrineOutputHistoryScreen extends StatefulWidget {
  const LeptoUrineOutputHistoryScreen({super.key});

  @override
  State<LeptoUrineOutputHistoryScreen> createState() =>
      _LeptoUrineOutputHistoryScreenState();
}

class _LeptoUrineOutputHistoryScreenState
    extends State<LeptoUrineOutputHistoryScreen> {
  double _currentOutput = 400.0;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    String formattedVal = '${_currentOutput.toInt()} ml';

    // Simple logic: under 300ml might be a warning sign of dehydration
    bool isAlert = _currentOutput < 300;
    String status = isAlert ? 'LOW OUTPUT' : 'NORMAL';

    final now = DateTime.now();
    int hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    String timeStr = "Today, $hour:$minute $period";

    setState(() {
      // CHANGED TO: globalLeptoUrineHistory
      globalLeptoUrineHistory.insert(
          0,
          HealthRecord(
            formattedVal,
            timeStr,
            status,
            isAlert,
            notes: _notesController.text.trim(),
            hasVoiceNote: _hasRecordedVoice,
          ));

      _notesController.clear();
      _hasRecordedVoice = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Urine output saved successfully!'),
          backgroundColor: Color(0xFF14B8A6)),
    );
  }

  List<double> _getTrendData() {
    List<double> chartData = List.filled(7, 400.0);
    // CHANGED TO: globalLeptoUrineHistory
    if (globalLeptoUrineHistory.isNotEmpty) {
      var recentRecords =
          globalLeptoUrineHistory.take(7).toList().reversed.toList();
      int startIndex = 7 - recentRecords.length;
      for (int i = 0; i < recentRecords.length; i++) {
        String rawVal = recentRecords[i].value.replaceAll(' ml', '').trim();
        chartData[startIndex + i] = double.tryParse(rawVal) ?? 400.0;
      }
      for (int i = 0; i < startIndex; i++) {
        chartData[i] = chartData[startIndex];
      }
    }
    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    // CHANGED TO: globalLeptoUrineHistory
    final latestRecord = globalLeptoUrineHistory.isNotEmpty
        ? globalLeptoUrineHistory.first
        : HealthRecord("--", "No data yet", "NONE", false);

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
        padding: const EdgeInsets.all(24.0),
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
                          Text(latestRecord.value.replaceAll(' ml', ''),
                              style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A))),
                          if (latestRecord.value != "--")
                            Text(' ml',
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // CHANGED TO: globalLeptoUrineHistory
                      if (globalLeptoUrineHistory.isNotEmpty)
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: latestRecord.isAlert
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(latestRecord.status,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: latestRecord.isAlert
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
                        min: 0.0,
                        max: 1000.0,
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
                          dataPoints: _getTrendData(),
                          minY: 0.0,
                          maxY: 1000.0,
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

            // CHANGED TO: globalLeptoUrineHistory
            if (globalLeptoUrineHistory.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("No entries yet.",
                          style: GoogleFonts.nunito(color: Colors.grey))))
            else
              ...globalLeptoUrineHistory
                  .map((record) => _buildDailyLogItem(record)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
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

  Widget _buildDailyLogItem(HealthRecord record) {
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
                        color: record.isAlert
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.science,
                        color: record.isAlert
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFEAB308)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.value,
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      Text(record.time,
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
                    color: record.isAlert
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(record.status,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: record.isAlert
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF059669))),
              ),
            ],
          ),
          if (record.notes.isNotEmpty || record.hasVoiceNote) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFF1F5F9), height: 1)),
            if (record.notes.isNotEmpty)
              Text('Note: "${record.notes}"',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic)),
            if (record.notes.isNotEmpty && record.hasVoiceNote)
              const SizedBox(height: 8),
            if (record.hasVoiceNote)
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
  final Color lineColor;
  final Color fillColor;
  final List<double> dataPoints;
  final double minY;
  final double maxY;

  AngularTrendChartPainter(
      {required this.lineColor,
      required this.fillColor,
      required this.dataPoints,
      required this.minY,
      required this.maxY});

  @override
  void paint(Canvas canvas, Size size) {
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
              colors: [fillColor.withOpacity(0.8), fillColor.withOpacity(0.0)])
          .createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    double range = maxY - minY;
    List<Offset> points = [];

    for (int i = 0; i < 7; i++) {
      double x = size.width * (i / 6);
      double val = dataPoints[i].clamp(minY, maxY);
      double normalizedY = 1.0 - ((val - minY) / range);
      double y = size.height * 0.1 + (size.height * 0.8 * normalizedY);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++)
      path.lineTo(points[i].dx, points[i].dy);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

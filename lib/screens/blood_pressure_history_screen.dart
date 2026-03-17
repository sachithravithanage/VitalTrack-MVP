import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

class BloodPressureHistoryScreen extends StatefulWidget {
  const BloodPressureHistoryScreen({super.key});

  @override
  State<BloodPressureHistoryScreen> createState() =>
      _BloodPressureHistoryScreenState();
}

class _BloodPressureHistoryScreenState
    extends State<BloodPressureHistoryScreen> {
  double _systolic = 120.0;
  double _diastolic = 80.0;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    String formattedVal = '${_systolic.toInt()}/${_diastolic.toInt()} mmHg';

    // BP Logic (High if Sys > 130 or Dia > 85)
    bool isAlert = _systolic > 130 || _diastolic > 85;
    String status = isAlert ? 'ELEVATED' : 'NORMAL';

    final now = DateTime.now();
    int hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    String timeStr = "Today, $hour:$minute $period";

    setState(() {
      globalBPHistory.insert(
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
          content: Text('Blood pressure saved successfully!'),
          backgroundColor: Color(0xFF14B8A6)),
    );
  }

  // Returns two lists: [systolicData, diastolicData]
  List<List<double>> _getDualTrendData() {
    List<double> sysData = List.filled(7, 120.0);
    List<double> diaData = List.filled(7, 80.0);

    if (globalBPHistory.isNotEmpty) {
      var recentRecords = globalBPHistory.take(7).toList().reversed.toList();
      int startIndex = 7 - recentRecords.length;
      for (int i = 0; i < recentRecords.length; i++) {
        // Parse "120/80 mmHg"
        String rawVal = recentRecords[i].value.replaceAll(' mmHg', '').trim();
        List<String> parts = rawVal.split('/');
        if (parts.length == 2) {
          sysData[startIndex + i] = double.tryParse(parts[0]) ?? 120.0;
          diaData[startIndex + i] = double.tryParse(parts[1]) ?? 80.0;
        }
      }
      for (int i = 0; i < startIndex; i++) {
        sysData[i] = sysData[startIndex];
        diaData[i] = diaData[startIndex];
      }
    }
    return [sysData, diaData];
  }

  @override
  Widget build(BuildContext context) {
    final latestRecord = globalBPHistory.isNotEmpty
        ? globalBPHistory.first
        : HealthRecord("--/--", "No data yet", "NONE", false);

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
                          Text(latestRecord.value.replaceAll(' mmHg', ''),
                              style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFEA580C))),
                          if (latestRecord.value != "--/--")
                            Text(' mmHg',
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (globalBPHistory.isNotEmpty)
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
                        min: 80.0,
                        max: 200.0,
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
                        min: 50.0,
                        max: 130.0,
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
                        dataPoints: _getDualTrendData(),
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

            if (globalBPHistory.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("No entries yet.",
                          style: GoogleFonts.nunito(color: Colors.grey))))
            else
              ...globalBPHistory.map((record) => _buildDailyLogItem(record)),
          ],
        ),
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
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.favorite,
                        color: record.isAlert
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFEF4444)),
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

// ----------------------------------------------------
// THE NEW DUAL LINE CHART PAINTER
// ----------------------------------------------------
class DualLineChartPainter extends CustomPainter {
  final List<List<double>> dataPoints; // [sysData, diaData]

  DualLineChartPainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || dataPoints[0].isEmpty) return;

    double minY = 40.0;
    double maxY = 220.0;
    double range = maxY - minY;

    List<Offset> sysPoints = [];
    List<Offset> diaPoints = [];

    // Calculate Coordinates
    for (int i = 0; i < 7; i++) {
      double x = size.width * (i / 6);

      double sysVal = dataPoints[0][i].clamp(minY, maxY);
      double sysY = size.height * 0.1 +
          (size.height * 0.8 * (1.0 - ((sysVal - minY) / range)));
      sysPoints.add(Offset(x, sysY));

      double diaVal = dataPoints[1][i].clamp(minY, maxY);
      double diaY = size.height * 0.1 +
          (size.height * 0.8 * (1.0 - ((diaVal - minY) / range)));
      diaPoints.add(Offset(x, diaY));
    }

    _drawLine(canvas, size, sysPoints,
        const Color(0xFFEA580C)); // Orange for Systolic
    _drawLine(canvas, size, diaPoints,
        const Color(0xFFFBBF24)); // Yellow for Diastolic
  }

  void _drawLine(
      Canvas canvas, Size size, List<Offset> points, Color lineColor) {
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

    // Draw dots
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

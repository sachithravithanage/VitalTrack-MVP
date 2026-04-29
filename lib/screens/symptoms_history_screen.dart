import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/health_data_provider.dart';
import '../models/health_log.dart';

class SymptomsHistoryScreen extends StatefulWidget {
  const SymptomsHistoryScreen({super.key});

  @override
  State<SymptomsHistoryScreen> createState() => _SymptomsHistoryScreenState();
}

class _SymptomsHistoryScreenState extends State<SymptomsHistoryScreen> {
  final Map<String, bool> _symptoms = {
    'High Fever': true,
    'Muscle Pain': true,
    'Headache': false,
    'Nausea / Vomiting': false,
    'Yellow Eyes / Skin': true,
    'Dark Urine': false,
  };

  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final List<String> activeSymptomsList = _symptoms.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final double count = activeSymptomsList.length.toDouble();
    final String status = count >= 3 ? 'EVALUATE' : 'MONITOR';

    // Save directly to Firebase using the HealthDataProvider
    // We pass 'count' to value1 so the Bar Chart knows how high to draw the bar!
    context.read<HealthDataProvider>().addEntry(
          'Symptoms',
          value1: count,
          symptoms: activeSymptomsList,
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
          content: Text('Symptoms logged successfully!'),
          backgroundColor: Color(0xFF14B8A6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch live data from Firestore via the unified Provider
    final provider = context.watch<HealthDataProvider>();
    final latestLog = provider.getLatestLog('Symptoms');
    final history = provider.getLogsByType('Symptoms');

    final bool isCurrentlyAlert =
        latestLog != null && (latestLog.value1 ?? 0) >= 3;
    final String currentStatus = isCurrentlyAlert ? 'EVALUATE' : 'MONITOR';
    final String currentValue =
        latestLog != null ? '${latestLog.value1?.toInt()}/6' : '0/6';

    List<double> chartData = provider.getChartData('Symptoms');
    if (chartData.isEmpty) chartData = [0.0];

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
            // Latest Status Card
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
                      Text('ACTIVE SYMPTOMS',
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
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(currentStatus,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentlyAlert
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B))),
                          ],
                        )
                      else
                        Text('Log symptoms below',
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
                    child: const Icon(Icons.sick,
                        color: Color(0xFFF59E0B), size: 32),
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
                  Text('Symptom Checklist',
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  ..._symptoms.keys.map((symptom) {
                    return CheckboxListTile(
                      title: Text(symptom,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B))),
                      value: _symptoms[symptom],
                      activeColor: const Color(0xFFF59E0B),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          _symptoms[symptom] = value!;
                        });
                      },
                    );
                  }),
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

            // Dynamic Bar Chart
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
                      painter: DynamicBarChartPainter(
                        dataPoints: chartData,
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
    final bool isAlert = (log.value1 ?? 0) >= 3;
    final String formattedTime =
        DateFormat('MMM d, h:mm a').format(log.timestamp);
    final String statusStr = isAlert ? 'EVALUATE' : 'MONITOR';

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
                    child: Icon(Icons.sick,
                        color: isAlert
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${log.value1?.toInt() ?? 0} Symptoms',
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
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(statusStr,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAlert
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFFD97706))),
              ),
            ],
          ),

          // DYNAMIC SYMPTOM TAGS DISPLAY
          if (log.symptoms != null && log.symptoms!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: log.symptoms!
                  .map((sym) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(sym,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF475569))),
                      ))
                  .toList(),
            ),
          ],

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

class DynamicBarChartPainter extends CustomPainter {
  DynamicBarChartPainter({required this.dataPoints});
  final List<double> dataPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final defaultBarPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    final highlightBarPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    const double maxSymptoms = 6;
    const barWidth = 12.0;

    // Dynamically calculate spacing based on the number of points (up to 7)
    final int count = dataPoints.length > 7 ? 7 : dataPoints.length;
    final spacing =
        count > 1 ? (size.width - (barWidth * count)) / (count - 1) : 0.0;

    for (int i = 0; i < count; i++) {
      final xOffset = count == 1
          ? size.width / 2 - (barWidth / 2)
          : i * (barWidth + spacing);
      final double val = dataPoints[i].clamp(0.0, maxSymptoms);
      final double heightPercent = val == 0 ? 0.05 : (val / maxSymptoms);
      final height = size.height * heightPercent;
      final yOffset = size.height - height;

      final paint = val > 0 ? highlightBarPaint : defaultBarPaint;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xOffset, yOffset, barWidth, height),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

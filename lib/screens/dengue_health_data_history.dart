import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/health_data_provider.dart';
import '../models/health_log.dart';

// --- LOCAL UI CONFIGURATION ---
// This holds your beautiful colors, icons, and slider limits for each tab
class TabUIConfig {
  TabUIConfig({
    required this.title,
    required this.unit,
    required this.icon,
    required this.baseColor,
    required this.gradient,
    required this.sliderMin,
    required this.sliderMax,
    required this.labelMin,
    required this.labelMid,
    required this.labelMax,
  });
  final String title;
  final String unit;
  final IconData icon;
  final Color baseColor;
  final List<Color> gradient;
  final double sliderMin;
  final double sliderMax;
  final String labelMin;
  final String labelMid;
  final String labelMax;
}

class HealthDataHistoryScreen extends StatefulWidget {
  const HealthDataHistoryScreen({super.key, required this.initialTab});
  final String initialTab;

  @override
  State<HealthDataHistoryScreen> createState() =>
      _HealthDataHistoryScreenState();
}

class _HealthDataHistoryScreenState extends State<HealthDataHistoryScreen> {
  late String _activeTab;
  double _sliderValue = 0;
  bool _sliderInitialized = false;
  final TextEditingController _notesController = TextEditingController();
  bool _hasRecordedVoice = false;

  final List<String> _tabs = [
    'Platelets',
    'Fluid Intake',
    'Urine Output',
    'Temperature'
  ];

  final Map<String, TabUIConfig> _uiConfigs = {
    'Platelets': TabUIConfig(
      title: 'Current Platelet Count',
      unit: '/µL',
      icon: Icons.bloodtype,
      baseColor: const Color(0xFFEF4444),
      gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
      sliderMin: 0,
      sliderMax: 400000,
      labelMin: '0',
      labelMid: '200k',
      labelMax: '400k',
    ),
    'Fluid Intake': TabUIConfig(
      title: 'Daily Fluid Intake',
      unit: 'L',
      icon: Icons.local_drink,
      baseColor: const Color(0xFF06B6D4),
      gradient: const [Color(0xFF06B6D4), Color(0xFF0369A1)],
      sliderMin: 0,
      sliderMax: 5,
      labelMin: '0L',
      labelMid: '2.5L',
      labelMax: '5L',
    ),
    'Urine Output': TabUIConfig(
      title: 'Daily Urine Output',
      unit: 'ml',
      icon: Icons.water_drop,
      baseColor: const Color(0xFFEAB308),
      gradient: const [Color(0xFFFBBF24), Color(0xFFD97706)],
      sliderMin: 0,
      sliderMax: 1000,
      labelMin: '0ml',
      labelMid: '500ml',
      labelMax: '1000ml',
    ),
    'Temperature': TabUIConfig(
      title: 'Body Temperature',
      unit: '°F',
      icon: Icons.thermostat,
      baseColor: const Color(0xFFF97316),
      gradient: const [Color(0xFFF97316), Color(0xFFC2410C)],
      sliderMin: 95,
      sliderMax: 105,
      labelMin: '95°F',
      labelMid: '100°F',
      labelMax: '105°F',
    ),
  };

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeSlider(TabUIConfig data) {
    if (!_sliderInitialized) {
      _sliderValue = (data.sliderMin + data.sliderMax) / 2;
      _sliderInitialized = true;
    }
  }

  void _switchTab(String tab, TabUIConfig newData) {
    setState(() {
      _activeTab = tab;
      _sliderValue = (newData.sliderMin + newData.sliderMax) / 2;
    });
  }

  void _saveEntry() {
    String status = 'LOGGED';

    // Auto-calculate simple status logic based on tab
    if (_activeTab == 'Temperature' && _sliderValue >= 100.4) {
      status = 'HIGH FEVER';
    }
    if (_activeTab == 'Temperature' && _sliderValue < 100.4) status = 'STABLE';
    if (_activeTab == 'Platelets' && _sliderValue < 100000) {
      status = 'LOW / ALERT';
    }
    if (_activeTab == 'Platelets' && _sliderValue >= 100000) status = 'STABLE';
    if (_activeTab == 'Fluid Intake' && _sliderValue < 1.5) {
      status = 'LOW INTAKE';
    }
    if (_activeTab == 'Urine Output' && _sliderValue < 300) {
      status = 'LOW OUTPUT';
    }

    context.read<HealthDataProvider>().addEntry(
          _activeTab,
          value1: _sliderValue,
          notes: _notesController.text.trim(),
          hasVoiceNote: _hasRecordedVoice,
          status: status,
        );

    setState(() {
      _notesController.clear();
      _hasRecordedVoice = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$_activeTab saved successfully!'),
        backgroundColor: _uiConfigs[_activeTab]!.baseColor,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthDataProvider>();
    final uiData = _uiConfigs[_activeTab]!;

    _initializeSlider(uiData);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEC5B13)),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text('Health Data History',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: uiData.gradient),
                borderRadius: BorderRadius.circular(12)),
            child: IconButton(
                icon: const Icon(Icons.picture_as_pdf,
                    color: Colors.white, size: 20),
                onPressed: () {}),
          )
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(uiData),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(uiData, provider),
                const SizedBox(height: 20),
                _buildEntryCard(uiData, provider),
                const SizedBox(height: 20),
                _buildTrendChart(uiData, provider),
                const SizedBox(height: 20),
                _buildHistoryList(uiData, provider),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(uiData),
    );
  }

  Widget _buildTabBar(TabUIConfig data) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _tabs.map((tab) {
            final bool isActive = tab == _activeTab;
            return GestureDetector(
              onTap: () => _switchTab(tab, _uiConfigs[tab]!),
              child: Container(
                padding: const EdgeInsets.only(
                    top: 16, bottom: 12, left: 16, right: 16),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color:
                                isActive ? data.baseColor : Colors.transparent,
                            width: 3))),
                child: Text(tab,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive
                            ? data.baseColor
                            : const Color(0xFF64748B))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TabUIConfig uiData, HealthDataProvider provider) {
    final latestLog = provider.getLatestLog(_activeTab);

    String valText = '--';
    if (latestLog != null && latestLog.value1 != null) {
      valText = _activeTab == 'Temperature' || _activeTab == 'Fluid Intake'
          ? latestLog.value1!.toStringAsFixed(1)
          : latestLog.value1!.toInt().toString();
    }

    final bool isAlert = latestLog != null &&
        (latestLog.status.contains('HIGH') || latestLog.status.contains('LOW'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: uiData.baseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(uiData.icon, color: uiData.baseColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(uiData.title,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(valText,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(width: 4),
                    Text(uiData.unit,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 6),
                if (latestLog != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: isAlert
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(latestLog.status,
                            style: TextStyle(
                                color: isAlert
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF059669),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEntryCard(TabUIConfig data, HealthDataProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New $_activeTab Entry',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: data.baseColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  children: [
                    TextSpan(
                        text: _activeTab == 'Platelets' ||
                                _activeTab == 'Urine Output'
                            ? _sliderValue.toInt().toString()
                            : _sliderValue.toStringAsFixed(1)),
                    TextSpan(
                        text: ' ${data.unit}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
                activeTrackColor: data.baseColor,
                inactiveTrackColor: Colors.grey.shade200,
                thumbColor: Colors.white,
                trackHeight: 6),
            child: Slider(
                value: _sliderValue,
                min: data.sliderMin,
                max: data.sliderMax,
                onChanged: (val) => setState(() => _sliderValue = val)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.labelMin,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8))),
                Text(data.labelMid,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8))),
                Text(data.labelMax,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: data.gradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: data.baseColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]),
            child: TextButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save, color: Colors.white, size: 18),
              label: const Text('Save Entry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          const Text('Notes',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
                hintText: 'Add additional notes here...',
                hintStyle:
                    const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _hasRecordedVoice = !_hasRecordedVoice),
            icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: _hasRecordedVoice
                        ? data.baseColor
                        : data.baseColor.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.mic,
                    color: _hasRecordedVoice ? Colors.white : data.baseColor,
                    size: 16)),
            label: Text(
                _hasRecordedVoice ? 'Voice Note Attached' : 'Record Voice Note',
                style: const TextStyle(
                    color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: _hasRecordedVoice
                        ? data.baseColor
                        : const Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          )
        ],
      ),
    );
  }

  Widget _buildTrendChart(TabUIConfig data, HealthDataProvider provider) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    List<double> chartData = provider.getChartData(_activeTab);
    if (chartData.isEmpty) chartData = [data.sliderMin];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-DAY TREND',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: 1)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                        3,
                        (index) => const Divider(
                            color: Color(0xFFF1F5F9), thickness: 1))),
                CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _CurvePainter(
                        color: data.baseColor, dataPoints: chartData)),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final bool isToday = index == 6;
                      return Column(
                        children: [
                          Container(
                              width: isToday ? 10 : 6,
                              height: isToday ? 10 : 6,
                              decoration: BoxDecoration(
                                  color: data.baseColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: isToday
                                      ? [
                                          BoxShadow(
                                              color: data.baseColor
                                                  .withOpacity(0.4),
                                              blurRadius: 4)
                                        ]
                                      : null)),
                          const SizedBox(height: 8),
                          Text(days[index],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isToday
                                      ? data.baseColor
                                      : const Color(0xFF94A3B8),
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      );
                    }),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryList(TabUIConfig data, HealthDataProvider provider) {
    final historyLogs = provider.getLogsByType(_activeTab);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RECENT HISTORY',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1)),
            TextButton(
                onPressed: () {},
                child: const Text('View All',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0D9488),
                        fontWeight: FontWeight.bold)))
          ],
        ),
        if (historyLogs.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No entries yet.',
                      style: TextStyle(color: Colors.grey))))
        else
          ...historyLogs.map((log) {
            final String valText =
                _activeTab == 'Temperature' || _activeTab == 'Fluid Intake'
                    ? log.value1!.toStringAsFixed(1)
                    : log.value1!.toInt().toString();

            return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: data.baseColor.withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: Icon(data.icon,
                                color: data.baseColor, size: 20)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$valText ${data.unit}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A))),
                              Text(
                                  DateFormat('MMM d, h:mm a')
                                      .format(log.timestamp),
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: log.status.contains('HIGH') ||
                                      log.status.contains('LOW')
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(log.status,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: log.status.contains('HIGH') ||
                                          log.status.contains('LOW')
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF059669))),
                        )
                      ],
                    ),
                    if (log.notes.isNotEmpty || log.hasVoiceNote) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFFF1F5F9)),
                      ),
                      if (log.notes.isNotEmpty)
                        Text('Note: "${log.notes}"',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                fontStyle: FontStyle.italic)),
                      if (log.hasVoiceNote)
                        const Row(children: [
                          Icon(Icons.mic, size: 14, color: Color(0xFF20B5A0)),
                          SizedBox(width: 4),
                          Text('Voice note attached',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF20B5A0),
                                  fontWeight: FontWeight.bold))
                        ])
                    ]
                  ],
                ));
          }),
      ],
    );
  }

  Widget _buildBottomNav(TabUIConfig data) {
    // If you are using MainLayout for bottom nav, you can actually return a SizedBox.shrink() here.
    // I am leaving your original code intact just in case you use this screen standalone!
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', false, data),
              _buildNavItem(Icons.assignment, 'Log', true, data),
              _buildNavItem(Icons.location_on_outlined, 'Map', false, data),
              _buildNavItem(Icons.person_outline, 'Profile', false, data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, TabUIConfig data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: isActive ? data.baseColor : const Color(0xFF94A3B8),
            size: 26),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? data.baseColor : const Color(0xFF94A3B8))),
      ],
    );
  }
}

// --- CUSTOM CHART PAINTER ---
class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.color, required this.dataPoints});
  final Color color;
  final List<double> dataPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    final double stepX =
        size.width / (dataPoints.length - 1 == 0 ? 1 : dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final double normalizedY = (dataPoints[i] - minVal) / range;
      final double y =
          size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);
      final double x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final double prevNormalizedY = (dataPoints[i - 1] - minVal) / range;
        final double prevY = size.height -
            (prevNormalizedY * size.height * 0.8 + size.height * 0.1);
        final double prevX = (i - 1) * stepX;

        path.cubicTo(prevX + (stepX / 2), prevY, prevX + (stepX / 2), y, x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) {
    return true;
  }
}

import 'package:flutter/material.dart';

// --- MAIN APP (For testing purposes) ---


// --- DATA MODEL ---
class MetricConfig {
  final String title;
  final String currentValue;
  final String unit;
  final String status;
  final String statusSub;
  final IconData icon;
  final Color baseColor;
  final List<Color> gradient;
  final double sliderMin;
  final double sliderMax;
  final String labelMin;
  final String labelMid;
  final String labelMax;
  final List<Map<String, String>> history;

  MetricConfig({
    required this.title, required this.currentValue, required this.unit,
    required this.status, required this.statusSub, required this.icon,
    required this.baseColor, required this.gradient,
    required this.sliderMin, required this.sliderMax,
    required this.labelMin, required this.labelMid, required this.labelMax,
    required this.history,
  });
}

// --- MAIN SCREEN ---
class HealthDataHistoryScreen extends StatefulWidget {
  final String initialTab;
  const HealthDataHistoryScreen({super.key, required this.initialTab});

  @override
  State<HealthDataHistoryScreen> createState() => _HealthDataHistoryScreenState();
}

class _HealthDataHistoryScreenState extends State<HealthDataHistoryScreen> {
  late String _activeTab;
  double _sliderValue = 0.0;

  final List<String> _tabs = ['Platelets', 'Fluid Intake', 'Urine Output', 'Temperature'];

  // Configuration map for all 4 dashboards
  late final Map<String, MetricConfig> _metricsData;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;

    // Initialize specific data for each tab
    _metricsData = {
      'Platelets': MetricConfig(
        title: 'Current Platelet Count', currentValue: '145,000', unit: '/µL',
        status: 'STABLE', statusSub: 'Ref: 150k - 450k',
        icon: Icons.bloodtype, baseColor: const Color(0xFFEF4444),
        gradient: const [Color(0xFFFCA5A5), Color(0xFFDC2626)],
        sliderMin: 0, sliderMax: 500000,
        labelMin: '0', labelMid: '250k', labelMax: '500k',
        history: [
          {'val': '145,000', 'time': 'Today, 10:30 AM'},
          {'val': '142,000', 'time': 'Today, 08:00 AM'},
          {'val': '138,000', 'time': 'Yesterday, 09:15 PM'},
        ],
      ),
      'Fluid Intake': MetricConfig(
        title: 'Daily Fluid Intake', currentValue: '1.8', unit: 'L',
        status: 'ON TRACK', statusSub: 'Goal: 2.5 L',
        icon: Icons.water_drop, baseColor: const Color(0xFF14B8A6),
        gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
        sliderMin: 0, sliderMax: 5,
        labelMin: '0 L', labelMid: '2.5 L', labelMax: '5 L',
        history: [
          {'val': '0.5 L', 'time': 'Today, 10:30 AM'},
          {'val': '0.3 L', 'time': 'Today, 08:00 AM'},
          {'val': '0.2 L', 'time': 'Yesterday, 09:15 PM'},
        ],
      ),
      'Urine Output': MetricConfig(
        title: 'Daily Urine Output', currentValue: '1.2', unit: 'L',
        status: 'NORMAL', statusSub: 'Goal: 1.5 L',
        icon: Icons.science, baseColor: const Color(0xFFEAB308),
        gradient: const [Color(0xFFFACC15), Color(0xFFCA8A04)],
        sliderMin: 0, sliderMax: 1000,
        labelMin: '0 ml', labelMid: '500 ml', labelMax: '1000 ml',
        history: [
          {'val': '400 ml', 'time': 'Today, 11:15 AM'},
          {'val': '350 ml', 'time': 'Today, 07:45 AM'},
          {'val': '450 ml', 'time': 'Yesterday, 10:30 PM'},
        ],
      ),
      'Temperature': MetricConfig(
        title: 'Latest Temperature', currentValue: '98.6', unit: '°F',
        status: 'NORMAL', statusSub: 'Status: Normal',
        icon: Icons.thermostat, baseColor: const Color(0xFFF97316),
        gradient: const [Color(0xFFFB923C), Color(0xFFEA580C)],
        sliderMin: 95, sliderMax: 105,
        labelMin: '95°F', labelMid: '100°F', labelMax: '105°F',
        history: [
          {'val': '98.6°F', 'time': 'Today, 10:30 AM'},
          {'val': '99.1°F', 'time': 'Today, 08:00 AM'},
          {'val': '98.4°F', 'time': 'Yesterday, 09:15 PM'},
        ],
      ),
    };

    // Set initial slider mid-point
    _sliderValue = (_metricsData[_activeTab]!.sliderMin + _metricsData[_activeTab]!.sliderMax) / 2;
  }

  void _switchTab(String tab) {
    setState(() {
      _activeTab = tab;
      _sliderValue = (_metricsData[tab]!.sliderMin + _metricsData[tab]!.sliderMax) / 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeData = _metricsData[_activeTab]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEC5B13)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Health Data History',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: activeData.gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(activeData),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(activeData),
                const SizedBox(height: 20),
                _buildEntryCard(activeData),
                const SizedBox(height: 20),
                _buildTrendChart(activeData),
                const SizedBox(height: 20),
                _buildHistoryList(activeData),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(activeData),
    );
  }

  Widget _buildTabBar(MetricConfig data) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _tabs.map((tab) {
            bool isActive = tab == _activeTab;
            return GestureDetector(
              onTap: () => _switchTab(tab),
              child: Container(
                padding: const EdgeInsets.only(top: 16, bottom: 12, left: 16, right: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? data.baseColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? data.baseColor : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MetricConfig data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: data.baseColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.baseColor, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(data.currentValue, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 4),
                  Text(data.unit, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: data.baseColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(data.status, style: TextStyle(color: data.baseColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(data.statusSub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEntryCard(MetricConfig data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New $_activeTab Entry', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: data.baseColor, fontWeight: FontWeight.bold, fontSize: 18),
                  children: [
                    TextSpan(text: _sliderValue.toStringAsFixed(1)),
                    TextSpan(text: ' ${data.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
              trackHeight: 6,
            ),
            child: Slider(
              value: _sliderValue,
              min: data.sliderMin,
              max: data.sliderMax,
              onChanged: (val) => setState(() => _sliderValue = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.labelMin, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text(data.labelMid, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text(data.labelMax, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: data.gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: data.baseColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save, color: Colors.white, size: 18),
              label: const Text('Save Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add additional notes here...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: data.baseColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.mic, color: data.baseColor, size: 16),
            ),
            label: const Text('Record Voice Note', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56), // Correctly bounded size
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendChart(MetricConfig data) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-DAY TREND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 1)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                // Mock Grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) => const Divider(color: Color(0xFFF1F5F9), thickness: 1)),
                ),
                // Simple representation of the chart line (Uses Custom Paint for curve)
                CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _CurvePainter(color: data.baseColor),
                ),
                // X-Axis dots
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      bool isToday = index == 6;
                      return Column(
                        children: [
                          Container(
                            width: isToday ? 10 : 6, height: isToday ? 10 : 6,
                            decoration: BoxDecoration(
                              color: data.baseColor, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: isToday ? [BoxShadow(color: data.baseColor.withValues(alpha: 0.4), blurRadius: 4)] : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(days[index], style: TextStyle(fontSize: 10, color: isToday ? data.baseColor : const Color(0xFF94A3B8), fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
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

  Widget _buildHistoryList(MetricConfig data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RECENT HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 1)),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        ...data.history.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: data.baseColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(data.icon, color: data.baseColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['val']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text(item['time']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1))
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildBottomNav(MetricConfig data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
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

  Widget _buildNavItem(IconData icon, String label, bool isActive, MetricConfig data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? data.baseColor : const Color(0xFF94A3B8), size: 26),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? data.baseColor : const Color(0xFF94A3B8))),
      ],
    );
  }
}

// --- CUSTOM CHART PAINTER ---
class _CurvePainter extends CustomPainter {
  final Color color;
  _CurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    var path = Path();
    // A generic smooth curve representation similar to the HTML SVG paths
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.2, size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
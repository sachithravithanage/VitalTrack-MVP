import 'package:flutter/material.dart';


// --- ENUMS FOR DYNAMIC LAYOUTS ---
enum InputType { singleSlider, doubleSlider, checklist }
enum ChartType { curve, bar }

// --- DATA MODEL ---
class MetricConfig {
  final String title;
  final String currentValue;
  final String unit;
  final String status;
  final String statusSub;
  final IconData icon;
  final Color baseColor;
  final Color iconBgColor;
  final List<Color> gradient;

  // Layout flags
  final InputType inputType;
  final ChartType chartType;

  // Slider Data
  final double sliderMin1;
  final double sliderMax1;
  final double? sliderMin2;
  final double? sliderMax2;
  final String labelMin;
  final String labelMid;
  final String labelMax;

  // Checklist Data
  final List<Map<String, dynamic>>? checklistItems;

  final List<Map<String, String>> history;

  MetricConfig({
    required this.title, required this.currentValue, required this.unit,
    required this.status, required this.statusSub, required this.icon,
    required this.baseColor, required this.iconBgColor, required this.gradient,
    this.inputType = InputType.singleSlider,
    this.chartType = ChartType.curve,
    this.sliderMin1 = 0, this.sliderMax1 = 100,
    this.sliderMin2, this.sliderMax2,
    this.labelMin = '', this.labelMid = '', this.labelMax = '',
    this.checklistItems,
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

  // State variables for the different inputs
  double _sliderValue1 = 0.0;
  double _sliderValue2 = 0.0;
  final Map<String, bool> _checklistState = {};

  final List<String> _tabs = ['Blood Pressure', 'Symptoms', 'Urine Output', 'Temperature'];

  late final Map<String, MetricConfig> _metricsData;

  @override
  void initState() {
    super.initState();
    // Fallback to first tab if the passed tab isn't in our list
    _activeTab = _tabs.contains(widget.initialTab) ? widget.initialTab : _tabs[0];

    _metricsData = {
      'Blood Pressure': MetricConfig(
        title: 'Last Blood Pressure', currentValue: '120/80', unit: 'mmHg',
        status: 'NORMAL', statusSub: '',
        icon: Icons.favorite_border, baseColor: const Color(0xFFEC5B13), iconBgColor: const Color(0xFFFEF2F2),
        gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)], // Save button teal
        inputType: InputType.doubleSlider, chartType: ChartType.bar,
        sliderMin1: 80, sliderMax1: 200, // Systolic
        sliderMin2: 40, sliderMax2: 130, // Diastolic
        history: [
          {'val': '118/79 mmHg', 'time': 'Today, 08:30 AM', 'status': 'Normal', 'statusColor': 'green'},
          {'val': '125/84 mmHg', 'time': 'Yesterday, 09:15 PM', 'status': 'Elevated', 'statusColor': 'orange'},
          {'val': '115/75 mmHg', 'time': 'Oct 24, 07:00 AM', 'status': 'Normal', 'statusColor': 'green'},
        ],
      ),
      'Symptoms': MetricConfig(
        title: 'Today\'s Symptoms', currentValue: '3/5', unit: 'Logged',
        status: 'STABLE', statusSub: '',
        icon: Icons.medical_services_outlined, baseColor: const Color(0xFF3B82F6), iconBgColor: const Color(0xFFFFF1F2),
        gradient: const [Color(0xFF14B8A6), Color(0xFF1D4ED8)],
        inputType: InputType.checklist, chartType: ChartType.bar,
        checklistItems: [
          {'name': 'Yellow Eyes', 'icon': Icons.visibility_outlined},
          {'name': 'Muscle Pain', 'icon': Icons.accessibility_new},
          {'name': 'Vomiting', 'icon': Icons.sick_outlined},
          {'name': 'Headache', 'icon': Icons.psychology_outlined},
          {'name': 'Joint Pain', 'icon': Icons.sports_gymnastics},
        ],
        history: [
          {'val': '3 Symptoms Logged', 'time': 'Yesterday, 8:45 PM'},
          {'val': '1 Symptom Logged', 'time': 'Oct 24, 9:15 AM'},
        ],
      ),
      'Urine Output': MetricConfig(
        title: 'Daily Urine Output', currentValue: '1.2', unit: 'L',
        status: 'NORMAL', statusSub: 'Goal: 1.5 L',
        icon: Icons.science_outlined, baseColor: const Color(0xFFEAB308), iconBgColor: const Color(0xFFFEFCE8),
        gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
        inputType: InputType.singleSlider, chartType: ChartType.curve,
        sliderMin1: 0, sliderMax1: 1500,
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
        icon: Icons.thermostat, baseColor: const Color(0xFFF97316), iconBgColor: const Color(0xFFFFF7ED),
        gradient: const [Color(0xFF2DD4BF), Color(0xFF0E7490)],
        inputType: InputType.singleSlider, chartType: ChartType.curve,
        sliderMin1: 95, sliderMax1: 105,
        labelMin: '95°F', labelMid: '100°F', labelMax: '105°F',
        history: [
          {'val': '98.6°F', 'time': 'Today, 10:30 AM'},
          {'val': '99.1°F', 'time': 'Today, 08:00 AM'},
          {'val': '98.4°F', 'time': 'Yesterday, 09:15 PM'},
        ],
      ),
    };

    _initTabState(_activeTab);
  }

  void _initTabState(String tab) {
    final data = _metricsData[tab]!;
    _sliderValue1 = (data.sliderMin1 + data.sliderMax1) / 2;
    if (data.inputType == InputType.doubleSlider) {
      _sliderValue2 = (data.sliderMin2! + data.sliderMax2!) / 2;
    } else if (data.inputType == InputType.checklist) {
      for (var item in data.checklistItems!) {
        // Pre-check some items to match UI mockup
        _checklistState[item['name']] = item['name'] == 'Muscle Pain' || item['name'] == 'Headache' || item['name'] == 'Joint Pain';
      }
    }
  }

  void _switchTab(String tab) {
    setState(() {
      _activeTab = tab;
      _initTabState(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeData = _metricsData[_activeTab]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF14B8A6), size: 24),
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
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(activeData),
                const SizedBox(height: 16),
                _buildEntryCard(activeData),
                const SizedBox(height: 16),
                _buildTrendChart(activeData),
                const SizedBox(height: 16),
                _buildHistoryList(activeData),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
                padding: const EdgeInsets.only(top: 16, bottom: 12, left: 12, right: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: isActive ? const Color(0xFF14B8A6) : Colors.transparent, width: 3),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? const Color(0xFF14B8A6) : const Color(0xFF64748B),
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: data.iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(data.icon, color: data.baseColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(data.currentValue, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: data.inputType == InputType.doubleSlider ? data.baseColor : const Color(0xFF0F172A))),
                    const SizedBox(width: 4),
                    Text(data.unit, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF14B8A6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(data.status, style: const TextStyle(color: Color(0xFF14B8A6), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    if (data.statusSub.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(child: Text(data.statusSub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))),
                    ]
                  ],
                )
              ],
            ),
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.inputType == InputType.checklist ? 'New Symptom Entry' : 'New Entry', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              if (data.inputType == InputType.singleSlider)
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: data.baseColor, fontWeight: FontWeight.bold, fontSize: 18),
                    children: [
                      TextSpan(text: _sliderValue1.toStringAsFixed(1)),
                      TextSpan(text: ' ${data.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // --- DYNAMIC INPUT SECTION ---
          if (data.inputType == InputType.singleSlider)
            _buildSingleSlider(data),
          if (data.inputType == InputType.doubleSlider)
            _buildDoubleSlider(data),
          if (data.inputType == InputType.checklist)
            _buildChecklist(data),

          const SizedBox(height: 20),

          // Notes
          const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add additional notes here...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 16),

          // Voice Note & Save
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.mic, color: Color(0xFF14B8A6), size: 20),
            label: const Text('Record Voice Note', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Color(0xFFE2E8F0), style: BorderStyle.solid, width: 2), // Dashed mockup fallback
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: data.gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: data.gradient.first.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: TextButton(
              onPressed: () {},
              child: const Text('Save Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // Layout 1: Single Slider
  Widget _buildSingleSlider(MetricConfig data) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF14B8A6), inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white, trackHeight: 6,
          ),
          child: Slider(
            value: _sliderValue1, min: data.sliderMin1, max: data.sliderMax1,
            onChanged: (val) => setState(() => _sliderValue1 = val),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.labelMin, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            Text(data.labelMid, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            Text(data.labelMax, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  // Layout 2: Double Slider (Blood Pressure)
  Widget _buildDoubleSlider(MetricConfig data) {
    return Column(
      children: [
        _buildBPSliderRow('Systolic (Top)', _sliderValue1, data.sliderMin1, data.sliderMax1, (v) => setState(() => _sliderValue1 = v)),
        const SizedBox(height: 16),
        _buildBPSliderRow('Diastolic (Bottom)', _sliderValue2, data.sliderMin2!, data.sliderMax2!, (v) => setState(() => _sliderValue2 = v)),
      ],
    );
  }

  Widget _buildBPSliderRow(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text('${val.toInt()} mmHg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6))),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.grey.shade300, inactiveTrackColor: Colors.grey.shade200,
            thumbColor: const Color(0xFF14B8A6), trackHeight: 4,
          ),
          child: Slider(value: val, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  // Layout 3: Checklist (Symptoms)
  Widget _buildChecklist(MetricConfig data) {
    return Column(
      children: data.checklistItems!.map((item) {
        bool isChecked = _checklistState[item['name']] ?? false;
        return GestureDetector(
          onTap: () => setState(() => _checklistState[item['name']] = !isChecked),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
              color: isChecked ? Colors.grey.shade50 : Colors.white,
            ),
            child: Row(
              children: [
                Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? const Color(0xFF14B8A6) : Colors.grey.shade300),
                const SizedBox(width: 12),
                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                Icon(item['icon'], color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendChart(MetricConfig data) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('7-DAY TREND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 1)),
              if (data.inputType == InputType.doubleSlider)
                const Text('Avg: 118/79', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                // DYNAMIC CHART RENDERING
                if (data.chartType == ChartType.curve)
                  CustomPaint(
                    size: const Size(double.infinity, 100),
                    painter: _CurvePainter(color: data.baseColor),
                  ),
                if (data.chartType == ChartType.bar)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBar(0.6, data.baseColor.withValues(alpha: 0.3)),
                      _buildBar(0.8, data.baseColor.withValues(alpha: 0.4)),
                      _buildBar(0.5, data.baseColor.withValues(alpha: 0.5)),
                      _buildBar(0.7, data.baseColor.withValues(alpha: 0.6)),
                      _buildBar(0.9, data.baseColor.withValues(alpha: 0.4)),
                      _buildBar(0.8, data.baseColor),
                      _buildBar(0.6, data.baseColor),
                    ],
                  ),

                // X-Axis Labels
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      return Text(days[index], style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)));
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

  Widget _buildBar(double heightPercent, Color color) {
    return Container(
      width: 30,
      height: 100 * heightPercent,
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
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
              child: const Text('View All', style: TextStyle(fontSize: 10, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        ...data.history.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: data.iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(data.icon, color: data.baseColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['val']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    Text(item['time']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (item.containsKey('status'))
                Text(
                    item['status']!,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: item['statusColor'] == 'green' ? Colors.green : Colors.orange
                    )
                )
              else
                const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1))
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBottomNav() {
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
              _buildNavItem(Icons.home_outlined, 'Home', false, () => Navigator.pop(context)),
              _buildNavItem(Icons.assignment, 'Log', true, () {}),
              _buildNavItem(Icons.location_on_outlined, 'Map', false, () {}),
              _buildNavItem(Icons.person_outline, 'Profile', false, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF14B8A6) : const Color(0xFF94A3B8), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFF14B8A6) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// --- CUSTOM CHART PAINTER (For Curve) ---
class _CurvePainter extends CustomPainter {
  final Color color;
  _CurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    var path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width * 0.7, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.25, size.width, size.height * 0.4);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lepto_health_data_provider.dart'; // Ensure this matches your provider filename

class LeptoHealthDataHistoryScreen extends StatefulWidget {
  final String initialTab;
  const LeptoHealthDataHistoryScreen({super.key, required this.initialTab});

  @override
  State<LeptoHealthDataHistoryScreen> createState() => _LeptoHealthDataHistoryScreenState();
}

class _LeptoHealthDataHistoryScreenState extends State<LeptoHealthDataHistoryScreen> {
  late String _activeTab;

  // Local UI state for inputs
  double _sliderValue1 = 0.0;
  double _sliderValue2 = 0.0;
  final Map<String, bool> _checklistState = {};
  bool _stateInitialized = false;

  final List<String> _tabs = ['Blood Pressure', 'Symptoms', 'Urine Output', 'Temperature'];

  @override
  void initState() {
    super.initState();
    _activeTab = _tabs.contains(widget.initialTab) ? widget.initialTab : _tabs[0];
  }

  // Syncs the local UI sliders/checkboxes with the current data in the Provider
  void _initTabState(LeptoMetricConfig data) {
    if (!_stateInitialized) {
      _sliderValue1 = (data.sliderMin1 + data.sliderMax1) / 2;
      if (data.inputType == InputType.doubleSlider) {
        _sliderValue2 = (data.sliderMin2! + data.sliderMax2!) / 2;
      } else if (data.inputType == InputType.checklist) {
        for (var item in data.checklistItems!) {
          // Initialize checkboxes to false or keep existing state
          _checklistState[item['name']] = _checklistState[item['name']] ?? false;
        }
      }
      _stateInitialized = true;
    }
  }

  void _switchTab(String tab, LeptoMetricConfig newData) {
    setState(() {
      _activeTab = tab;
      _stateInitialized = false;
      _initTabState(newData);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the Lepto Provider for changes
    final provider = context.watch<LeptoHealthDataProvider>();
    final activeData = provider.metricsData[_activeTab]!;

    _initTabState(activeData);

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
        title: const Text('Health Data History', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF14B8A6), size: 24),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(activeData, provider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(activeData),
                const SizedBox(height: 16),
                _buildEntryCard(activeData, provider),
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

  Widget _buildTabBar(LeptoMetricConfig data, LeptoHealthDataProvider provider) {
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
              onTap: () => _switchTab(tab, provider.metricsData[tab]!),
              child: Container(
                padding: const EdgeInsets.only(top: 16, bottom: 12, left: 12, right: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF14B8A6) : Colors.transparent, width: 3)),
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

  Widget _buildSummaryCard(LeptoMetricConfig data) {
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

  Widget _buildEntryCard(LeptoMetricConfig data, LeptoHealthDataProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.inputType == InputType.checklist ? 'New Symptom Entry' : 'New Entry', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              if (data.inputType == InputType.singleSlider)
                Text('${_sliderValue1.toStringAsFixed(1)} ${data.unit}', style: TextStyle(color: data.baseColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),

          if (data.inputType == InputType.singleSlider) _buildSingleSlider(data),
          if (data.inputType == InputType.doubleSlider) _buildDoubleSlider(data),
          if (data.inputType == InputType.checklist) _buildChecklist(data),

          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: data.gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                // Determine what to save based on InputType
                if (data.inputType == InputType.singleSlider) {
                  provider.addEntry(_activeTab, _sliderValue1);
                } else if (data.inputType == InputType.doubleSlider) {
                  provider.addEntry(_activeTab, _sliderValue1, _sliderValue2);
                } else if (data.inputType == InputType.checklist) {
                  List<String> activeSymptoms = _checklistState.entries.where((e) => e.value).map((e) => e.key).toList();
                  provider.addEntry(_activeTab, activeSymptoms);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_activeTab entry saved!'), behavior: SnackBarBehavior.floating));
              },
              child: const Text('Save Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSlider(LeptoMetricConfig data) {
    return Column(
      children: [
        Slider(
          value: _sliderValue1, min: data.sliderMin1, max: data.sliderMax1,
          activeColor: const Color(0xFF14B8A6),
          onChanged: (val) => setState(() => _sliderValue1 = val),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.labelMin, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text(data.labelMax, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _buildDoubleSlider(LeptoMetricConfig data) {
    return Column(
      children: [
        _buildBPSliderRow('Systolic', _sliderValue1, data.sliderMin1, data.sliderMax1, (v) => setState(() => _sliderValue1 = v)),
        const SizedBox(height: 16),
        _buildBPSliderRow('Diastolic', _sliderValue2, data.sliderMin2!, data.sliderMax2!, (v) => setState(() => _sliderValue2 = v)),
      ],
    );
  }

  Widget _buildBPSliderRow(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${val.toInt()} mmHg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6))),
          ],
        ),
        Slider(value: val, min: min, max: max, activeColor: const Color(0xFF14B8A6), onChanged: onChanged),
      ],
    );
  }

  Widget _buildChecklist(LeptoMetricConfig data) {
    return Column(
      children: data.checklistItems!.map((item) {
        bool isChecked = _checklistState[item['name']] ?? false;
        return CheckboxListTile(
          title: Text(item['name'], style: const TextStyle(fontSize: 14)),
          secondary: Icon(item['icon'], size: 20),
          value: isChecked,
          activeColor: const Color(0xFF14B8A6),
          onChanged: (bool? val) => setState(() => _checklistState[item['name']] = val!),
        );
      }).toList(),
    );
  }

  Widget _buildTrendChart(LeptoMetricConfig data) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-DAY TREND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                if (data.chartType == ChartType.curve)
                  CustomPaint(size: const Size(double.infinity, 100), painter: _CurvePainter(color: data.baseColor, dataPoints: data.chartData)),
                if (data.chartType == ChartType.bar)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: data.chartData.map((val) {
                      // Normalize bar height based on metric type
                      double percent = (data.inputType == InputType.checklist) ? val / 5.0 : (val - 80) / 120;
                      return _buildBar(percent.clamp(0.1, 1.0), data.baseColor);
                    }).toList(),
                  ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) => Text(days[i], style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)))),
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
      width: 25, height: 100 * heightPercent,
      decoration: BoxDecoration(color: color.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildHistoryList(LeptoMetricConfig data) {
    return Column(
      children: [
        const Text('RECENT HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...data.history.map((item) => ListTile(
          leading: Icon(data.icon, color: data.baseColor),
          title: Text(item['val']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item['time']!),
          trailing: item.containsKey('status')
              ? Text(item['status']!, style: TextStyle(color: item['statusColor'] == 'green' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))
              : const Icon(Icons.chevron_right),
        )),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: const Color(0xFF14B8A6),
      unselectedItemColor: Colors.grey,
      currentIndex: 1,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Log'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  final Color color;
  final List<double> dataPoints;
  _CurvePainter({required this.color, required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    var paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    var path = Path();

    double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);
    double stepX = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      double y = size.height - ((dataPoints[i] - minVal) / range * size.height * 0.8 + 10);
      double x = i * stepX;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
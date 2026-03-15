import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedDisease = "Dengue";
  int _currentNavIndex = 1;

  // Search and selection state
  int _selectedDistrictIndex = -1;
  bool _isViewAll = false;
  final TextEditingController _searchController = TextEditingController();

  static const Color primary = Color(0xFF26A69A);
  static const Color backgroundLight = Color(0xFFF6F8F8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  final List<String> _districtsList = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
    'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
    'Monaragala', 'Ratnapura', 'Kegalle'
  ];

  void _selectDistrictByName(String name) {
    final data = _getDistrictData();
    int foundIndex = data.indexWhere(
            (d) => d.district.toLowerCase() == name.toLowerCase()
    );

    setState(() {
      _selectedDistrictIndex = foundIndex;
      _isViewAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          // Added Row here to include the icon before the title
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/appicon.png',
                height: 30, // Adjusted for standard AppBar height
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
              ),
              const SizedBox(width: 10),
              const Text(
                "VitalTrack",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, color: Colors.black)
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AUTOCOMPLETE SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                    return _districtsList.where((String option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _searchController.text = selection;
                    _selectDistrictByName(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: "Search for a District in Sri Lanka...",
                        prefixIcon: Icon(Icons.search, color: Colors.black54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildChip("Dengue", selectedDisease == "Dengue"),
                  _buildChip("Leptospirosis", selectedDisease == "Leptospirosis"),
                ],
              ),
            ),

            // Map Section with Legend
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: HeatmapCard(
                disease: selectedDisease,
                selectedIndex: _selectedDistrictIndex,
                onDistrictSelected: (index) {
                  setState(() {
                    _selectedDistrictIndex = index;
                    _isViewAll = false;
                  });
                },
              ),
            ),

            // Density Details Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Density Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: () => setState(() {
                        _isViewAll = !_isViewAll;
                        _selectedDistrictIndex = -1;
                      }),
                      child: Text(_isViewAll ? "Show Less" : "View All",
                          style: const TextStyle(color: primary, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
            ),

            ..._buildDynamicCards(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- UI HELPER METHODS ---

  List<Widget> _buildDynamicCards() {
    final data = _getDistrictData();
    List<DistrictData> displayedData;

    if (_selectedDistrictIndex != -1 && _selectedDistrictIndex < data.length) {
      displayedData = [data[_selectedDistrictIndex]];
    } else if (_isViewAll) {
      displayedData = List.from(data);
    } else {
      List<DistrictData> sorted = List.from(data);
      sorted.sort((a, b) => (selectedDisease == "Dengue" ? b.dengueCases : b.leptoCases)
          .compareTo(selectedDisease == "Dengue" ? a.dengueCases : a.leptoCases));
      displayedData = sorted.take(3).toList();
    }

    return displayedData.map((d) {
      double cases = (selectedDisease == "Dengue" ? d.dengueCases : d.leptoCases);
      return _buildDistrictCard(
          d.district,
          "${cases.toInt()} reported cases",
          cases > 1000 ? "+12%" : "-5%",
          cases > 1000 ? Colors.red : Colors.orange,
          cases > 1000 ? Icons.trending_up : Icons.trending_down
      );
    }).toList();
  }

  List<DistrictData> _getDistrictData() {
    return const [
      DistrictData('Colombo', 2800, 900), DistrictData('Gampaha', 1500, 250),
      DistrictData('Kalutara', 800, 400), DistrictData('Kandy', 950, 300),
      DistrictData('Matale', 400, 550), DistrictData('Nuwara Eliya', 200, 700),
      DistrictData('Galle', 300, 1100), DistrictData('Matara', 350, 350),
      DistrictData('Hambantota', 150, 500), DistrictData('Jaffna', 600, 450),
      DistrictData('Kilinochchi', 100, 60), DistrictData('Mannar', 80, 120),
      DistrictData('Vavuniya', 120, 80), DistrictData('Mullaitivu', 60, 100),
      DistrictData('Batticaloa', 450, 600), DistrictData('Ampara', 500, 150),
      DistrictData('Trincomalee', 350, 350), DistrictData('Kurunegala', 1100, 300),
      DistrictData('Puttalam', 700, 200), DistrictData('Anuradhapura', 550, 400),
      DistrictData('Polonnaruwa', 300, 950), DistrictData('Badulla', 400, 800),
      DistrictData('Monaragala', 250, 1500), DistrictData('Ratnapura', 900, 2800),
      DistrictData('Kegalle', 850, 850),
    ];
  }

  Widget _buildChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool s) => s ? setState(() { selectedDisease = label; _selectedDistrictIndex = -1; }) : null,
        selectedColor: primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildDistrictCard(String title, String subtitle, String stats, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surfaceWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        Text(stats, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(height: 80,
        decoration: const BoxDecoration(color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navIcon(Icons.home_outlined, "Home", 0),
              _navIcon(Icons.description_outlined, "Log", 1),
              _navIcon(Icons.location_on, "Map", 2),
              _navIcon(Icons.person_outline, "Profile", 3)
            ]
        )
    );
  }

  Widget _navIcon(IconData icon, String label, int index) {
    bool isSel = _currentNavIndex == index;
    return GestureDetector(onTap: () => setState(() => _currentNavIndex = index), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSel ? primary : Colors.grey), Text(label, style: TextStyle(color: isSel ? primary : Colors.grey, fontSize: 10))]));
  }
}

// --- HEATMAP CARD WITH LEGEND AT TOP RIGHT ---

class HeatmapCard extends StatefulWidget {
  final String disease;
  final int selectedIndex;
  final ValueChanged<int> onDistrictSelected;
  const HeatmapCard({super.key, required this.disease, required this.selectedIndex, required this.onDistrictSelected});

  @override
  State<HeatmapCard> createState() => _HeatmapCardState();
}

class _HeatmapCardState extends State<HeatmapCard> {
  late List<DistrictData> _data;
  late MapShapeSource _shapeSource;

  @override
  void initState() {
    _data = _getStaticDistrictData();
    _updateSource();
    super.initState();
  }

  @override
  void didUpdateWidget(HeatmapCard oldWidget) {
    if (oldWidget.disease != widget.disease) _updateSource();
    super.didUpdateWidget(oldWidget);
  }

  void _updateSource() {
    setState(() {
      _shapeSource = MapShapeSource.asset(
        'assets/srilanka_25_districts.json',
        shapeDataField: 'shapeName',
        dataCount: _data.length,
        primaryValueMapper: (int index) => _data[index].district,
        shapeColorValueMapper: (int index) => widget.disease == "Dengue" ? _data[index].dengueCases : _data[index].leptoCases,
        shapeColorMappers: widget.disease == "Dengue" ? _getDengueMappers() : _getLeptoMappers(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("${widget.disease} Distribution Map", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SfMaps(
                    layers: [
                      MapShapeLayer(
                        source: _shapeSource,
                        showDataLabels: true,
                        selectedIndex: widget.selectedIndex,
                        onSelectionChanged: (int index) => widget.onDistrictSelected(index),
                        selectionSettings: const MapSelectionSettings(color: Color(0xFF26A69A), strokeColor: Colors.white, strokeWidth: 2),
                        dataLabelSettings: const MapDataLabelSettings(textStyle: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // VERTICAL LEGEND AT TOP RIGHT
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Changed to start for Top Right
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.disease == "Dengue" ? _buildDengueLegend() : _buildLeptoLegend(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }

  List<Widget> _buildDengueLegend() {
    return [
      _buildLegendItem(const Color(0xFFFEE5D9), "< 500"),
      _buildLegendItem(const Color(0xFFFB6A4A), "501-1500"),
      _buildLegendItem(const Color(0xFFA50F15), "> 1500"),
    ];
  }

  List<Widget> _buildLeptoLegend() {
    return [
      _buildLegendItem(const Color(0xFFFEE5D9), "< 500"),
      _buildLegendItem(const Color(0xFFA0BCD8), "501-1500"),
      _buildLegendItem(const Color(0xFF4175B5), "> 1500"),
    ];
  }

  List<DistrictData> _getStaticDistrictData() {
    return const [
      DistrictData('Colombo', 2800, 900), DistrictData('Gampaha', 1500, 250), DistrictData('Kalutara', 800, 400), DistrictData('Kandy', 950, 300), DistrictData('Matale', 400, 550), DistrictData('Nuwara Eliya', 200, 700), DistrictData('Galle', 300, 1100), DistrictData('Matara', 350, 350), DistrictData('Hambantota', 150, 500), DistrictData('Jaffna', 600, 450), DistrictData('Kilinochchi', 100, 60), DistrictData('Mannar', 80, 120), DistrictData('Vavuniya', 120, 80), DistrictData('Mullaitivu', 60, 100), DistrictData('Batticaloa', 450, 600), DistrictData('Ampara', 500, 150), DistrictData('Trincomalee', 350, 350), DistrictData('Kurunegala', 1100, 300), DistrictData('Puttalam', 700, 200), DistrictData('Anuradhapura', 550, 400), DistrictData('Polonnaruwa', 300, 950), DistrictData('Badulla', 400, 800), DistrictData('Monaragala', 250, 1500), DistrictData('Ratnapura', 900, 2800), DistrictData('Kegalle', 850, 850),
    ];
  }

  List<MapColorMapper> _getLeptoMappers() => [
    MapColorMapper(from: 0, to: 500, color: const Color(0xFFFEE5D9)),
    MapColorMapper(from: 501, to: 1500, color: const Color(0xFFA0BCD8)),
    MapColorMapper(from: 1501, to: 10000, color: const Color(0xFF4175B5)),
  ];

  List<MapColorMapper> _getDengueMappers() => [
    MapColorMapper(from: 0, to: 500, color: const Color(0xFFFEE5D9)),
    MapColorMapper(from: 501, to: 1500, color: const Color(0xFFFB6A4A)),
    MapColorMapper(from: 1501, to: 10000, color: const Color(0xFFA50F15))
  ];
}

class DistrictData {
  const DistrictData(this.district, this.dengueCases, this.leptoCases);
  final String district;
  final double dengueCases;
  final double leptoCases;
}
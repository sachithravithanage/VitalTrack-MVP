import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import 'heatmap_setup.dart';
import '../services/index.dart';

class HotspotMapScreen extends StatefulWidget {
  const HotspotMapScreen({super.key, required this.forCaregiverPatientData});

  final bool forCaregiverPatientData;

  @override
  State<HotspotMapScreen> createState() => _HotspotMapScreenState();
}

class _HotspotMapScreenState extends State<HotspotMapScreen> {
  String get selectedDisease =>
      _selectedMapDisease == DiseaseType.ratFever ? "Rat Fever" : "Dengue";

  // Search and selection state
  int _selectedDistrictIndex = -1;
  bool _isViewAll = false;
  final TextEditingController _searchController = TextEditingController();

  static const Color primary = Color(0xFF1E5AA8);
  static const Color backgroundLight = Color(0xFFF6F8F8);
  static const Color surfaceWhite = Color(0xFFEFF4FC);

  bool _loadingMap = false;
  bool _loadingInitialSetup = true;
  bool _showInitialSetup = false;
  bool _didInitialLoad = false;
  DiseaseType _selectedMapDisease = DiseaseType.dengue;
  String? _selectedPatientId;
  DiseaseType _setupDisease = DiseaseType.dengue;
  String? _setupDistrict;

  static const List<String> _districtDisplayOrder = <String>[
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  static const bool _useDummyHeatmapData = true;

  static const Map<String, double> _dummyDistrictScores = <String, double>{
    'colombo': 5.2,
    'gampaha': 3.4,
    'kalutara': 2.1,
    'kandy': 4.7,
    'matale': 1.2,
    'nuwara eliya': 0.8,
    'galle': 2.9,
    'matara': 1.6,
    'hambantota': 3.8,
    'jaffna': 1.4,
    'kilinochchi': 2.3,
    'mannar': 0.9,
    'vavuniya': 1.9,
    'mullaitivu': 2.6,
    'batticaloa': 4.1,
    'ampara': 6.0,
    'trincomalee': 3.0,
    'kurunegala': 4.6,
    'puttalam': 2.7,
    'anuradhapura': 3.3,
    'polonnaruwa': 4.4,
    'badulla': 2.5,
    'monaragala': 5.8,
    'ratnapura': 3.7,
    'kegalle': 2.8,
  };

  final List<String> _districtsList = _districtDisplayOrder;

  String _heatmapSetupKey(String patientId) =>
      'heatmap_setup_completed_$patientId';

  Future<void> _bootstrapInitialSetup() async {
    final AppState app = AppScope.of(context);
    final currentUser = app.currentUser;

    if (currentUser == null) {
      if (mounted) {
        setState(() => _loadingInitialSetup = false);
      }
      return;
    }

    final bool shouldPromptSetup =
        currentUser.role == UserRole.patient && !widget.forCaregiverPatientData;

    if (!shouldPromptSetup) {
      if (mounted) {
        setState(() {
          _showInitialSetup = false;
          _loadingInitialSetup = false;
        });
      }
      return;
    }

    final saved = storageService.getString(_heatmapSetupKey(currentUser.id));

    if (saved == null || saved.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _showInitialSetup = true;
          _loadingInitialSetup = false;
          _setupDisease = _selectedMapDisease;
          _setupDistrict = _districtDisplayOrder.first;
        });
      }
      return;
    }

    try {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      final diseaseRaw = (decoded['disease'] ?? 'dengue').toString();
      final districtRaw = (decoded['district'] ?? '').toString();

      _selectedMapDisease = diseaseRaw == 'ratFever'
          ? DiseaseType.ratFever
          : DiseaseType.dengue;

      if (_districtDisplayOrder.contains(districtRaw)) {
        _setupDistrict = districtRaw;
      }
    } catch (_) {
      _showInitialSetup = true;
      _setupDistrict = _districtDisplayOrder.first;
    }

    if (mounted) {
      setState(() {
        _showInitialSetup = false;
        _loadingInitialSetup = false;
      });
    }
  }

  Future<void> _completeInitialSetup(AppState app) async {
    final currentUser = app.currentUser;
    if (currentUser == null || _setupDistrict == null) {
      return;
    }

    setState(() {
      _loadingMap = true;
      _selectedMapDisease = _setupDisease;
      _selectedDistrictIndex = -1;
      _searchController.clear();
    });

    await storageService.saveString(
      _heatmapSetupKey(currentUser.id),
      jsonEncode(<String, String>{
        'disease': _setupDisease == DiseaseType.ratFever
            ? 'ratFever'
            : 'dengue',
        'district': _setupDistrict!,
      }),
    );

    try {
      await app.loadRegionalHeatmapData(disease: _selectedDiseaseApiValue());
    } catch (_) {
      // If loading fails, user should still proceed to map.
    }

    if (mounted) {
      setState(() {
        _showInitialSetup = false;
        _loadingMap = false;
      });
    }
  }

  void _selectDistrictByName(String name) {
    final data = _getDistrictData();
    int foundIndex = data.indexWhere(
      (d) => d.district.toLowerCase() == name.toLowerCase(),
    );

    setState(() {
      _selectedDistrictIndex = foundIndex;
      _isViewAll = false;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) {
      return;
    }
    _didInitialLoad = true;
    unawaited(_bootstrapInitialSetup().then((_) => _loadMapData()));
  }

  Future<void> _loadMapData() async {
    setState(() => _loadingMap = true);
    final AppState app = AppScope.of(context);

    try {
      if (widget.forCaregiverPatientData) {
        await app.loadCaregiverPatients();
        if (!mounted) return;
        final patients = app.caregiverPatients(app.currentUser!.id);
        if (patients.isNotEmpty) {
          _selectedPatientId ??= patients.first.id;
          _selectedMapDisease = patients.first.disease;
          await app.loadPatientHotspots(_selectedPatientId!);
        } else if (app.hasRole(UserRole.patient)) {
          await app.loadPatientHotspots(app.currentUser!.id);
        }
      } else {
        await app.loadPatientHotspots(app.currentUser!.id);
      }

      await app.loadRegionalHeatmapData(disease: _selectedDiseaseApiValue());
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingMap = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _selectedDiseaseApiValue() {
    return _selectedMapDisease == DiseaseType.ratFever ? 'ratFever' : 'dengue';
  }

  List<DistrictHeatData> _shapeDataFromRegions(
    List<HotspotRegionSummary> regions,
  ) {
    if (_useDummyHeatmapData) {
      return _districtDisplayOrder.map((districtName) {
        final key = districtName.toLowerCase();
        return DistrictHeatData(
          district: districtName,
          score: _dummyDistrictScores[key] ?? 0,
        );
      }).toList();
    }

    final Map<String, HotspotRegionSummary> byDistrict =
        <String, HotspotRegionSummary>{
          for (final region in regions) region.district.toLowerCase(): region,
        };

    return _districtDisplayOrder.map((districtName) {
      final key = districtName.toLowerCase();
      final region = byDistrict[key];
      return DistrictHeatData(
        district: districtName,
        score: region?.score ?? 0,
      );
    }).toList();
  }

  List<MapColorMapper> _shapeMappers() {
    if (_selectedMapDisease == DiseaseType.ratFever) {
      return <MapColorMapper>[
        MapColorMapper(from: 0, to: 1.5, color: const Color(0xFFFEE5D9)),
        MapColorMapper(from: 1.51, to: 4, color: const Color(0xFFA0BCD8)),
        MapColorMapper(from: 4.01, to: 100, color: const Color(0xFF4175B5)),
      ];
    }

    return <MapColorMapper>[
      MapColorMapper(from: 0, to: 1.5, color: const Color(0xFFFEE5D9)),
      MapColorMapper(from: 1.51, to: 4, color: const Color(0xFFFB6A4A)),
      MapColorMapper(from: 4.01, to: 100, color: const Color(0xFFA50F15)),
    ];
  }

  MapShapeSource _buildShapeSource(List<DistrictHeatData> shapeData) {
    return MapShapeSource.asset(
      'assets/srilanka_25_districts.json',
      shapeDataField: 'shapeName',
      dataCount: shapeData.length,
      primaryValueMapper: (int index) => shapeData[index].district,
      shapeColorValueMapper: (int index) => shapeData[index].score,
      shapeColorMappers: _shapeMappers(),
    );
  }

  List<Widget> _buildVerticalMapLegend() {
    if (_selectedMapDisease == DiseaseType.ratFever) {
      return <Widget>[
        _buildSmallLegendItem(const Color(0xFFFEE5D9), '< 500'),
        _buildSmallLegendItem(const Color(0xFFA0BCD8), '501-1500'),
        _buildSmallLegendItem(const Color(0xFF4175B5), '> 1500'),
      ];
    }

    return <Widget>[
      _buildSmallLegendItem(const Color(0xFFFEE5D9), '< 500'),
      _buildSmallLegendItem(const Color(0xFFFB6A4A), '501-1500'),
      _buildSmallLegendItem(const Color(0xFFA50F15), '> 1500'),
    ];
  }

  Widget _buildSmallLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _switchMapDisease(AppState app, DiseaseType disease) async {
    if (_selectedMapDisease == disease) {
      return;
    }
    setState(() {
      _selectedMapDisease = disease;
      _loadingMap = true;
    });

    try {
      await app.loadRegionalHeatmapData(disease: _selectedDiseaseApiValue());
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingMap = false);
    }
  }

  double _dummyScoreToCases(double score) {
    return (score * 500).roundToDouble();
  }

  List<DistrictData> _getDistrictData() {
    if (_useDummyHeatmapData) {
      return _districtDisplayOrder.map((district) {
        final double score = _dummyDistrictScores[district.toLowerCase()] ?? 0;
        final double cases = _dummyScoreToCases(score);
        return DistrictData(district, cases, cases);
      }).toList();
    }

    final app = AppScope.of(context);
    final regions = app.regionalHotspotSummary;

    return _districtDisplayOrder.map((district) {
      final region = regions.firstWhere(
        (r) => r.district.toLowerCase() == district.toLowerCase(),
        orElse: () => HotspotRegionSummary(
          district: district,
          score: 0,
          riskLevel: 'low',
          patients: 0,
          totalEvents: 0,
          hometownCount: 0,
          workplaceCount: 0,
          visitCount: 0,
        ),
      );

      final double cases = region.totalEvents.toDouble();
      return DistrictData(district, cases, cases);
    }).toList();
  }

  Widget _buildChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool s) {
          if (s) {
            setState(() {
              _selectedMapDisease = label == "Dengue"
                  ? DiseaseType.dengue
                  : DiseaseType.ratFever;
              _selectedDistrictIndex = -1;
            });
            final app = AppScope.of(context);
            unawaited(_switchMapDisease(app, _selectedMapDisease));
          }
        },
        selectedColor: primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildDistrictCard(
    String title,
    String subtitle,
    String stats,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E5F8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2440),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6C7A95),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            stats,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicCards() {
    final data = _getDistrictData();
    List<DistrictData> displayedData;

    if (_selectedDistrictIndex != -1 && _selectedDistrictIndex < data.length) {
      displayedData = [data[_selectedDistrictIndex]];
    } else if (_isViewAll) {
      displayedData = List.from(data);
    } else {
      List<DistrictData> sorted = List.from(data);
      sorted.sort(
        (a, b) => (selectedDisease == "Dengue" ? b.dengueCases : b.leptoCases)
            .compareTo(
              selectedDisease == "Dengue" ? a.dengueCases : a.leptoCases,
            ),
      );
      displayedData = sorted.take(3).toList();
    }

    return displayedData.map((d) {
      double cases = (selectedDisease == "Dengue"
          ? d.dengueCases
          : d.leptoCases);
      return _buildDistrictCard(
        d.district,
        "${cases.toInt()} reported cases",
        cases > 1000 ? "+12%" : "-5%",
        cases > 1000 ? const Color(0xFF1E5AA8) : const Color(0xFF4F7FC4),
        cases > 1000 ? Icons.trending_up : Icons.trending_down,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final currentUser = app.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadingInitialSetup) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showInitialSetup) {
      return HeatmapSetupScreen(
        selectedDisease: _setupDisease,
        selectedDistrict: _setupDistrict,
        districts: _districtDisplayOrder,
        onDiseaseChanged: (value) => setState(() => _setupDisease = value),
        onDistrictChanged: (value) => setState(() => _setupDistrict = value),
        onContinue: () => unawaited(_completeInitialSetup(app)),
      );
    }

    final regionalSummary = app.regionalHotspotSummary;
    final shapeData = _shapeDataFromRegions(regionalSummary);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        title: const Text(
          'Heat Map',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AUTOCOMPLETE SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _districtsList.where(
                      (String option) => option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (String selection) {
                    _searchController.text = selection;
                    _selectDistrictByName(selection);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            hintText: "Search for a District in Sri Lanka...",
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black54,
                            ),
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
                  _buildChip(
                    "Dengue",
                    _selectedMapDisease == DiseaseType.dengue,
                  ),
                  _buildChip(
                    "Rat Fever",
                    _selectedMapDisease == DiseaseType.ratFever,
                  ),
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
                shapeData: shapeData,
                isLoading: _loadingMap,
                buildShapeSource: _buildShapeSource,
                buildVerticalMapLegend: _buildVerticalMapLegend,
                selectedDisease: _selectedMapDisease,
              ),
            ),

            // Density Details Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Density Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _isViewAll = !_isViewAll;
                      _selectedDistrictIndex = -1;
                    }),
                    child: Text(
                      _isViewAll ? "Show Less" : "View All",
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ..._buildDynamicCards(),
          ],
        ),
      ),
    );
  }
}

// --- HEATMAP CARD WITH LEGEND AT TOP RIGHT ---

class HeatmapCard extends StatefulWidget {
  final String disease;
  final int selectedIndex;
  final ValueChanged<int> onDistrictSelected;
  final List<DistrictHeatData> shapeData;
  final bool isLoading;
  final MapShapeSource Function(List<DistrictHeatData> data) buildShapeSource;
  final List<Widget> Function() buildVerticalMapLegend;
  final DiseaseType selectedDisease;

  const HeatmapCard({
    super.key,
    required this.disease,
    required this.selectedIndex,
    required this.onDistrictSelected,
    required this.shapeData,
    required this.isLoading,
    required this.buildShapeSource,
    required this.buildVerticalMapLegend,
    required this.selectedDisease,
  });

  @override
  State<HeatmapCard> createState() => _HeatmapCardState();
}

class _HeatmapCardState extends State<HeatmapCard> {
  late MapShapeSource _shapeSource;

  @override
  void initState() {
    _updateSource();
    super.initState();
  }

  @override
  void didUpdateWidget(HeatmapCard oldWidget) {
    if (oldWidget.disease != widget.disease ||
        oldWidget.selectedDisease != widget.selectedDisease) {
      _updateSource();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _updateSource() {
    setState(() {
      _shapeSource = widget.buildShapeSource(widget.shapeData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${widget.disease} Distribution Map",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SfMaps(
                          layers: [
                            MapShapeLayer(
                              source: _shapeSource,
                              showDataLabels: true,
                              selectedIndex: widget.selectedIndex,
                              onSelectionChanged: (int index) =>
                                  widget.onDistrictSelected(index),
                              selectionSettings: const MapSelectionSettings(
                                color: Color(0xFF9BBCE7),
                                strokeColor: Colors.white,
                                strokeWidth: 2,
                              ),
                              dataLabelSettings: const MapDataLabelSettings(
                                textStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                // VERTICAL LEGEND AT TOP RIGHT
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.buildVerticalMapLegend(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DistrictData {
  const DistrictData(this.district, this.dengueCases, this.leptoCases);
  final String district;
  final double dengueCases;
  final double leptoCases;
}

class DistrictHeatData {
  const DistrictHeatData({required this.district, required this.score});

  final String district;
  final double score;
}

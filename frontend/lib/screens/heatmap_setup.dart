import 'package:flutter/material.dart';

import '../app/models.dart';

class HeatmapSetupScreen extends StatelessWidget {
  const HeatmapSetupScreen({
    super.key,
    required this.selectedDisease,
    required this.selectedDistrict,
    required this.districts,
    required this.onDiseaseChanged,
    required this.onDistrictChanged,
    required this.onContinue,
  });

  final DiseaseType selectedDisease;
  final String? selectedDistrict;
  final List<String> districts;
  final ValueChanged<DiseaseType> onDiseaseChanged;
  final ValueChanged<String> onDistrictChanged;
  final VoidCallback onContinue;

  static const Color primary = Color(0xFF1E5AA8);
  static const Color backgroundLight = Color(0xFFF6F8F8);

  @override
  Widget build(BuildContext context) {
    final String selectedDiseaseLabel = selectedDisease == DiseaseType.ratFever
        ? 'Rat Fever'
        : 'Dengue';

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Heat Map Setup',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE6F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set your heat map profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2440),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your current disease and district once. Next time you will go directly to the heat map.',
                  style: TextStyle(color: Color(0xFF5D6B85), height: 1.35),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Disease',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A3855),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DiseaseType>(
                  initialValue: selectedDisease,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: DiseaseType.dengue,
                      child: Text('Dengue'),
                    ),
                    DropdownMenuItem(
                      value: DiseaseType.ratFever,
                      child: Text('Rat Fever'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onDiseaseChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current District',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A3855),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedDistrict,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: districts
                      .map(
                        (district) => DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onDistrictChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedDistrict == null ? null : onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Continue with $selectedDiseaseLabel map'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

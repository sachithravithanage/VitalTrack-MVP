import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

// Note: These imports will show errors until we create these two files in the next step!
import 'link_caretaker_screen.dart';
import 'dashboard_no_data_screen.dart';

class MedicalProfileScreen extends StatefulWidget {
  final String userRole; // Receives 'Patient' or 'Caretaker'

  const MedicalProfileScreen({super.key, required this.userRole});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  String? selectedBloodType;
  String? hasDiabetes;
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  @override
  void dispose() {
    weightController.dispose();
    healthConditionsController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    // 1. Validation: Check if Weight, Blood Type, or Diabetes status is missing
    if (weightController.text.trim().isEmpty ||
        selectedBloodType == null ||
        hasDiabetes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter your weight, blood type, and diabetes status.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop the user from moving forward
    }
    // Save the data globally!
    globalUserWeight = weightController.text;
    globalUserBloodType = selectedBloodType!;

    // 2. If valid, proceed with your existing branching logic
    if (widget.userRole == 'Patient') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LinkCaretakerScreen()),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardNoDataScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF20B5A0), // Switched back to Teal
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'VitalTrack',
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Placeholder for Doctor/Laptop Illustration
            Container(
              height: 180,
              width: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E4DF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child:
                    Icon(Icons.laptop_mac, size: 80, color: Color(0xFF4A908A)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Medical Profile',
              style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us personalize your health monitoring by providing your medical details.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 32),

            // Form Fields aligned to start
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Weight (kg)'),
                  _buildTextField(weightController, 'e.g. 72',
                      keyboardType: TextInputType.number),
                  _buildLabel('Blood Type'),
                  _buildDropdown(
                    hint: 'Select blood type',
                    value: selectedBloodType,
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                    onChanged: (val) => setState(() => selectedBloodType = val),
                  ),
                  _buildLabel('Do you have diabetes?'),
                  _buildDropdown(
                    hint: 'Select',
                    value: hasDiabetes,
                    items: ['Yes', 'No'],
                    onChanged: (val) => setState(() => hasDiabetes = val),
                  ),
                  _buildLabel('Other Health Conditions'),
                  _buildTextField(healthConditionsController,
                      'e.g. Hypertension, Asthma...',
                      maxLines: 3),
                  _buildLabel('Allergies'),
                  _buildTextField(
                      allergiesController, 'e.g. Peanuts, Penicillin...',
                      maxLines: 1),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Next Step Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7B85),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleNextStep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next Step',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                _buildDot(true),
                _buildDot(false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        text,
        style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildDropdown(
      {required String hint,
      required String? value,
      required List<String> items,
      required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint,
              style: GoogleFonts.nunito(color: Colors.grey.shade400)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child:
                  Text(item, style: GoogleFonts.nunito(color: Colors.black87)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF20B5A0)),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      height: 6,
      width: isActive ? 24 : 6,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF20B5A0) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

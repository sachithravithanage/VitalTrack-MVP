import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'link_caretaker_screen.dart';
import 'main_layout.dart'; // REQUIRED TO SHOW THE NAVIGATION BAR!

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key, required this.userRole});
  final String userRole;

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
  bool isLoading = false;

  @override
  void dispose() {
    weightController.dispose();
    healthConditionsController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  Future<void> _handleNextStep() async {
    if (weightController.text.trim().isEmpty ||
        selectedBloodType == null ||
        hasDiabetes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'weight': weightController.text.trim(),
          'bloodType': selectedBloodType,
          'hasDiabetes': hasDiabetes == 'Yes',
          'preExistingConditions': healthConditionsController.text.trim(),
          'allergies': allergiesController.text.trim(),
        });

        if (!mounted) return;

        // Give them the option to link a caretaker OR route to the Dashboard (with Nav Bar!)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LinkCaretakerScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Medical Information',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Vitals',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildDropdown(
                ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                selectedBloodType,
                (val) => setState(() => selectedBloodType = val)),
            const SizedBox(height: 16),
            _buildTextField(weightController, 'Weight (kg)',
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            Text('Medical History',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Do you have Diabetes?',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Yes'),
                          value: 'Yes',
                          groupValue: hasDiabetes,
                          activeColor: const Color(0xFF20B5A0),
                          onChanged: (val) => setState(() => hasDiabetes = val),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('No'),
                          value: 'No',
                          groupValue: hasDiabetes,
                          activeColor: const Color(0xFF20B5A0),
                          onChanged: (val) => setState(() => hasDiabetes = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(healthConditionsController,
                'Other pre-existing conditions (Optional)',
                maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(allergiesController, 'Allergies (Optional)',
                maxLines: 3),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B5A0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Complete Setup',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? currentValue,
      ValueChanged<String?> onChanged) {
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
          hint: Text('Select Blood Type',
              style: GoogleFonts.nunito(color: Colors.grey.shade400)),
          value: currentValue,
          items: items
              .map((String item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
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
            borderSide: BorderSide.none),
      ),
    );
  }
}

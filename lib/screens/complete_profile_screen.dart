import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'
    as math; // FIXED: Added 'as math' to prevent naming collisions

import 'medical_profile_screen.dart';
import 'main_layout.dart';
import '../models/user_profile.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String selectedGender = 'Male';
  String selectedRole = 'Patient';
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF20B5A0),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // FIXED: Using math.Random() to guarantee we use the correct library
  String generateCaretakerCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    math.Random rnd = math.Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? generatedCode;
        if (selectedRole == 'Caretaker') {
          generatedCode = generateCaretakerCode();
        }

        final userProfile = UserProfile(
          uid: user.uid,
          fullName: nameController.text.trim(),
          phone: phoneController.text.trim(),
          dob: dobController.text.trim(),
          gender: selectedGender,
          role: selectedRole,
          address: addressController.text.trim(),
          createdAt: DateTime.now(),
          caretakerCode: generatedCode,
          linkedPatients: [],
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userProfile.toFirestore());

        if (!mounted) return;

        if (selectedRole == 'Patient') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const MedicalProfileScreen(userRole: 'Patient')),
          );
        } else {
          // If Caretaker, route to MainLayout so navigation bar appears!
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
            (route) => false,
          );
        }
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
        title: Text('Complete Profile',
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
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.person,
                        size: 50, color: Color(0xFF20B5A0)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Color(0xFF0F172A), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('I am a...',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    'Patient',
                    Icons.personal_injury,
                    selectedRole == 'Patient',
                    () => setState(() => selectedRole = 'Patient'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectionCard(
                    'Caretaker',
                    Icons.health_and_safety,
                    selectedRole == 'Caretaker',
                    () => setState(() => selectedRole = 'Caretaker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(
                phoneController, 'Phone Number', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(dobController,
                    'Date of Birth (YYYY-MM-DD)', Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
                addressController, 'Home Address', Icons.location_on_outlined),
            const SizedBox(height: 24),
            Text('Gender',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    'Male',
                    Icons.male,
                    selectedGender == 'Male',
                    () => setState(() => selectedGender = 'Male'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectionCard(
                    'Female',
                    Icons.female,
                    selectedGender == 'Female',
                    () => setState(() => selectedGender = 'Female'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B5A0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        selectedRole == 'Patient'
                            ? 'Next: Medical Info'
                            : 'Complete Setup',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSelectionCard(
      String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  isSelected ? const Color(0xFF20B5A0) : Colors.grey.shade200,
              width: 2),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFF1B7B85)
                    : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(text,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF1B7B85)
                        : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

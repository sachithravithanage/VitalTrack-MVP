import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'medical_profile_screen.dart';
import '../globals.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // Controllers for text fields
  final TextEditingController nameController = TextEditingController(
      text: 'Kapuge Arachchige Asindi Thatasarani Rathnayaka');
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController =
      TextEditingController(text: '1992/06/05');
  final TextEditingController addressController = TextEditingController();

  String selectedGender = 'Male';
  String selectedRole = 'Patient';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    addressController.dispose();
    super.dispose();
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
                color: const Color(0xFF20B5A0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.monitor_heart,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'VitalTrack',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for Doctor/Patient Illustration
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF4A908A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.people, size: 80, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Complete Your Profile',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s get to know you better to personalize your health experience.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Full Name Field
            _buildLabel('Full Name'),
            _buildTextField(
                nameController, 'Enter your full name', Icons.person_outline),

            // Phone Number Field
            _buildLabel('Phone Number'),
            _buildTextField(
                phoneController, '+1 (555) 000-0000', Icons.phone_outlined,
                keyboardType: TextInputType.phone),

            // Date of Birth Field
            _buildLabel('Date of Birth'),
            _buildTextField(
                dobController, 'MM/DD/YYYY', Icons.calendar_today_outlined),

            // Gender Selection
            _buildLabel('Gender'),
            Row(
              children: [
                Expanded(
                    child: _buildSelectionCard(
                        'Male',
                        Icons.male,
                        selectedGender == 'Male',
                        () => setState(() => selectedGender = 'Male'))),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSelectionCard(
                        'Female',
                        Icons.female,
                        selectedGender == 'Female',
                        () => setState(() => selectedGender = 'Female'))),
              ],
            ),
            const SizedBox(height: 16),

            // Role Selection
            _buildLabel('I am a...'),
            Row(
              children: [
                Expanded(
                    child: _buildSelectionCard(
                        'Patient',
                        Icons.person,
                        selectedRole == 'Patient',
                        () => setState(() => selectedRole = 'Patient'))),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSelectionCard(
                        'Caretaker',
                        Icons.health_and_safety,
                        selectedRole == 'Caretaker',
                        () => setState(() => selectedRole = 'Caretaker'))),
              ],
            ),
            const SizedBox(height: 16),

            // Home Address Field
            _buildLabel('Home Address'),
            _buildTextField(addressController, 'Enter your home address',
                Icons.location_on_outlined),

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7B85),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter your name.'),
                        backgroundColor: Colors.red));
                    return;
                  }

                  globalUserName = nameController.text;
                  globalUserRole = selectedRole;
                  globalUserDOB = dobController.text;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MedicalProfileScreen(userRole: selectedRole),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next',
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
                _buildDot(true),
                _buildDot(false),
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
            color: isSelected ? const Color(0xFF20B5A0) : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFF1B7B85)
                    : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? const Color(0xFF1B7B85) : Colors.grey.shade600,
              ),
            ),
          ],
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

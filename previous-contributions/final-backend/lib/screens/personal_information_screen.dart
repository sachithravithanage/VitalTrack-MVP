import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/patient_provider.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _weightController;
  late TextEditingController _phoneController;
  String? _selectedBloodType;

  // FIXED: Added a dedicated variable for the REAL caretaker code
  String? _caretakerCode;

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  @override
  void initState() {
    super.initState();
    // 1. Load the initial data from memory so the screen doesn't look blank
    final currentUser = context.read<PatientProvider>().currentUser;
    _nameController = TextEditingController(text: currentUser?.fullName ?? '');
    _dobController = TextEditingController(text: currentUser?.dob ?? '');
    _weightController =
        TextEditingController(text: currentUser?.weight?.toString() ?? '');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
    _selectedBloodType = currentUser?.bloodType;

    // FIXED: Load initial real code
    _caretakerCode = currentUser?.caretakerCode;

    // 2. BULLETPROOF FIX: Always force the app to pull the absolute newest data straight from Firebase!
    _fetchFreshData();
  }

  // --- NEW FUNCTION: Ensures the screen never gets stuck with old cached data ---
  Future<void> _fetchFreshData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['fullName'] ?? _nameController.text;
            _dobController.text = data['dob'] ?? _dobController.text;
            _weightController.text =
                data['weight']?.toString() ?? _weightController.text;
            _phoneController.text = data['phone'] ?? _phoneController.text;
            _selectedBloodType = data['bloodType'] ?? _selectedBloodType;

            // FIXED: Fetch the REAL Caretaker code from the database
            _caretakerCode = data['caretakerCode'] ?? _caretakerCode;
          });
        }
      } catch (e) {
        debugPrint('Failed to fetch fresh data: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Update the database securely
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': _nameController.text.trim(),
          'dob': _dobController.text.trim(),
          'weight': _weightController.text.trim(),
          'phone': _phoneController.text.trim(),
          'bloodType': _selectedBloodType,
        });

        setState(() {
          _isEditing = false; // Turn off edit mode
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Information updated successfully!'),
              backgroundColor: Color(0xFF20B5A0)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return; // Only allow date picking if in edit mode

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
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final currentUser = provider.currentUser;
    final role = currentUser?.role ?? 'Patient';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Personal Information',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. TOP PROFILE HEADER
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF20B5A0), width: 2),
                    ),
                    child: const Icon(Icons.person,
                        size: 50, color: Color(0xFF20B5A0)),
                  ),
                  const SizedBox(height: 16),

                  // NAME FIELD (Static or Editable)
                  if (_isEditing)
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        border: UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFF20B5A0), width: 2)),
                      ),
                    )
                  else
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Unknown User',
                      style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A)),
                    ),

                  const SizedBox(height: 4),
                  Text(role,
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. CARETAKER LINKING CODE BOX
            if (role == 'Caretaker') ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF20B5A0).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF20B5A0).withOpacity(0.5),
                      width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.link,
                            color: Color(0xFF20B5A0), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Your Caretaker Linking Code',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF20B5A0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // FIXED: Display the real Caretaker code from Firebase
                    Text(
                      _caretakerCode ?? '------',
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Share this code with patients to link accounts.',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 3. INFORMATION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // DATE OF BIRTH
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date of Birth',
                    child: _isEditing
                        ? GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _dobController,
                                style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A)),
                                decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none),
                              ),
                            ),
                          )
                        : Text(
                            _dobController.text.isNotEmpty
                                ? _dobController.text
                                : '--',
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A))),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 32),

                  // WEIGHT
                  _buildInfoRow(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    child: _isEditing
                        ? TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'e.g. 65'),
                          )
                        : Text(
                            _weightController.text.isNotEmpty
                                ? '${_weightController.text} kg'
                                : '--',
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A))),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 32),

                  // BLOOD TYPE
                  _buildInfoRow(
                    icon: Icons.bloodtype_outlined,
                    label: 'Blood Type',
                    child: _isEditing
                        ? DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBloodType,
                              isDense: true,
                              hint: Text('Select',
                                  style: GoogleFonts.nunito(
                                      fontSize: 16, color: Colors.grey)),
                              items: _bloodTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A))),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedBloodType = newValue;
                                });
                              },
                            ),
                          )
                        : Text(_selectedBloodType ?? '--',
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A))),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 32),

                  // PHONE NUMBER
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    child: _isEditing
                        ? TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'e.g. 0712345678'),
                          )
                        : Text(
                            _phoneController.text.isNotEmpty
                                ? _phoneController.text
                                : '--',
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // DYNAMIC BUTTON (Edit vs Save)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B5A0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : Icon(_isEditing ? Icons.save : Icons.edit,
                        color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing ? 'Save Changes' : 'Edit Information',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to draw the rows inside the card cleanly
  Widget _buildInfoRow(
      {required IconData icon, required String label, required Widget child}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF20B5A0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF20B5A0), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

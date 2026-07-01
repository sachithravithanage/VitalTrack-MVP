import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/patient_provider.dart';
import 'main_layout.dart';

class AddPatientScreen extends StatefulWidget {
  final UserProfile? patient;

  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController conditionsController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  String selectedGender = 'Male';
  String? selectedBloodType;
  String? hasDiabetes;
  bool isLoading = false;

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

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    if (patient != null) {
      nameController.text = patient.fullName;
      phoneController.text = patient.phone;
      dobController.text = patient.dob;
      addressController.text = patient.address;
      weightController.text = patient.weight ?? '';
      conditionsController.text = patient.preExistingConditions ?? '';
      allergiesController.text = patient.allergies ?? '';
      selectedGender = patient.gender;
      selectedBloodType = patient.bloodType;
      hasDiabetes = patient.hasDiabetes == null
          ? null
          : (patient.hasDiabetes! ? 'Yes' : 'No');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    addressController.dispose();
    weightController.dispose();
    conditionsController.dispose();
    allergiesController.dispose();
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
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _savePatient() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty ||
        selectedBloodType == null ||
        hasDiabetes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final caretaker = FirebaseAuth.instance.currentUser;
      if (caretaker == null) {
        throw Exception('You must be signed in to add a patient.');
      }

      final caretakerRef =
          FirebaseFirestore.instance.collection('users').doc(caretaker.uid);

      final patientRef = _isEditing
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(widget.patient!.uid)
          : FirebaseFirestore.instance.collection('users').doc();

      final patientProfile = UserProfile(
        uid: patientRef.id,
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        dob: dobController.text.trim(),
        gender: selectedGender,
        role: 'Patient',
        address: addressController.text.trim(),
        createdAt: _isEditing ? widget.patient!.createdAt : DateTime.now(),
        linkedCaretakerId: widget.patient?.linkedCaretakerId ?? caretaker.uid,
        linkedPatients: const [],
        weight: weightController.text.trim(),
        bloodType: selectedBloodType,
        hasDiabetes: hasDiabetes == 'Yes',
        preExistingConditions: conditionsController.text.trim().isEmpty
            ? null
            : conditionsController.text.trim(),
        allergies: allergiesController.text.trim().isEmpty
            ? null
            : allergiesController.text.trim(),
      );

      final batch = FirebaseFirestore.instance.batch();

      if (_isEditing) {
        batch.update(patientRef, patientProfile.toFirestore());
      } else {
        batch.set(patientRef, patientProfile.toFirestore());
        batch.update(caretakerRef, {
          'linkedPatients': FieldValue.arrayUnion([patientRef.id]),
        });
      }

      await batch.commit();

      final patientProvider = context.read<PatientProvider>();
      await patientProvider.refreshCurrentUser();
      if (!_isEditing ||
          patientProvider.activePatient?.uid == patientProfile.uid) {
        await patientProvider.setActivePatient(patientProfile);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Patient updated successfully.'
              : 'Patient added successfully.'),
          backgroundColor: Color(0xFF20B5A0),
        ),
      );

      if (_isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Patient' : 'Add Patient',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Details',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(nameController, 'Full Name'),
            const SizedBox(height: 12),
            _buildTextField(
              phoneController,
              'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(dobController, 'Date of Birth'),
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              const ['Male', 'Female', 'Other'],
              selectedGender,
              (value) => setState(() => selectedGender = value ?? 'Male'),
            ),
            const SizedBox(height: 12),
            _buildTextField(addressController, 'Address', maxLines: 2),
            const SizedBox(height: 28),
            Text(
              'Medical Details',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              weightController,
              'Weight (kg)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              _bloodTypes,
              selectedBloodType,
              (value) => setState(() => selectedBloodType = value),
              hint: 'Blood Type',
            ),
            const SizedBox(height: 12),
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
                  Text(
                    'Do they have Diabetes?',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Yes'),
                          value: 'Yes',
                          groupValue: hasDiabetes,
                          activeColor: const Color(0xFF20B5A0),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) =>
                              setState(() => hasDiabetes = value),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('No'),
                          value: 'No',
                          groupValue: hasDiabetes,
                          activeColor: const Color(0xFF20B5A0),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) =>
                              setState(() => hasDiabetes = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              conditionsController,
              'Pre-existing conditions (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              allergiesController,
              'Allergies (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing ? 'Save Changes' : 'Create Patient',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String? currentValue,
    ValueChanged<String?> onChanged, {
    String? hint,
  }) {
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
          hint: Text(
            hint ?? 'Select option',
            style: GoogleFonts.nunito(color: Colors.grey.shade400),
          ),
          value: currentValue,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

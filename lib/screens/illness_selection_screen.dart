import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';

class IllnessSelectionScreen extends StatefulWidget {
  const IllnessSelectionScreen({super.key});

  @override
  State<IllnessSelectionScreen> createState() => _IllnessSelectionScreenState();
}

class _IllnessSelectionScreenState extends State<IllnessSelectionScreen> {
  String selectedIllness = 'dengue';
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  Future<void> _saveAndNavigate() async {
    final provider = context.read<PatientProvider>();

    // SAFETY GATE: Check if they already have an active illness
    if (provider.activeEpisode != null && provider.activeEpisode!.isActive) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Start New Tracking?',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            content: Text(
                'You are currently tracking an active case of ${provider.activeEpisode!.diseaseName}. Starting a new illness will end your current tracking session and archive your data. Are you sure you want to continue?',
                style: GoogleFonts.nunito(
                    color: const Color(0xFF475569), height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                    dialogContext, false), // Return false on cancel
                child: Text('Cancel',
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEF4444), // Red for destructive action
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(
                    dialogContext, true), // Return true on confirm
                child: Text('Yes, Start New',
                    style: GoogleFonts.nunito(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      // If they clicked Cancel or tapped outside the box, stop the function!
      if (confirm != true) {
        return;
      }
    }

    setState(() => isLoading = true);

    String illnessName =
        selectedIllness == 'dengue' ? 'Dengue' : 'Leptospirosis';

    try {
      // Call our Provider to generate a proper Disease Episode!
      await provider.startNewEpisode(illnessName, selectedDate);

      if (!mounted) return;

      // Pop this screen off the stack.
      // The HomeWrapper inside MainLayout will automatically see the new episode and swap the dashboard!
      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you tracking?',
                style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the illness you have been diagnosed with to customize your dashboard.',
                style: GoogleFonts.nunito(
                    fontSize: 16, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 40),
              _buildIllnessOption(
                id: 'dengue',
                title: 'Dengue Fever',
                description: 'Track fever, platelets, and fluid intake.',
                icon: Icons.water_drop,
                color: const Color(0xFF20B5A0),
              ),
              const SizedBox(height: 16),
              _buildIllnessOption(
                id: 'lepto',
                title: 'Leptospirosis',
                description: 'Monitor symptoms, blood pressure, and urine.',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEC5B13),
              ),
              const SizedBox(height: 40),
              Text(
                'When did symptoms start?',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF20B5A0)),
                      const SizedBox(width: 12),
                      Text(
                        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Continue',
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
      ),
    );
  }

  Widget _buildIllnessOption({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    bool isSelected = selectedIllness == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIllness = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected ? color : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.nunito(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(description,
                      style:
                          GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}

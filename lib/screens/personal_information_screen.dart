import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Information',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFFA),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF14B8A6), width: 3),
                    ),
                    child: const Icon(Icons.person,
                        size: 50, color: Color(0xFF14B8A6)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    globalUserName.isEmpty ? 'Guest User' : globalUserName,
                    style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    globalUserRole,
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // =======================================================
            // NEW: CARETAKER LINKING CODE (Only shows for Caretakers)
            // =======================================================
            if (globalUserRole == 'Caretaker') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Very light mint/green
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.link,
                            color: Color(0xFF059669), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Your Caretaker Linking Code',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF059669)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '482 915', // You can replace this with a dynamic variable later if needed!
                      style: GoogleFonts.nunito(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this code with patients to link accounts.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            // =======================================================

            // Details Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, 'Date of Birth',
                      globalUserDOB.isEmpty ? 'Not set' : globalUserDOB),
                  const Divider(color: Color(0xFFF1F5F9), height: 30),
                  _buildInfoRow(Icons.monitor_weight_outlined, 'Weight',
                      globalUserWeight.isEmpty ? 'Not set' : globalUserWeight),
                  const Divider(color: Color(0xFFF1F5F9), height: 30),
                  _buildInfoRow(
                      Icons.bloodtype_outlined,
                      'Blood Type',
                      globalUserBloodType.isEmpty
                          ? 'Not set'
                          : globalUserBloodType),
                  const Divider(color: Color(0xFFF1F5F9), height: 30),
                  _buildInfoRow(Icons.phone_outlined, 'Emergency Contact',
                      '+94 77 123 4567'), // Dummy data for UI completeness
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Edit Button (Visual only for now)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                label: Text('Edit Information',
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF14B8A6), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8))),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }
}

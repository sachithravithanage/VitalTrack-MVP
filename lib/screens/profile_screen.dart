import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/patient_provider.dart';
import 'personal_information_screen.dart';
import 'privacy_security_screen.dart';
import 'login_screen.dart';
import 'add_patient_screen.dart';
import 'link_caretaker_screen.dart';
import 'patient_connections_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final currentUser = provider.currentUser;
    final authUser = FirebaseAuth.instance.currentUser;

    final String fullName = currentUser?.fullName.trim().isNotEmpty == true
        ? currentUser!.fullName
        : (authUser?.displayName?.trim().isNotEmpty == true
            ? authUser!.displayName!
            : (authUser?.email?.split('@').first ?? ''));
    final String role = currentUser?.role ?? 'Patient';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // User Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.person,
                      size: 50, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'Caretaker'
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: role == 'Caretaker'
                          ? const Color(0xFFD97706)
                          : const Color(0xFF20B5A0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Menu Options
          Text(
            'Account Settings',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          _buildMenuTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PersonalInformationScreen())),
          ),

          // DYNAMIC BUTTON: Updated text for the new Manage functionality
          if (role == 'Patient')
            _buildMenuTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Manage Caretaker',
              subtitle: 'Add or remove your caretaker connection',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const LinkCaretakerScreen(isFromOnboarding: false))),
            ),

          if (role == 'Caretaker')
            _buildMenuTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Add Patient',
              subtitle: 'Create a patient profile from this account',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddPatientScreen())),
            ),

          if (role == 'Caretaker')
            _buildMenuTile(
              icon: Icons.people_outline,
              title: 'My Patients',
              subtitle: 'View linked and added patients',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PatientConnectionsScreen())),
            ),

          _buildMenuTile(
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacySecurityScreen())),
          ),

          const SizedBox(height: 24),

          // Log Out Button
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout,
                        color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Log Out',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
      {required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF14B8A6), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Log Out',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text(
              'Are you sure you want to log out? Your session data will be cleared.',
              style: GoogleFonts.nunito(color: const Color(0xFF475569))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleSignOut(context);
              },
              child: Text('Log Out',
                  style: GoogleFonts.nunito(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

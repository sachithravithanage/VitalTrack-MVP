import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

// Import your new screens and login screen
import 'personal_information_screen.dart';
import 'privacy_security_screen.dart';
import 'login_screen.dart'; // Make sure this matches your login file name!

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // The Sign Out Logic that clears everything (UPDATED TO HARD RESET)
  void _handleSignOut(BuildContext context) {
    // 1. Clear all personal information
    globalUserName = '';
    globalUserRole = 'Patient';
    globalUserDOB = '';
    globalUserWeight = '';
    globalUserBloodType = '';

    // 2. Clear all Dengue records (HARD RESET WITH [])
    globalTempHistory = [];
    globalPlateletHistory = [];
    globalFluidHistory = [];
    globalUrineHistory = [];

    // 3. Clear all Leptospirosis records (HARD RESET WITH [])
    globalLeptoTempHistory = [];
    globalLeptoUrineHistory = [];
    globalBPHistory = [];
    globalSymptomsHistory = [];

    // 4. Navigate back to Login and completely clear the app history
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) =>
          false, // This prevents the user from hitting the "back" button to return
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B)),
        ),
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Hides the back button since this is a main tab
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Simple Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFFA),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF14B8A6), width: 3),
                    ),
                    child: const Icon(Icons.person,
                        size: 40, color: Color(0xFF14B8A6)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    globalUserName.isEmpty ? 'Guest User' : globalUserName,
                    style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    globalUserRole,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Settings Options Menu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  // Button 1: Personal Information
                  _buildMenuButton(
                    context,
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalInformationScreen()));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Button 2: Privacy & Security
                  _buildMenuButton(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PrivacySecurityScreen()));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Button 3: Settings/Preferences (Placeholder)
                  _buildMenuButton(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'App Preferences',
                    onTap: () {
                      // You can add a preferences screen later if you want
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                ),
                onPressed: () {
                  // Show a quick confirmation dialog before logging out
                  _showLogoutConfirmation(context);
                },
                icon: const Icon(Icons.logout),
                label: Text('Log Out',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 100), // Padding for bottom navigation bar
          ],
        ),
      ),
    );
  }

  // Reusable widget for the menu items
  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF14B8A6), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }

  // A nice popup to confirm logging out
  void _showLogoutConfirmation(BuildContext context) {
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
              onPressed: () => Navigator.pop(dialogContext), // Close dialog
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
                Navigator.pop(dialogContext); // Close dialog
                _handleSignOut(context); // Trigger the actual sign-out logic
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

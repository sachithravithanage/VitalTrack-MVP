import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';
import 'patient_connections_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Magic function to calculate age from YYYY/MM/DD
  String _calculateAge(String dobString) {
    if (dobString.isEmpty) return '33'; // Default fallback
    try {
      List<String> parts = dobString.split('/');
      if (parts.length == 3) {
        DateTime dob = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        DateTime today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month ||
            (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
        return age.toString();
      }
    } catch (e) {
      return '33'; // Fallback if they typed it weirdly
    }
    return '33';
  }

  @override
  Widget build(BuildContext context) {
    // Safely get the details, fallback to default if empty
    String displayName = globalUserName.isNotEmpty
        ? globalUserName
        : 'Kapuge Arachchige Asindi Thatasarani Rathnayaka';
    String displayAge =
        _calculateAge(globalUserDOB.isNotEmpty ? globalUserDOB : '1992/06/05');
    String displayBlood =
        globalUserBloodType.isNotEmpty ? globalUserBloodType : 'O+';
    String displayWeight =
        globalUserWeight.isNotEmpty ? '${globalUserWeight}kg' : '72kg';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B), size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF147B85)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.settings,
                  color: Color(0xFF1E293B), size: 18),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFF0F7FF), width: 4),
                          color: const Color(0xFFFDE68A),
                        ),
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Color(0xFF147B85), shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: 199215707162',
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  // Dynamic Stats Row
                  // Dynamic Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBadge('AGE', displayAge),
                      _buildStatBadge('BLOOD', displayBlood),
                      _buildStatBadge('WEIGHT', displayWeight),
                    ],
                  ),

                  // CARETAKER LINKING CODE (Only shows if role is Caretaker)
                  if (globalUserRole == 'Caretaker') ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF0FDF4), // Light green background
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Linking Code',
                                  style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF047857))),
                              Text('774291', // Hardcoded mockup code
                                  style: GoogleFonts.nunito(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF059669),
                                      letterSpacing: 4)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                color: Color(0xFF10B981)),
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content:
                                    Text('Linking Code copied to clipboard!'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Options Card
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(Icons.person_outline, 'Personal Information',
                      const Color(0xFF0EA5E9), const Color(0xFFE0F2FE), () {}),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  if (globalUserRole == 'Caretaker') ...[
                    _buildMenuItem(
                      Icons.watch_outlined,
                      'Patients Connections',
                      const Color(0xFF10B981),
                      const Color(0xFFD1FAE5),
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PatientConnectionsScreen()));
                      },
                      subtitle: '1 Patients Connected',
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                  _buildMenuItem(Icons.lock_outline, 'Privacy & Security',
                      const Color(0xFFA855F7), const Color(0xFFF3E8FF), () {}),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(Icons.help_outline, 'Help Center',
                      const Color(0xFF14B8A6), const Color(0xFFCCFBF1), () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  // Navigate to the Login Screen and clear the history so they can't hit "Back"
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context), // Goes back to the Dashboard
              child: _buildNavItem(Icons.home, 'Home', false),
            ),
            _buildNavItem(Icons.assignment, 'Log', false),
            _buildNavItem(Icons.location_on, 'Map', false),
            _buildNavItem(Icons.person, 'Profile', true), // <-- ACTIVE (Teal)
          ],
        ),
      ),
    );
  }

  // ADDED: Helper widget to draw the navigation icons
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF26A69A) : Colors.grey.shade400,
        ),
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF26A69A) : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF147B85))),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor,
      Color bgColor, VoidCallback onTap,
      {String? subtitle}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B))),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981)))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }
}

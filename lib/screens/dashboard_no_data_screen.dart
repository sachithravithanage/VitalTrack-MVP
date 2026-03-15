import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'illness_selection_screen.dart';
import '../globals.dart';
import 'profile_screen.dart';

class DashboardNoDataScreen extends StatelessWidget {
  const DashboardNoDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract the last name safely
    String lastName = globalUserName.isNotEmpty
        ? globalUserName.trim().split(' ').last
        : 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEC5B13).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.health_and_safety,
                  color: Color(0xFFEC5B13), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'VitalTrack',
              style: GoogleFonts.publicSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.blueGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $lastName!',
              style: GoogleFonts.publicSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to check your vitals today?',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Hero Illustration Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EE),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF20B5A0).withOpacity(0.1)),
              ),
              child: const Center(
                child: Icon(Icons.medical_information,
                    size: 80, color: Color(0xFF20B5A0)),
              ),
            ),
            const SizedBox(height: 24),

            // No Data Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC5B13).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_outlined,
                        color: Color(0xFFEC5B13), size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Data Yet',
                    style: GoogleFonts.publicSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It looks like you haven\'t tracked anything yet. Start monitoring your health today for better insights.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4DB6AC), Color(0xFF00695C)],
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const IllnessSelectionScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Add Data',
                            style: GoogleFonts.publicSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(Icons.edit_note, 'Log Symptoms'),
                _buildQuickAction(Icons.history, 'View History'),
                _buildQuickAction(Icons.person_outline, 'Update Info'),
              ],
            ),
            const SizedBox(height: 80), // Padding for the bottom nav bar
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IllnessSelectionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF26A69A),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.assignment, 'Log', false),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.location_on, 'Map', false),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: _buildNavItem(Icons.person, 'Profile', false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: const Color(0xFFEC5B13), size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

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
}

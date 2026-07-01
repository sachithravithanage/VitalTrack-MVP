import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/patient_provider.dart';
import 'home_wrapper.dart';
import 'activity_log.dart';
import 'heatmap.dart';
import 'profile_screen.dart';
import 'illness_selection_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // The 4 main tabs of your application
  final List<Widget> _screens = [
    const HomeWrapper(),
    const ActivityLogScreen(),
    const HeatMapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final isCaretaker = patientProvider.currentUser?.role == 'Caretaker';
    final showPatientActions =
        !isCaretaker || patientProvider.activePatient != null;

    return Scaffold(
      // IndexedStack keeps all tabs alive in memory without rebuilding them!
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Floating Action Button logic kept entirely here
      floatingActionButton: showPatientActions
          ? FloatingActionButton(
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
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // The Persistent Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.assignment, 'Log', 1),

              if (showPatientActions)
                const SizedBox(width: 40), // Space for FAB

              _buildNavItem(Icons.location_on, 'Map', 2),
              _buildNavItem(Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
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
      ),
    );
  }
}

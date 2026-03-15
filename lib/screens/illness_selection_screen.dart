import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dengue_dashboard_screen.dart';
import 'leptospirosis_dashboard_screen.dart';

class IllnessSelectionScreen extends StatefulWidget {
  const IllnessSelectionScreen({super.key});

  @override
  State<IllnessSelectionScreen> createState() => _IllnessSelectionScreenState();
}

class _IllnessSelectionScreenState extends State<IllnessSelectionScreen> {
  String selectedIllness = 'dengue'; // Default selection based on your HTML

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF), // Light blue background
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'What are you',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'feeling?',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D9C8D), // Primary Teal
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your diagnosed condition to start tracking.',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Leptospirosis Card
                  _buildIllnessCard(
                    id: 'leptospirosis',
                    title: 'Leptospirosis',
                    description:
                        'Bacterial disease affecting kidneys and liver. Watch for fever and muscle pain.',
                    icon: Icons.pest_control_rodent,
                    iconColor: const Color(0xFFF97316), // Orange
                    iconBgColor: const Color(0xFFFEF3C7), // Light yellow/orange
                  ),
                  const SizedBox(height: 20),

                  // Dengue Card
                  _buildIllnessCard(
                    id: 'dengue',
                    title: 'Dengue',
                    description:
                        'Mosquito-borne viral infection. Monitor platelets and hydration.',
                    icon: Icons.pest_control,
                    iconColor: const Color(0xFF0D9488), // Teal
                    iconBgColor: const Color(0xFFCCFBF1), // Light teal
                  ),
                ],
              ),
            ),

            // Bottom Continue Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFF0F7FF),
                      const Color(0xFFF0F7FF).withOpacity(0.0),
                    ],
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF2D9C8D).withOpacity(0.5),
                    ),
                    onPressed: () {
                      if (selectedIllness == 'dengue') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DengueDashboardScreen(),
                          ),
                          (route) => false,
                        );
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LeptospirosisDashboardScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF14B8A6),
                            Color(0xFF2563EB)
                          ], // Teal to Blue
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllnessCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    bool isSelected = selectedIllness == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIllness = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D9C8D).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D9C8D) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2D9C8D).withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(icon, size: 40, color: iconColor),
              ),
            ),
            const SizedBox(width: 20),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark Indicator
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 12),
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2D9C8D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

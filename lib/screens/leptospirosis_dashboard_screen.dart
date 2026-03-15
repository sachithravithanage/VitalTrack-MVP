import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';
import 'profile_screen.dart';

class LeptospirosisDashboardScreen extends StatelessWidget {
  const LeptospirosisDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String lastName = globalUserName.isNotEmpty
        ? globalUserName.trim().split(' ').last
        : 'User';
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            height: 1.2,
                          ),
                        ),
                        Text(
                          lastName,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFCA5A5),
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Leptospirosis Main Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFEAB308), Color(0xFFD97706)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.pets,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Leptospirosis',
                                  style: GoogleFonts.nunito(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B))),
                              Row(
                                children: [
                                  Text('Status: ',
                                      style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          color: const Color(0xFF6B7280))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('Stable',
                                        style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0D9488))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF9CA3AF)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 6,
                        width: 120,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.66,
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFACC15),
                                    Color(0xFFD97706)
                                  ]),
                                  borderRadius: BorderRadius.circular(4))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Vitals Grid (Custom for Leptospirosis)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildVitalCard(Icons.thermostat, 'Temperature', '98.6°F',
                      const Color(0xFFEF4444), const Color(0xFFFEF2F2), 0.75),
                  _buildVitalCard(
                      Icons.favorite_border,
                      'Blood Pressure',
                      '120/80',
                      const Color(0xFFF43F5E),
                      const Color(0xFFFFF1F2),
                      0.66),
                  // Custom Symptom Checklist Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF8FAFC))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.checklist,
                                    color: Color(0xFF6366F1), size: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Symptom Checklist',
                                      style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B7280))),
                                  Text('3/5 Logged',
                                      style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCheckItem('Yellow Eyes'),
                        _buildCheckItem('Muscle Pain'),
                        _buildCheckItem('Vomiting'),
                      ],
                    ),
                  ),
                  _buildVitalCard(Icons.water_drop, 'Urine Output', '850 ml',
                      const Color(0xFFA855F7), const Color(0xFFFAF5FF), 0.75),
                ],
              ),
              const SizedBox(height: 24),

              // Alerts Section
              Text('Alerts',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              const SizedBox(height: 12),
              _buildAlertCard(Icons.warning_amber, 'Low Hydration', '1 hr ago',
                  const Color(0xFFD97706), const Color(0xFFFEF3C7), 0.66),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2D9C8D),
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
              const SizedBox(width: 40),
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

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF6366F1), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildVitalCard(IconData icon, String title, String value, Color color,
      Color bgColor, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF8FAFC))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280))),
                    Text(value,
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B))),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2)))),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(IconData icon, String title, String time, Color color,
      Color bgColor, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                      color: bgColor, borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2)))),
                ),
              ],
            ),
          ),
          Text(time,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF))),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            color:
                isActive ? const Color(0xFF2D9C8D) : const Color(0xFF9CA3AF)),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? const Color(0xFF2D9C8D)
                    : const Color(0xFF9CA3AF))),
      ],
    );
  }
}

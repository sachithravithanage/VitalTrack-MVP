import 'package:flutter/material.dart';
import 'main.dart'; // Needed to access SelectionScreen

class EmptyDashboardScreen extends StatelessWidget {
  const EmptyDashboardScreen({super.key});

  // Navigation function to keep code clean
  void _navigateToAddData(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 20),
                    _buildIllustrationBanner(),
                    const SizedBox(height: 24),
                    _buildEmptyStateCard(context), // Pass context for navigation
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEC5B13).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety, color: Color(0xFFEC5B13), size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'VitalTrack',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Hello Anushka!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ready to check your vitals today?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustrationBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF7EBE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.monitor_heart, size: 64, color: Color(0xFF9CA3AF)),
            SizedBox(height: 8),
            Text('Illustration Placeholder', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEC5B13).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined, color: Color(0xFFEC5B13), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Data Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          const Text(
            "It looks like you haven't tracked anything yet. Start monitoring your health today for better insights.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _navigateToAddData(context), // Triggers Navigation
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4DB6AC), Color(0xFF00695C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF26A69A).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Data',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionIcon(Icons.edit_note, 'Log Symptoms'),
            _buildActionIcon(Icons.history, 'View History'),
            _buildActionIcon(Icons.person_outline, 'Update Info'),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFEC5B13), size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF26A69A),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: FloatingActionButton(
        onPressed: () => _navigateToAddData(context), // Triggers Navigation
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_filled, label: 'Home', isActive: true),
              _buildNavItem(icon: Icons.assignment_outlined, label: 'Log', isActive: false),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(icon: Icons.location_on_outlined, label: 'Map', isActive: false),
              _buildNavItem(icon: Icons.person_outline, label: 'Profile', isActive: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive}) {
    final color = isActive ? const Color(0xFF26A69A) : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
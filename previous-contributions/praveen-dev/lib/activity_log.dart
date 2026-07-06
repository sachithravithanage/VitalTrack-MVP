import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity Log',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2DD4BF), Color(0xFF0E7490)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterTabs(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _buildDateHeader('TODAY, APRIL 24'),
          _buildLogCard(
            icon: Icons.thermostat,
            iconColor: const Color(0xFFF97316),
            iconBgColor: const Color(0xFFFFF7ED),
            title: '98.6°F',
            time: '08:30 AM',
            category: 'Temperature',
            status: 'Stable',
            statusColor: const Color(0xFF0D9488),
          ),
          _buildLogCard(
            icon: Icons.water_drop,
            iconColor: const Color(0xFFEAB308),
            iconBgColor: const Color(0xFFFEFCE8),
            title: '400 ml',
            time: '07:15 AM',
            category: 'Urine Output',
            status: 'Normal',
            statusColor: const Color(0xFF64748B),
          ),
          _buildLogCard(
            icon: Icons.description,
            iconColor: const Color(0xFF3B82F6),
            iconBgColor: const Color(0xFFEFF6FF),
            title: 'Paracetamol 500mg',
            time: '06:00 AM',
            category: 'Notes',
          ),
          const SizedBox(height: 16),
          _buildDateHeader('YESTERDAY, APRIL 23'),
          _buildLogCard(
            icon: Icons.local_drink,
            iconColor: const Color(0xFF06B6D4),
            iconBgColor: const Color(0xFFECFEFF),
            title: '250 ml',
            time: '10:45 PM',
            category: 'Fluid Intake',
            status: 'Water',
            statusColor: const Color(0xFF64748B),
          ),
          _buildLogCard(
            icon: Icons.thermostat,
            iconColor: const Color(0xFFEF4444),
            iconBgColor: const Color(0xFFFEF2F2),
            title: '101.2°F',
            time: '08:20 PM',
            category: 'Temperature',
            status: 'High Fever',
            statusColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['All', 'Platelets', 'Fluid Intake', 'Urine Output', 'Temperature'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: tabs.map((tab) {
            bool isActive = tab == 'All';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFF14B8A6) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLogCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String time,
    required String category,
    String? status,
    Color? statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      category,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: statusColor == const Color(0xFFEF4444) ? FontWeight.bold : FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ]
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: false,
              onTap: () => Navigator.pop(context), // Go back to Dashboard
            ),
            _buildNavItem(
              icon: Icons.assignment,
              label: 'Log',
              isActive: true, // Log is active here
              onTap: () {},
            ),
            _buildNavItem(icon: Icons.location_on, label: 'Map', isActive: false, onTap: () {}),
            _buildNavItem(icon: Icons.person, label: 'Profile', isActive: false, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    final color = isActive ? const Color(0xFF0D9488) : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'leptospirosis_health_data_history.dart';
import 'activity_log.dart';

class LeptoDashboardScreen extends StatelessWidget {
  const LeptoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildPrimaryStatusCard(),
                const SizedBox(height: 24),
                _buildVitalsGrid(context),
                const SizedBox(height: 24),
                const Text(
                  'Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                _buildAlertBanner(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0, top: 4.0),
                child: Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 26),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning,', style: TextStyle(color: Color(0xFF1E293B), fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
                Text('Anushka', style: TextStyle(color: Color(0xFF1E293B), fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
              ],
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?img=5'), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: 0, left: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.eco, size: 16, color: Color(0xFF34D399)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leptospirosis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Stable', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
              )
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.4, minHeight: 6,
              backgroundColor: Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context, tabName: 'Temperature', // Correct mapping
                icon: Icons.thermostat, iconColor: const Color(0xFFEF4444), iconBg: const Color(0xFFFEF2F2),
                label: 'Temperature', value: '98.6°F', unit: '',
                progressColor: const Color(0xFFEF4444), progressValue: 0.7,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                context: context, tabName: 'Blood Pressure', // Correct mapping
                icon: Icons.favorite_border, iconColor: const Color(0xFFF43F5E), iconBg: const Color(0xFFFFF1F2),
                label: 'Blood Pressure', value: '120/80', unit: 'MMHG',
                progressColor: const Color(0xFFF43F5E), progressValue: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSymptomCard(context)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                context: context, tabName: 'Urine Output', // Correct mapping
                icon: Icons.water_drop, iconColor: const Color(0xFFA855F7), iconBg: const Color(0xFFFAF5FF),
                label: 'Urine Output', value: '850 ml', unit: '',
                progressColor: const Color(0xFFA855F7), progressValue: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context, required String tabName,
    required IconData icon, required Color iconColor, required Color iconBg,
    required String label, required String value, required String unit,
    required Color progressColor, required double progressValue,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HealthDataHistoryScreen(initialTab: tabName)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            if (unit.isNotEmpty)
              Text(unit, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue, minHeight: 4,
                backgroundColor: iconBg, valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthDataHistoryScreen(initialTab: 'Symptoms'))); // Correct mapping
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.checklist, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Symptom\nChecklist', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              ],
            ),
            const SizedBox(height: 12),
            const Text('3/5', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const Text('Logged', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _buildBulletPoint('Yellow Eyes'),
            const SizedBox(height: 6),
            _buildBulletPoint('Muscle Pain'),
            const SizedBox(height: 6),
            _buildBulletPoint('Vomiting'),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      children: [
        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Low Hydration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.5, minHeight: 4,
                    backgroundColor: Color(0xFFFEF3C7), valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Text('1 hr ago', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 16),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: const Color(0xFF14B8A6),
        boxShadow: [BoxShadow(color: const Color(0xFF14B8A6).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent, elevation: 0,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: BottomAppBar(
        color: Colors.transparent, elevation: 0,
        shape: const CircularNotchedRectangle(), notchMargin: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(icon: Icons.home, label: 'Home', isActive: true, onTap: () {}),
              _buildNavItem(
                icon: Icons.assignment_outlined, label: 'Log', isActive: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityLogScreen()));
                },
              ),
              const SizedBox(width: 48),
              _buildNavItem(icon: Icons.map_outlined, label: 'Map', isActive: false, onTap: () {}),
              _buildNavItem(icon: Icons.person_outline, label: 'Profile', isActive: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
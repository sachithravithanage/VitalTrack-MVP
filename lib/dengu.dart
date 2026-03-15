import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'health_data_provider.dart'; // Import the provider
import 'dengue_health_data_history.dart';
import 'activity_log.dart';

class DengueDashboardScreen extends StatelessWidget {
  const DengueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. THIS IS THE MAGIC LINE: Watch the provider for live updates!
    final metrics = context.watch<HealthDataProvider>().metricsData;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withValues(alpha: 0.05),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildDengueStatusCard(),
                  const SizedBox(height: 24),
                  // 2. Pass the live metrics to your grid
                  _buildVitalsGrid(context, metrics),
                  const SizedBox(height: 24),
                  _buildRecentAlerts(),
                ],
              ),
            ),
          ],
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
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 22),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Welcome back,', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Anushka', style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?img=5'), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: -4, right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.eco, size: 14, color: Color(0xFF0D9488)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildDengueStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1DD1A1), Color(0xFF10AC84)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.coronavirus_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dengue Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF14B8A6), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Stable Condition', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(50)),
            child: Row(
              children: [
                const Text('RECOVERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1)),
                const SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.65, minHeight: 10,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('65%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))
              ],
            ),
          )
        ],
      ),
    );
  }

  // 3. UPDATED TO USE LIVE DATA FROM THE PROVIDER
  Widget _buildVitalsGrid(BuildContext context, Map<String, MetricConfig> metrics) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
            context: context, tabName: 'Temperature', icon: Icons.thermostat, iconColors: const [Color(0xFFFF6B6B), Color(0xFFEE5253)],
            value: metrics['Temperature']!.currentValue, // Live Value
            unit: metrics['Temperature']!.unit,          // Live Unit
            label: 'Temperature', badgeText: 'Now', badgeColor: const Color(0xFFF1F5F9), badgeTextColor: const Color(0xFF64748B)
        ),
        _buildMetricCard(
            context: context, tabName: 'Platelets', icon: Icons.bubble_chart, iconColors: const [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
            value: metrics['Platelets']!.currentValue,   // Live Value
            unit: metrics['Platelets']!.unit,            // Live Unit
            label: 'Platelets', badgeText: 'Low', badgeColor: const Color(0xFFFFF1F2), badgeTextColor: const Color(0xFFE11D48)
        ),
        _buildMetricCard(
            context: context, tabName: 'Fluid Intake', icon: Icons.local_drink, iconColors: const [Color(0xFF48DBFB), Color(0xFF0ABDE3)],
            value: metrics['Fluid Intake']!.currentValue, // Live Value
            unit: metrics['Fluid Intake']!.unit,          // Live Unit
            label: 'Fluid Intake', badgeText: 'Good', badgeColor: const Color(0xFFF0FDFA), badgeTextColor: const Color(0xFF0D9488)
        ),
        _buildMetricCard(
            context: context, tabName: 'Urine Output', icon: Icons.water_drop, iconColors: const [Color(0xFFFECA57), Color(0xFFFF9F43)],
            value: metrics['Urine Output']!.currentValue, // Live Value
            unit: metrics['Urine Output']!.unit,          // Live Unit
            label: 'Urine Output', badgeText: '--', badgeColor: const Color(0xFFF1F5F9), badgeTextColor: const Color(0xFF64748B)
        ),
      ],
    );
  }

  Widget _buildMetricCard({required BuildContext context, required String tabName, required IconData icon, required List<Color> iconColors, required String value, required String unit, required String label, required String badgeText, required Color badgeColor, required Color badgeTextColor}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HealthDataHistoryScreen(initialTab: tabName)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: iconColors), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
              children: [
                // 4. Wrap text in Flexible to prevent overflow on long numbers
                Flexible(child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 2),
                Text(unit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)))
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0FDFA), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('See All', style: TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: const Border(left: BorderSide(color: Color(0xFF14B8A6), width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: Color(0xFFF0FDFA), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Hydration Goal Met', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Keep up the good work!', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ),
              const Text('5m ago', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500))
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 64, width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: const Color(0xFF26A69A),
        boxShadow: [BoxShadow(color: const Color(0xFF26A69A).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
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
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
                icon: Icons.home, label: 'Home', isActive: true,
                onTap: () {} // Already on Home
            ),
            _buildNavItem(
                icon: Icons.assignment, label: 'Log', isActive: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityLogScreen()));
                }
            ),
            const SizedBox(width: 48), // Space for FAB
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
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}
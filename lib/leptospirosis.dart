import 'package:flutter/material.dart';


class LeptoDashboardScreen extends StatelessWidget {
  const LeptoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background soft gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF0FDFA), Color(0xFFEFF6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),
          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildPrimaryStatusCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(),
                  const SizedBox(height: 16),
                  _buildVitalsGrid(),
                  const SizedBox(height: 20),
                  _buildAlertBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome back,',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Anushka',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900),
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
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                ],
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?img=5'), // Placeholder image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 14, color: Color(0xFF0D9488)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
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
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ]
                ),
                child: const Icon(Icons.pest_control, color: Colors.white, size: 28),
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
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF14B8A6), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCCFBF1))),
                          child: const Text('Monitoring Active', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Risk Level', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    SizedBox(height: 2),
                    Text('Moderate', style: TextStyle(fontSize: 14, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Next Check', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    SizedBox(height: 2),
                    Text('4 Hours', style: TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('RECOVERY PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
              Text('65%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: const [
        Icon(Icons.monitor_heart, color: Color(0xFF14B8A6), size: 24),
        SizedBox(width: 8),
        Text('Vitals & Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildVitalsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildVitalCard(
          icon: Icons.favorite,
          iconColors: const [Color(0xFFFB7185), Color(0xFFEF4444)],
          title: 'BLOOD PRESSURE',
          value: '120/80',
          unit: 'mmHg',
          indicator: _buildProgressBar(const Color(0xFFEF4444), const Color(0xFFFFE4E6), 0.75),
        ),
        _buildVitalCard(
          icon: Icons.assignment_late,
          iconColors: const [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
          title: 'SYMPTOMS',
          value: '3',
          unit: 'Logged',
          indicator: _buildDotsIndicator(const Color(0xFF8B5CF6)),
        ),
        _buildVitalCard(
          icon: Icons.water_drop,
          iconColors: const [Color(0xFFFCD34D), Color(0xFFFACC15)],
          title: 'URINE OUTPUT',
          value: '850',
          unit: 'ml',
          indicator: _buildProgressBar(const Color(0xFFFACC15), const Color(0xFFFEF3C7), 0.6),
        ),
        _buildVitalCard(
          icon: Icons.local_drink,
          iconColors: const [Color(0xFF22D3EE), Color(0xFF06B6D4)],
          title: 'FLUID INTAKE',
          value: '1.2',
          unit: 'L',
          indicator: _buildProgressBar(const Color(0xFF06B6D4), const Color(0xFFCFFAFE), 0.8),
        ),
      ],
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required List<Color> iconColors,
    required String title,
    required String value,
    required String unit,
    required Widget indicator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: iconColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 8),
          indicator,
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color activeColor, Color bgColor, double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: bgColor,
        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
      ),
    );
  }

  Widget _buildDotsIndicator(Color baseColor) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
        Transform.translate(offset: const Offset(-6, 0), child: Container(width: 14, height: 14, decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
        Transform.translate(offset: const Offset(-12, 0), child: Container(width: 14, height: 14, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
      ],
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Low Hydration Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                SizedBox(height: 2),
                Text('Your intake is below target for this hour.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFEF3C7))),
            child: const Text('Details', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: FloatingActionButton(
        onPressed: () {},
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(icon: Icons.home, label: 'Home', isActive: true),
              _buildNavItem(icon: Icons.assignment_outlined, label: 'Log', isActive: false),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(icon: Icons.map_outlined, label: 'Map', isActive: false),
              _buildNavItem(icon: Icons.person_outline, label: 'Profile', isActive: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive}) {
    final color = isActive ? const Color(0xFF0D9488) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
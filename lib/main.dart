import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added Provider import

// Ensure these filenames match your actual file names (lowercase)
import 'dengu.dart';
import 'leptospirosis.dart';
import 'empty_dashboard.dart';
import 'health_data_provider.dart'; // Added HealthDataProvider import

void main() {
  // Wrap the entire app in a MultiProvider so all screens can access the data!
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthDataProvider()),
      ],
      child: const VitalTrackApp(),
    ),
  );
}

class VitalTrackApp extends StatelessWidget {
  const VitalTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitalTrack',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D9C8D),
          primary: const Color(0xFF2D9C8D),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F7FF),
      ),
      // App now starts at the Empty Dashboard after login
      home: const EmptyDashboardScreen(),
    );
  }
}

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  // Logic: Track which condition is selected (default to dengue)
  String selectedCondition = 'dengue';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F7FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Feature: Header Text with Primary Span
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      fontFamily: 'Nunito',
                    ),
                    children: [
                      TextSpan(text: 'What are you\n'),
                      TextSpan(
                        text: 'feeling?',
                        style: TextStyle(color: Color(0xFF2D9C8D)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select your diagnosed condition to start tracking.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // Card 1: Leptospirosis
                _buildConditionCard(
                  id: 'lepto',
                  title: 'Leptospirosis',
                  description: 'Bacterial disease affecting kidneys and liver. Watch for fever and muscle pain.',
                  icon: Icons.pest_control_rodent,
                  iconColor: Colors.orange,
                  gradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                ),
                const SizedBox(height: 16),

                // Card 2: Dengue
                _buildConditionCard(
                  id: 'dengue',
                  title: 'Dengue',
                  description: 'Mosquito-borne viral infection. Monitor platelets and hydration.',
                  icon: Icons.pest_control,
                  iconColor: const Color(0xFF2D9C8D),
                  gradient: const [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
                ),

                const Spacer(),

                // Feature: Gradient "Continue" Button
                Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF2563EB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logic: Navigate based on choice
                      if (selectedCondition == 'dengue') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DengueDashboardScreen())
                        );
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LeptoDashboardScreen())
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    label: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradient,
  }) {
    bool isSelected = selectedCondition == id;

    return GestureDetector(
      onTap: () => setState(() => selectedCondition = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D9C8D) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF2D9C8D), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
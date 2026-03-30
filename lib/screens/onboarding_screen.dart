import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToLanguageSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLanguageSelection,
                child: Text(
                  'Skip',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // PageView for Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Welcome to VitalTrack',
                    description:
                        'Your Health, Our Priority. Let\'s get started on your wellness journey today!',
                    icon: Icons.medical_services_outlined,
                  ),
                  _buildPage(
                    title: 'Your Health, Tracked.',
                    description:
                        'Stay informed and protected with real-time health insights and monitoring.',
                    icon: Icons.track_changes_outlined,
                  ),
                  _buildPage(
                    title: 'Terms & Conditions',
                    description:
                        'Review our policies to ensure your data and privacy are protected. We value your security and transparency.',
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
            ),
            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => buildDot(index, context),
              ),
            ),
            const SizedBox(height: 30),
            // Next / Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFF1B7B85), // Darker teal from your button design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage == 2) {
                      _goToLanguageSelection();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 2 ? 'Get Started' : 'Next',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_currentPage < 2) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
      {required String title,
      required String description,
      required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for your illustrations
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(icon, size: 100, color: const Color(0xFF20B5A0)),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.blueGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index
            ? const Color(0xFF20B5A0)
            : Colors.grey.shade300,
      ),
    );
  }
}

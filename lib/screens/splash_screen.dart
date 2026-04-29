import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'onboarding_screen.dart';
import 'main_layout.dart'; // CHANGED: We now import MainLayout instead of the dashboard
import 'complete_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Show splash screen logo for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (currentUser == null) {
      // Not logged in -> Go to Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // Logged in! Let's check if they have a Firestore profile yet
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists) {
          // Profile exists! Route directly to the MainLayout (which holds the Bottom Nav Bar).
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const MainLayout()), // CHANGED: Route to MainLayout
          );
        } else {
          // They signed up with Firebase Auth, but didn't finish the profile setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const CompleteProfileScreen()),
          );
        }
      } catch (e) {
        // Fallback if network fails
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF20B5A0), Color(0xFF147B85)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite,
                  color: Color(0xFF20B5A0), size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'VitalTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

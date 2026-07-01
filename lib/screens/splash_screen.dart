import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/app_auth_service.dart';
import 'onboarding_screen.dart';
import 'main_layout.dart'; // CHANGED: We now import MainLayout instead of the dashboard
import 'complete_profile_screen.dart';
import 'email_verification_screen.dart';

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

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (currentUser == null) {
      // Not logged in -> Go to Onboarding
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      try {
        await AppAuthService.instance.reloadCurrentUser();
        final verified = await AppAuthService.instance.isCurrentUserVerified();

        if (!mounted) return;

        if (!verified) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const EmailVerificationScreen()),
          );
          return;
        }

        final hasProfile =
            await AppAuthService.instance.currentUserHasProfile();

        if (hasProfile) {
          // Profile exists! Route directly to the MainLayout (which holds the Bottom Nav Bar).
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const MainLayout()), // CHANGED: Route to MainLayout
          );
        } else {
          // They signed up with Firebase Auth, but didn't finish the profile setup
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const CompleteProfileScreen()),
          );
        }
      } catch (e) {
        // Fallback if network fails
        await Navigator.pushReplacement(
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

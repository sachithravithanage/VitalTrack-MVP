import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'main_layout.dart';
import 'two_factor_screen.dart';
// FIX 1: We now import your exact file name!
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- THE REAL EMAIL SENDER ENGINE ---
  Future<bool> _sendRealEmail2FA(String patientEmail, String code) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // FIXED: This is the magic line that makes it work on Mobile!
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': 'service_pm50v4o',
          'template_id': 'template_qbucwvf',
          'user_id': 'G8r2h3EFKJLkV_A7J',
          'template_params': {
            'email': patientEmail,
            'verification_code': code,
          }
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('EmailJS Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Email sending failed: $e');
      return false;
    }
  }

  // --- FORGOT PASSWORD POPUP ENGINE ---
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController =
        TextEditingController(text: _emailController.text.trim());

    await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          bool isSendingReset = false;

          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Reset Password',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your email address and we will send you a secure link to reset your password.',
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF20B5A0), width: 2)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: GoogleFonts.nunito(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B5A0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSendingReset
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter an email address.'),
                                    backgroundColor: Colors.red));
                            return;
                          }

                          setDialogState(() => isSendingReset = true);

                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: email);

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Password reset link sent! Check your inbox.'),
                                  backgroundColor: Color(0xFF20B5A0)),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isSendingReset = false);
                            String msg = 'An error occurred. Please try again.';
                            if (e.code == 'user-not-found') {
                              msg = 'No account found with this email.';
                            }
                            if (e.code == 'invalid-email') {
                              msg = 'Please enter a valid email address.';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red));
                          } catch (e) {
                            setDialogState(() => isSendingReset = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Network error. Please try again.'),
                                    backgroundColor: Colors.red));
                          }
                        },
                  child: isSendingReset
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Send Link',
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ],
            );
          });
        });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final bool requires2FA = doc.data()?['twoFactorEnabled'] ?? false;

      if (requires2FA) {
        final String generatedCode =
            (Random().nextInt(900000) + 100000).toString();
        final DateTime expiresAt =
            DateTime.now().add(const Duration(minutes: 10));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'twoFactorCode': generatedCode,
          'twoFactorPending': true,
          'twoFactorCodeCreatedAt': FieldValue.serverTimestamp(),
          'twoFactorCodeExpiresAt': Timestamp.fromDate(expiresAt),
          'twoFactorAttemptCount': 0,
        });

        final bool emailSent = await _sendRealEmail2FA(
            _emailController.text.trim(), generatedCode);

        if (!mounted) return;

        if (!emailSent) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'twoFactorCode': FieldValue.delete(),
            'twoFactorPending': false,
            'twoFactorCodeCreatedAt': FieldValue.delete(),
            'twoFactorCodeExpiresAt': FieldValue.delete(),
            'twoFactorAttemptCount': FieldValue.delete(),
          });
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Could not send 2FA email. Please contact support.'),
                backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TwoFactorScreen()),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({'twoFactorPending': false}, SetOptions(merge: true));

        if (!mounted) return;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'An error occurred. Please try again.';
      final String rawError = e.toString().toLowerCase();

      if (rawError.contains('invalid-credential') ||
          rawError.contains('user-not-found') ||
          rawError.contains('wrong-password')) {
        errorMessage =
            'Incorrect email or password. Please check your details and try again.';
      } else if (rawError.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (rawError.contains('user-disabled')) {
        errorMessage =
            'This account has been disabled. Please contact support.';
      } else if (rawError.contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later.';
      } else if (rawError.contains('network-request-failed')) {
        errorMessage =
            'No internet connection. Please check your Wi-Fi or data and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage,
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.health_and_safety,
                      size: 48, color: Color(0xFF20B5A0)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to securely access your medical records and track your health.',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: const Color(0xFF64748B),
                      height: 1.5),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle:
                        GoogleFonts.nunito(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFF20B5A0), width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle:
                        GoogleFonts.nunito(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF94A3B8)),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFF20B5A0), width: 2)),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text('Forgot Password?',
                        style: GoogleFonts.nunito(
                            color: const Color(0xFF20B5A0),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Sign In',
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF20B5A0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

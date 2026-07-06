import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_no_data_screen.dart';

class LinkCaretakerScreen extends StatefulWidget {
  const LinkCaretakerScreen({super.key});

  @override
  State<LinkCaretakerScreen> createState() => _LinkCaretakerScreenState();
}

class _LinkCaretakerScreenState extends State<LinkCaretakerScreen> {
  final TextEditingController codeController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Link Caretaker',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Placeholder for the "holding hands" image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(
                    0xFFA17154), // Brownish placeholder color matching your image
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.handshake, size: 80, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connect for Better Care',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your health monitoring with a caretaker or family member. Enter their unique linking code below to grant them access to your Dengue and Rat Fever tracking data.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Linking Code Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Unique Linking Code',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit code',
                hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF20B5A0)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF20B5A0)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Info text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ask your caretaker for their code from the profile section.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Connect Account Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2DD4BF),
                    Color(0xFF0E7490)
                  ], // Teal to dark blue gradient
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2DD4BF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  // 1. Check if the code box is empty
                  if (codeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Please enter the 6-digit linking code.'),
                          backgroundColor: Colors.red),
                    );
                    return; // Stop here!
                  }

                  // 2. If it is NOT empty, go to the dashboard!
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardNoDataScreen(),
                    ),
                    (route) => false, // Clears the navigation stack
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Connect Account',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {},
              child: Text(
                'Need help finding the code?',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

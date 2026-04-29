import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_layout.dart';

class LinkCaretakerScreen extends StatefulWidget {
  const LinkCaretakerScreen({super.key, this.isFromOnboarding = true});
  final bool isFromOnboarding;

  @override
  State<LinkCaretakerScreen> createState() => _LinkCaretakerScreenState();
}

class _LinkCaretakerScreenState extends State<LinkCaretakerScreen> {
  final TextEditingController codeController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingStatus = true;
  String? _connectedCaretakerId;
  String? _connectedCaretakerName;

  @override
  void initState() {
    super.initState();
    _checkCurrentConnection();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  // 1. CHECKS IF THE PATIENT ALREADY HAS A CARETAKER ON LOAD
  Future<void> _checkCurrentConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('linkedCaretakerId') &&
            data['linkedCaretakerId'] != null &&
            data['linkedCaretakerId'].toString().isNotEmpty) {
          final caretakerId = data['linkedCaretakerId'];
          final caretakerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(caretakerId)
              .get();

          if (caretakerDoc.exists && caretakerDoc.data() != null) {
            final caretakerData = caretakerDoc.data() as Map<String, dynamic>;
            setState(() {
              _connectedCaretakerId = caretakerId;
              _connectedCaretakerName =
                  caretakerData['fullName'] ?? 'Unknown Caretaker';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching connection status: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingStatus = false);
      }
    }
  }

  // 2. LOGIC TO LINK A NEW CARETAKER
  Future<void> _linkCaretaker() async {
    // Strips out spaces and invisible characters securely
    final rawCode = codeController.text.toUpperCase();
    final code = rawCode.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 6-character code.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final patient = FirebaseAuth.instance.currentUser;
      if (patient == null) throw Exception('User not authenticated.');

      final caretakerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('caretakerCode', isEqualTo: code)
          .get(const GetOptions(source: Source.server));

      // SECURE FIX: Removed the diagnostic engine. If the code is wrong, it just says so. No leaks!
      if (caretakerQuery.docs.isEmpty) {
        throw Exception(
            'Invalid Caretaker Code. Please check the code and try again.');
      }

      final caretakerDoc = caretakerQuery.docs.first;

      if (caretakerDoc.id == patient.uid) {
        throw Exception('You cannot link your own account.');
      }

      // Firebase Batch Write guarantees both accounts link at the exact same millisecond
      final batch = FirebaseFirestore.instance.batch();

      final patientRef =
          FirebaseFirestore.instance.collection('users').doc(patient.uid);
      final caretakerRef =
          FirebaseFirestore.instance.collection('users').doc(caretakerDoc.id);

      batch.update(patientRef, {'linkedCaretakerId': caretakerDoc.id});
      batch.update(caretakerRef, {
        'linkedPatients': FieldValue.arrayUnion([patient.uid])
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Successfully linked to Caretaker!'),
            backgroundColor: Colors.green),
      );

      final caretakerData = caretakerDoc.data();

      if (widget.isFromOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      } else {
        setState(() {
          _connectedCaretakerId = caretakerDoc.id;
          _connectedCaretakerName = caretakerData['fullName'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red),
      );
    }
  }

  // 3. LOGIC TO REMOVE AN EXISTING CARETAKER
  Future<void> _removeCaretaker() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Remove Caretaker?',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text(
              'This person will no longer be able to view or update your medical data.',
              style: GoogleFonts.nunito(color: Colors.blueGrey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(
                      color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Remove',
                  style: GoogleFonts.nunito(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final patientId = FirebaseAuth.instance.currentUser!.uid;

      final batch = FirebaseFirestore.instance.batch();
      final patientRef =
          FirebaseFirestore.instance.collection('users').doc(patientId);
      final caretakerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_connectedCaretakerId);

      batch.update(patientRef, {'linkedCaretakerId': FieldValue.delete()});
      batch.update(caretakerRef, {
        'linkedPatients': FieldValue.arrayRemove([patientId])
      });

      await batch.commit();

      setState(() {
        _connectedCaretakerId = null;
        _connectedCaretakerName = null;
        codeController.clear();
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Caretaker removed successfully.'),
            backgroundColor: Colors.blueGrey),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            _connectedCaretakerId != null ? 'My Caretaker' : 'Link Caretaker',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A))),
      ),
      body: _isFetchingStatus
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF20B5A0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _connectedCaretakerId != null
                  ? _buildLinkedUI()
                  : _buildUnlinkedUI(),
            ),
    );
  }

  Widget _buildLinkedUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF20B5A0).withOpacity(0.3), width: 4),
            ),
            child: const Icon(Icons.verified_user,
                size: 60, color: Color(0xFF20B5A0)),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text('Caretaker Connected',
              style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A))),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Your health data is currently being monitored by:',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 16, color: const Color(0xFF64748B), height: 1.5)),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.medical_services,
                    color: Color(0xFF1B7B85), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_connectedCaretakerName ?? 'Loading...',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A))),
                    Text('Authorized Caretaker',
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF20B5A0),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _removeCaretaker,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.red)
                : Text('Remove Connection',
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinkedUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.handshake_outlined,
              size: 60, color: Color(0xFF20B5A0)),
        ),
        const SizedBox(height: 32),
        Text('Link a Caretaker',
            style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Text(
            'Enter the 6-character code provided by your family member or doctor to let them monitor your health data.',
            style: GoogleFonts.nunito(
                fontSize: 16, color: const Color(0xFF64748B), height: 1.5)),
        const SizedBox(height: 40),
        TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          style: GoogleFonts.nunito(
              fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'XXXXXX',
            hintStyle: GoogleFonts.nunito(
                color: Colors.grey.shade400, letterSpacing: 8),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF20B5A0), width: 2)),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _linkCaretaker,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Connect Account',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        if (widget.isFromOnboarding)
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainLayout()),
                  (route) => false,
                );
              },
              child: Text('Skip for now',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

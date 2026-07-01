import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_patient_screen.dart';
import '../providers/patient_provider.dart';
import '../models/user_profile.dart';
import 'dengue_patient_history_screen.dart';
import 'leptospirosis_patient_history_screen.dart';

class PatientConnectionsScreen extends StatefulWidget {
  const PatientConnectionsScreen({super.key});

  @override
  State<PatientConnectionsScreen> createState() =>
      _PatientConnectionsScreenState();
}

class _PatientConnectionsScreenState extends State<PatientConnectionsScreen> {
  bool _isLoading = false;

  // --- YOUR EXACT ROUTING LOGIC (Untouched!) ---
  Future<void> _openPatientDashboard(UserProfile patient) async {
    setState(() => _isLoading = true);

    // 1. Tell the app which patient the Caretaker just clicked
    final provider = context.read<PatientProvider>();
    await provider.setActivePatient(patient);

    setState(() => _isLoading = false);

    if (!mounted) return;

    // 2. Route to the correct dashboard based on their active illness!
    final episode = provider.activeEpisode;
    if (episode != null && episode.isActive) {
      if (episode.diseaseName == 'Dengue') {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const DenguePatientHistoryScreen()));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const LeptospirosisPatientHistoryScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This patient currently has no active illness.'),
            backgroundColor: Colors.blueGrey),
      );
    }
  }

  Future<void> _editPatient(UserProfile patient) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddPatientScreen(patient: patient),
      ),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deletePatientTree(String patientId) async {
    final firestore = FirebaseFirestore.instance;

    final episodesSnapshot = await firestore
        .collection('users')
        .doc(patientId)
        .collection('episodes')
        .get();

    for (final episodeDoc in episodesSnapshot.docs) {
      final logsSnapshot = await episodeDoc.reference.collection('logs').get();
      for (final logDoc in logsSnapshot.docs) {
        await logDoc.reference.delete();
      }
      await episodeDoc.reference.delete();
    }

    final leptoLogsSnapshot = await firestore
        .collection('users')
        .doc(patientId)
        .collection('lepto_logs')
        .get();

    for (final logDoc in leptoLogsSnapshot.docs) {
      await logDoc.reference.delete();
    }
  }

  Future<void> _deletePatient(UserProfile patient) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Patient?',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text(
            'This will permanently remove the patient profile, logs, and episodes from your account.',
            style: GoogleFonts.nunito(color: const Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Delete',
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
      final caretaker = FirebaseAuth.instance.currentUser;
      if (caretaker == null) {
        throw Exception('You must be signed in to delete a patient.');
      }

      await _deletePatientTree(patient.uid);

      final batch = FirebaseFirestore.instance.batch();
      final caretakerRef =
          FirebaseFirestore.instance.collection('users').doc(caretaker.uid);
      final patientRef =
          FirebaseFirestore.instance.collection('users').doc(patient.uid);

      batch.update(caretakerRef, {
        'linkedPatients': FieldValue.arrayRemove([patient.uid]),
      });
      batch.delete(patientRef);
      await batch.commit();

      final provider = context.read<PatientProvider>();
      if (provider.activePatient?.uid == patient.uid) {
        provider.clearActivePatient();
      }
      await provider.refreshCurrentUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient deleted successfully.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final currentUser = provider.currentUser;

    // Get the first name for a friendly greeting
    String firstName = currentUser?.fullName.split(' ').first ?? 'Caretaker';
    int patientCount = currentUser?.linkedPatients.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF20B5A0)))
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // --- BEAUTIFUL PREMIUM HEADER ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good Morning,',
                                    style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    firstName,
                                    style: GoogleFonts.nunito(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Color(0xFF0F172A)),
                              )
                            ],
                          ),
                          const SizedBox(height: 32),

                          // --- STATS OVERVIEW CARD ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF20B5A0), Color(0xFF0E7490)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF20B5A0)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.people_alt_outlined,
                                      color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$patientCount Active Patients',
                                        style: GoogleFonts.nunito(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        patientCount == 0
                                            ? 'Share your code to connect.'
                                            : 'You are monitoring their vitals.',
                                        style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          Text(
                            'My Patients',
                            style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // --- LIST OF PATIENTS (Using your Firebase Logic!) ---
                  if (currentUser == null || currentUser.linkedPatients.isEmpty)
                    SliverToBoxAdapter(child: _buildNoPatientsState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            String patientId =
                                currentUser.linkedPatients[index];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 16.0),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: Color(0xFF20B5A0))),
                                  );
                                }
                                if (!snapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                final patientData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final patientProfile =
                                    UserProfile.fromFirestore(
                                        patientData, snapshot.data!.id);

                                // Fetch their active episode for UI styling
                                return FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(patientProfile.uid)
                                      .collection('episodes')
                                      .where('isActive', isEqualTo: true)
                                      .limit(1)
                                      .get(),
                                  builder: (context, episodeSnapshot) {
                                    String illness = 'Healthy / Recovered';

                                    if (episodeSnapshot.hasData &&
                                        episodeSnapshot.data!.docs.isNotEmpty) {
                                      final epData = episodeSnapshot
                                          .data!.docs.first
                                          .data() as Map<String, dynamic>;
                                      illness =
                                          epData['diseaseName'] ?? 'Unknown';
                                    }

                                    return _buildPatientCard(
                                        patientProfile, illness);
                                  },
                                );
                              },
                            );
                          },
                          childCount: currentUser.linkedPatients.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  // --- EMPTY STATE UI ---
  Widget _buildNoPatientsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_disabled_outlined,
                  size: 60, color: Color(0xFF20B5A0)),
            ),
            const SizedBox(height: 24),
            Text('No Connected Patients',
                style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Text(
                'You can link an existing patient with your Caretaker Code or add a new patient from your Profile settings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 16, color: const Color(0xFF64748B), height: 1.5)),
          ],
        ),
      ),
    );
  }

  // --- PREMIUM PATIENT CARD UI ---
  Widget _buildPatientCard(UserProfile patientProfile, String illness) {
    bool isDengue = illness == 'Dengue';
    bool isHealthy = illness == 'Healthy / Recovered';

    // Dynamic styling based on the disease
    Color diseaseColor = isHealthy
        ? Colors.grey
        : (isDengue ? const Color(0xFF20B5A0) : const Color(0xFFEC5B13));
    IconData diseaseIcon = isHealthy
        ? Icons.check_circle
        : (isDengue ? Icons.water_drop : Icons.warning_amber_rounded);

    return GestureDetector(
      onTap: () => _openPatientDashboard(patientProfile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8)),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          children: [
            // Top Row: Avatar & Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: diseaseColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patientProfile.fullName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: diseaseColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientProfile.fullName,
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: diseaseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(diseaseIcon, size: 14, color: diseaseColor),
                            const SizedBox(width: 4),
                            Text(
                              illness,
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: diseaseColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon:
                          const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPatient(patientProfile);
                        } else if (value == 'delete') {
                          _deletePatient(patientProfile);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit Patient'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Patient'),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1)),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_heart,
                        size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'Monitoring Vitals',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  'View Dashboard',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

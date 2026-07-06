import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final currentUser = provider.currentUser;

    // Get the first name for a friendly greeting
    final String firstName =
        currentUser?.fullName.split(' ').first ?? 'Caretaker';
    final int patientCount = currentUser?.linkedPatients.length ?? 0;

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
                      padding: const EdgeInsets.all(24),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final String patientId =
                                currentUser.linkedPatients[index];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1),
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
                'To monitor a patient, give them your unique Caretaker Code from your Profile settings.',
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
    final bool isDengue = illness == 'Dengue';
    final bool isHealthy = illness == 'Healthy / Recovered';

    // Dynamic styling based on the disease
    final Color diseaseColor = isHealthy
        ? Colors.grey
        : (isDengue ? const Color(0xFF20B5A0) : const Color(0xFFEC5B13));
    final IconData diseaseIcon = isHealthy
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
                      // Beautiful Disease Badge
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
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1)),
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

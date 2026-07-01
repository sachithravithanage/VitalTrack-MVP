import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../providers/patient_provider.dart';
import '../models/user_profile.dart';
import '../models/disease_episode.dart';
import 'add_patient_screen.dart';
import 'dengue_patient_history_screen.dart';
import 'leptospirosis_patient_history_screen.dart';
import 'patient_connections_screen.dart';
import 'profile_screen.dart';

class DashboardNoDataScreen extends StatelessWidget {
  const DashboardNoDataScreen({super.key});

  // Fetch past recovered illnesses securely
  Future<List<DiseaseEpisode>> _fetchPastEpisodes(String uid) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('episodes')
        .where('isActive', isEqualTo: false)
        .orderBy('endDate', descending: true)
        .get();

    return query.docs
        .map((doc) => DiseaseEpisode.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final user = provider.currentUser;

    if (user == null) {
      return const SizedBox.shrink(); // Failsafe
    }

    final lastName = user.fullName.trim().split(' ').last;
    final isCaretaker = user.role == 'Caretaker';

    if (isCaretaker) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F6F6),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF20B5A0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.favorite, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'VitalTrack',
                style: GoogleFonts.publicSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.notifications_none, color: Colors.blueGrey),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $lastName!',
                style: GoogleFonts.publicSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here is the status of your connected patients.',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF20B5A0), Color(0xFF147B85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.people_alt_outlined,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.linkedPatients.length} Active Patients',
                            style: GoogleFonts.publicSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.linkedPatients.isEmpty
                                ? 'Share your code or add a patient from Profile.'
                                : 'You are monitoring their vitals.',
                            style: GoogleFonts.publicSans(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'My Patients',
                style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              if (user.linkedPatients.isEmpty)
                _buildCaretakerEmptyState(context)
              else
                FutureBuilder<List<_CaretakerPatientItem>>(
                  future: _fetchCaretakerPatients(user.linkedPatients),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              color: Color(0xFF20B5A0)),
                        ),
                      );
                    }

                    final patients = snapshot.data!;
                    if (patients.isEmpty) {
                      return _buildCaretakerEmptyState(context);
                    }

                    return Column(
                      children: patients
                          .map((patient) =>
                              _buildCaretakerPatientCard(context, patient))
                          .toList(),
                    );
                  },
                ),
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: GoogleFonts.publicSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCaretakerQuickAction(
                      Icons.person_add_alt_1, 'Add Patient', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddPatientScreen()),
                    );
                  }),
                  _buildCaretakerQuickAction(Icons.people, 'Patients', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const PatientConnectionsScreen()),
                    );
                  }),
                  _buildCaretakerQuickAction(Icons.person_outline, 'Profile',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF20B5A0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'VitalTrack',
              style: GoogleFonts.publicSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.blueGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $lastName!',
              style: GoogleFonts.publicSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You currently have no active health tracking.',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Hero Illustration Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EE),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF20B5A0).withOpacity(0.1)),
              ),
              child: const Center(
                child: Icon(Icons.medical_information,
                    size: 80, color: Color(0xFF20B5A0)),
              ),
            ),
            const SizedBox(height: 24),

            // DYNAMIC SECTION: Past Records vs No Data Yet
            FutureBuilder<List<DiseaseEpisode>>(
              future: _fetchPastEpisodes(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pastEpisodes = snapshot.data ?? [];

                if (pastEpisodes.isEmpty) {
                  return _buildNoDataCard();
                } else {
                  return _buildPastRecordsCard(pastEpisodes);
                }
              },
            ),

            const SizedBox(height: 32),

            // Quick Actions (Restored to perfectly match your design)
            Text(
              'Quick Actions',
              style: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(Icons.edit_note, 'Log Symptoms'),
                _buildQuickAction(Icons.history, 'View History'),
                _buildQuickAction(Icons.person_outline, 'Update Info'),
              ],
            ),

            const SizedBox(height: 80), // Padding to prevent hiding behind FAB
          ],
        ),
      ),
    );
  }

  Future<List<_CaretakerPatientItem>> _fetchCaretakerPatients(
      List<String> ids) async {
    final items = <_CaretakerPatientItem>[];

    for (final patientId in ids) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      if (!doc.exists || doc.data() == null) continue;

      final patient = UserProfile.fromFirestore(doc.data()!, doc.id);
      final episodeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('episodes')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      String illness = 'Healthy / Recovered';
      if (episodeDoc.docs.isNotEmpty) {
        illness = episodeDoc.docs.first.data()['diseaseName'] ?? illness;
      }

      items.add(_CaretakerPatientItem(patient: patient, illness: illness));
    }

    return items;
  }

  Widget _buildCaretakerEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_disabled_outlined,
                size: 60, color: Color(0xFF20B5A0)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Connected Patients',
            style: GoogleFonts.publicSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a patient from your Profile or share your caretaker code to start monitoring.',
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaretakerPatientCard(
      BuildContext context, _CaretakerPatientItem item) {
    final isDengue = item.illness == 'Dengue';
    final isHealthy = item.illness == 'Healthy / Recovered';
    final color = isHealthy
        ? Colors.grey
        : (isDengue ? const Color(0xFF147B85) : Colors.orange);

    return GestureDetector(
      onTap: () {
        if (item.illness == 'Dengue') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DenguePatientHistoryScreen(),
            ),
          );
        } else if (item.illness == 'Leptospirosis') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeptospirosisPatientHistoryScreen(),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.person, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.patient.fullName,
                    style: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    item.illness,
                    style: GoogleFonts.publicSans(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isHealthy ? 'Recovered' : 'View',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCaretakerQuickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF20B5A0)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEC5B13).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined,
                color: Color(0xFFEC5B13), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Yet',
            style: GoogleFonts.publicSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'It looks like you haven\'t tracked anything yet. Click the + button below if you get sick.',
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastRecordsCard(List<DiseaseEpisode> pastEpisodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Past Medical Records',
          style: GoogleFonts.publicSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ...pastEpisodes.map((episode) {
          final color = episode.diseaseName == 'Dengue'
              ? const Color(0xFF147B85)
              : Colors.orange;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recovered from ${episode.diseaseName}',
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ended: ${DateFormat('MMM dd, yyyy').format(episode.endDate ?? DateTime.now())}',
                        style: GoogleFonts.publicSans(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Restored your exact Quick Action design block
  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: const Color(0xFFEC5B13), size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

class _CaretakerPatientItem {
  final UserProfile patient;
  final String illness;

  _CaretakerPatientItem({required this.patient, required this.illness});
}

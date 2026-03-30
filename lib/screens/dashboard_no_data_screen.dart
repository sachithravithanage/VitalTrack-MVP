import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../providers/patient_provider.dart';
import '../models/disease_episode.dart';
import 'illness_selection_screen.dart'; // Needed if you want to link Quick Actions

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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/disease_episode.dart';

class PatientProvider extends ChangeNotifier {
  PatientProvider() {
    _initAuthListener();
  }
  UserProfile? currentUser;
  UserProfile? activePatient; // The patient whose data we are currently viewing
  DiseaseEpisode? activeEpisode;
  bool isLoading = true;

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchCurrentUser(user.uid);
      } else {
        currentUser = null;
        activePatient = null;
        activeEpisode = null;
        isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchCurrentUser(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        currentUser = UserProfile.fromFirestore(doc.data()!, uid);

        // If the logged-in user is a Patient, they are their own active patient
        if (currentUser!.role == 'Patient') {
          await setActivePatient(currentUser!);
        } else {
          // If it's a Caretaker, we wait for them to select a patient from the UI
          activePatient = null;
          activeEpisode = null;
          isLoading = false;
          notifyListeners();
        }
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  // Caretakers call this when they click on a patient card
  Future<void> setActivePatientById(String patientUid) async {
    isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientUid)
          .get();
      if (doc.exists && doc.data() != null) {
        final patientProfile =
            UserProfile.fromFirestore(doc.data()!, patientUid);
        await setActivePatient(patientProfile);
      }
    } catch (e) {
      debugPrint('Error fetching patient: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Sets the active patient and finds their current active sickness
  Future<void> setActivePatient(UserProfile patient) async {
    activePatient = patient;

    try {
      final episodesQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(patient.uid)
          .collection('episodes')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (episodesQuery.docs.isNotEmpty) {
        activeEpisode = DiseaseEpisode.fromFirestore(
            episodesQuery.docs.first.data(), episodesQuery.docs.first.id);
      } else {
        activeEpisode = null; // Patient is healthy / recovered
      }
    } catch (e) {
      debugPrint('Error fetching episode: $e');
      activeEpisode = null;
    }

    isLoading = false;
    notifyListeners();
  }

  // Start a new sickness (e.g., from IllnessSelectionScreen)
  Future<void> startNewEpisode(String diseaseName, DateTime startDate) async {
    if (activePatient == null) return;

    isLoading = true;
    notifyListeners();

    try {
      // 1. Mark any existing episodes as recovered
      final existingEpisodes = await FirebaseFirestore.instance
          .collection('users')
          .doc(activePatient!.uid)
          .collection('episodes')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in existingEpisodes.docs) {
        await doc.reference.update(
            {'isActive': false, 'endDate': FieldValue.serverTimestamp()});
      }

      // 2. Create the new episode
      final newEpisodeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(activePatient!.uid)
          .collection('episodes')
          .doc(); // Auto-generate ID

      final newEpisode = DiseaseEpisode(
        id: newEpisodeRef.id,
        diseaseName: diseaseName,
        startDate: startDate,
        isActive: true,
      );

      await newEpisodeRef.set(newEpisode.toFirestore());
      activeEpisode = newEpisode;
    } catch (e) {
      debugPrint('Error starting new episode: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Mark patient as recovered
  Future<void> markAsRecovered() async {
    if (activePatient == null || activeEpisode == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(activePatient!.uid)
          .collection('episodes')
          .doc(activeEpisode!.id)
          .update({
        'isActive': false,
        'endDate': FieldValue.serverTimestamp(),
      });
      activeEpisode = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error recovering patient: $e');
    }
  }
}

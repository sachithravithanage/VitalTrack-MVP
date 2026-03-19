import 'package:flutter/material.dart';
import '../services/index.dart';
import 'localization.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppLanguage? selectedLanguage;
  UserProfileData? currentUser;

  final Map<String, List<RecordEntry>> _recordsByPatient =
      <String, List<RecordEntry>>{};
  final Map<String, List<PatientSummary>> _caregiverPatients =
      <String, List<PatientSummary>>{};
  final Map<String, List<Map<String, dynamic>>> _caregiversByPatient =
      <String, List<Map<String, dynamic>>>{};
  final List<HotspotResponse> _hotspots = <HotspotResponse>[];

  String t(String key) {
    final bool isSi = selectedLanguage == AppLanguage.sinhala;
    return localized[key]?[isSi ? 'si' : 'en'] ?? key;
  }

  void setLanguage(AppLanguage language) {
    selectedLanguage = language;
    notifyListeners();
  }

  /// Initialize user from local storage (on app startup)
  void initializeUser() {
    final userData = authService.getCurrentUser();
    if (userData != null) {
      currentUser = UserProfileData(
        id: userData['id'] ?? userData['uid'] ?? '',
        role: _parseUserRole(userData['role']),
        name: userData['name'] ?? '',
        phone: userData['phone'] ?? '',
        email: userData['email'],
        emailVerified: userData['emailVerified'] == true,
      );
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<void> login({
    required String credential,
    required String password,
  }) async {
    try {
      final response = await authService.login(
        credential: credential,
        password: password,
      );

      if (response['user'] != null) {
        final userData = response['user'] as Map<String, dynamic>;
        currentUser = UserProfileData(
          id: userData['id'] ?? userData['uid'] ?? '',
          role: _parseUserRole(userData['role']),
          name: userData['name'] ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'],
          emailVerified: userData['emailVerified'] == true,
        );
        notifyListeners();

        // Reload user data after successful login
        await reloadUserData();
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  /// Sign up with new account
  Future<void> signup({
    String? email,
    required String phone,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await authService.signUp(
        email: email,
        phone: phone,
        password: password,
        name: name,
        role: role,
      );

      if (response['user'] != null) {
        final userData = response['user'] as Map<String, dynamic>;
        currentUser = UserProfileData(
          id: userData['id'] ?? userData['uid'] ?? '',
          role: _parseUserRole(userData['role']),
          name: userData['name'] ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'],
          emailVerified: userData['emailVerified'] == true,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await authService.logout();
      currentUser = null;
      _recordsByPatient.clear();
      _caregiverPatients.clear();
      _caregiversByPatient.clear();
      _hotspots.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  /// Reload user data after login (records, patients/caregivers, hotspots)
  Future<void> reloadUserData() async {
    try {
      if (currentUser == null) return;

      // Load patient records
      await loadPatientRecords(currentUser!.id);

      // Load relationships based on role
      if (currentUser!.role == UserRole.caregiver) {
        // Caregivers: load their patients
        await loadCaregiverPatients();
      } else {
        // Patients: load linked caregivers
        await loadPatientCaregivers();
      }

      // Load hotspot data
      await loadPatientHotspots(currentUser!.id);
    } catch (e) {
      debugPrint('Error reloading user data: $e');
      // Don't rethrow - this is optional data
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final response = await authService.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );

      final userData = response['profile'] ?? response['user'];
      if (userData is Map<String, dynamic> && currentUser != null) {
        currentUser!.name = userData['name'] ?? '';
        currentUser!.phone = userData['phone'] ?? '';
        currentUser!.email = userData['email'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  /// Mark email as verified
  void markEmailVerified() {
    if (currentUser != null) {
      currentUser!.emailVerified = true;
      notifyListeners();
    }
  }

  /// Parse user role string
  UserRole _parseUserRole(dynamic roleValue) {
    if (roleValue is String) {
      return roleValue.toLowerCase() == 'caregiver'
          ? UserRole.caregiver
          : UserRole.patient;
    }
    return UserRole.patient;
  }

  // ============ Medical Records ============

  /// Add a new medical record via backend
  Future<void> addRecord({
    String? patientId,
    required String disease,
    required String temperature,
    String? fluidIntake,
    String? urineOutput,
    String? urineColor,
    Map<String, bool>? symptoms,
    String? notes,
  }) async {
    try {
      if (currentUser == null) throw Exception('User not logged in');

      final String targetPatientId = patientId ?? currentUser!.id;

      final response = await recordService.createRecord(
        patientId: targetPatientId,
        disease: disease,
        temperature: temperature,
        fluidIntake: fluidIntake,
        urineOutput: urineOutput,
        urineColor: urineColor,
        symptoms: symptoms,
        notes: notes,
      );

      // Add to local cache
      if (response['record'] != null) {
        final diseaseEnum =
            disease == 'ratFever' || disease.toLowerCase().contains('rat')
            ? DiseaseType.ratFever
            : DiseaseType.dengue;
        final record = RecordEntry(
          patientId: targetPatientId,
          disease: diseaseEnum,
          createdAt: DateTime.now(),
          values: {
            'temperature': temperature.toString(),
            'fluidIntake': fluidIntake?.toString() ?? '',
            'urineOutput': urineOutput?.toString() ?? '',
            'urineColor': urineColor ?? '',
            if (symptoms != null)
              ...symptoms.entries.fold<Map<String, String>>(
                <String, String>{},
                (map, entry) => {...map, entry.key: entry.value.toString()},
              ),
          },
          notes: notes ?? '',
          createdBy: currentUser!.id,
        );

        final list = _recordsByPatient.putIfAbsent(
          targetPatientId,
          () => <RecordEntry>[],
        );
        list.add(record);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Add record error: $e');
      rethrow;
    }
  }

  /// Load patient records from backend
  Future<void> loadPatientRecords(
    String patientId, {
    TimelineFilter filter = TimelineFilter.last7Days,
    String? disease,
  }) async {
    try {
      final response = await recordService.listRecords(
        patientId: patientId,
        timelineFilter: _filterToString(filter),
        disease: disease,
      );

      if (response['records'] != null) {
        final records = response['records'] as List<dynamic>;
        final recordList = records.map((r) {
          final recordData = r as Map<String, dynamic>;
          final diseaseStr = recordData['disease'] ?? '';
          final diseaseParsed =
              diseaseStr == 'ratFever' ||
                  diseaseStr.toLowerCase().contains('rat')
              ? DiseaseType.ratFever
              : DiseaseType.dengue;
          return RecordEntry(
            patientId: recordData['patientId'] ?? '',
            disease: diseaseParsed,
            createdAt: _parseTimestamp(recordData['createdAt']),
            values: {
              'temperature': recordData['temperature']?.toString() ?? '',
              'fluidIntake': recordData['fluidIntake']?.toString() ?? '',
              'urineOutput': recordData['urineOutput']?.toString() ?? '',
              'urineColor': recordData['urineColor']?.toString() ?? '',
              if (recordData['symptoms'] is Map)
                ...(recordData['symptoms'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
            },
            notes: recordData['notes']?.toString() ?? '',
            createdBy: recordData['createdBy'] ?? '',
          );
        }).toList();

        _recordsByPatient[patientId] = recordList;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load patient records error: $e');
      rethrow;
    }
  }

  /// Get filtered records for a patient
  List<RecordEntry> filteredRecords(String patientId, TimelineFilter filter) {
    final List<RecordEntry> source =
        _recordsByPatient[patientId] ?? <RecordEntry>[];
    final DateTime now = DateTime.now();
    Duration window;
    switch (filter) {
      case TimelineFilter.last24h:
        window = const Duration(hours: 24);
      case TimelineFilter.last3Days:
        window = const Duration(days: 3);
      case TimelineFilter.last7Days:
        window = const Duration(days: 7);
    }
    final DateTime minTime = now.subtract(window);
    return source
        .where((RecordEntry r) => r.createdAt.isAfter(minTime))
        .toList()
      ..sort(
        (RecordEntry a, RecordEntry b) => b.createdAt.compareTo(a.createdAt),
      );
  }

  /// Export records as PDF
  Future<String> exportRecordsPdf({
    TimelineFilter filter = TimelineFilter.last7Days,
    String? patientId,
  }) async {
    try {
      final response = await recordService.exportRecordsPdf(
        timelineFilter: _filterToString(filter),
        patientId: patientId,
      );
      final pdf = response['pdf'] as Map<String, dynamic>?;
      // Returns signed URL or file path
      return response['url'] ??
          response['filePath'] ??
          pdf?['url'] ??
          pdf?['filePath'] ??
          '';
    } catch (e) {
      debugPrint('Export records error: $e');
      rethrow;
    }
  }

  // ============ Relationships ============

  /// Generate link code for caregiver
  Future<String> generateCaregiverCode() async {
    try {
      final code = await relationshipService.generateLinkCode();
      return code;
    } catch (e) {
      debugPrint('Generate link code error: $e');
      rethrow;
    }
  }

  /// Add patient using link code (caregiver)
  Future<void> attachPatientToCaregiver({
    required String code,
    String? disease,
  }) async {
    try {
      if (currentUser == null) throw Exception('User not logged in');

      final response = await relationshipService.addPatient(
        code: code,
        disease: disease,
      );

      if (response['relationship'] != null) {
        final patientData = response['relationship'] as Map<String, dynamic>;
        final diseaseStr = patientData['disease'] ?? disease ?? '';
        final diseaseParsed =
            diseaseStr == 'ratFever' || diseaseStr.toLowerCase().contains('rat')
            ? DiseaseType.ratFever
            : DiseaseType.dengue;
        final patient = PatientSummary(
          id: patientData['patientId'] ?? '',
          name: patientData['patientName'] ?? '',
          disease: diseaseParsed,
          linkCode: code,
        );

        final patients = _caregiverPatients.putIfAbsent(
          currentUser!.id,
          () => <PatientSummary>[],
        );
        patients.add(patient);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Attach patient error: $e');
      rethrow;
    }
  }

  /// Caregiver creates a managed patient profile and links it immediately
  Future<void> createManagedPatient({
    required String name,
    required String disease,
  }) async {
    try {
      if (currentUser == null) throw Exception('User not logged in');

      final response = await relationshipService.createPatient(
        name: name,
        disease: disease,
      );

      if (response['relationship'] != null) {
        final patientData = response['relationship'] as Map<String, dynamic>;
        final diseaseStr = patientData['disease'] ?? disease;
        final diseaseParsed =
            diseaseStr == 'ratFever' || diseaseStr.toLowerCase().contains('rat')
            ? DiseaseType.ratFever
            : DiseaseType.dengue;

        final patient = PatientSummary(
          id: patientData['patientId'] ?? '',
          name: patientData['patientName'] ?? '',
          disease: diseaseParsed,
        );

        final patients = _caregiverPatients.putIfAbsent(
          currentUser!.id,
          () => <PatientSummary>[],
        );
        patients.add(patient);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Create managed patient error: $e');
      rethrow;
    }
  }

  /// Get patients for caregiver
  Future<void> loadCaregiverPatients() async {
    try {
      if (currentUser == null) throw Exception('User not logged in');

      final patientsList = await relationshipService.getPatients();
      final patients = patientsList.map((p) {
        final patientData = p as Map<String, dynamic>;
        final diseaseStr = patientData['disease'] ?? '';
        final diseaseParsed =
            diseaseStr == 'ratFever' || diseaseStr.toLowerCase().contains('rat')
            ? DiseaseType.ratFever
            : DiseaseType.dengue;
        return PatientSummary(
          id: patientData['id'] ?? patientData['uid'] ?? '',
          name: patientData['name'] ?? '',
          disease: diseaseParsed,
          linkCode: patientData['linkCode'],
        );
      }).toList();

      _caregiverPatients[currentUser!.id] = patients;
      notifyListeners();
    } catch (e) {
      debugPrint('Load caregiver patients error: $e');
      rethrow;
    }
  }

  /// Get caregivers for patient
  Future<List<dynamic>> getCaregivers() async {
    try {
      return await relationshipService.getCaregivers();
    } catch (e) {
      debugPrint('Get caregivers error: $e');
      rethrow;
    }
  }

  /// Load linked caregivers for the current patient
  Future<void> loadPatientCaregivers() async {
    try {
      if (currentUser == null) throw Exception('User not logged in');

      final caregiversList = await relationshipService.getCaregivers();
      final caregivers = caregiversList.map((c) {
        final caregiverData = c as Map<String, dynamic>;
        return <String, dynamic>{
          'id': caregiverData['id'] ?? caregiverData['uid'] ?? '',
          'name': caregiverData['name'] ?? '',
          'email': caregiverData['email'],
          'phone': caregiverData['phone'],
        };
      }).toList();

      _caregiversByPatient[currentUser!.id] = caregivers;
      notifyListeners();
    } catch (e) {
      debugPrint('Load patient caregivers error: $e');
      rethrow;
    }
  }

  /// Get caregivers for a patient
  List<Map<String, dynamic>> patientCaregivers(String patientId) {
    return List<Map<String, dynamic>>.unmodifiable(
      _caregiversByPatient[patientId] ?? <Map<String, dynamic>>[],
    );
  }

  /// Get list of patients for caregiver
  List<PatientSummary> caregiverPatients(String caregiverId) {
    return List<PatientSummary>.unmodifiable(
      _caregiverPatients[caregiverId] ?? <PatientSummary>[],
    );
  }

  // ============ Hotspots ============

  /// Submit hotspot data
  Future<void> submitHotspot({
    required String subject,
    required String hometown,
    required String workplace,
    String? places,
    String? disease,
    Map<String, double>? coordinates,
  }) async {
    try {
      final response = await hotspotService.submitHotspot(
        subject: subject,
        hometown: hometown,
        workplace: workplace,
        places: places,
        disease: disease,
        coordinates: coordinates,
      );

      if (response['hotspot'] != null) {
        final hotspot = HotspotResponse(
          subject: subject,
          hometown: hometown,
          workplace: workplace,
          places: places ?? '',
          createdAt: DateTime.now(),
        );
        _hotspots.add(hotspot);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Submit hotspot error: $e');
      rethrow;
    }
  }

  /// Load hotspots for a patient
  Future<void> loadPatientHotspots(String patientId) async {
    try {
      final hotspotsList = await hotspotService.getPatientHotspots(
        patientId: patientId,
      );

      final hotspots = hotspotsList.map((h) {
        final hotspotData = h as Map<String, dynamic>;
        return HotspotResponse(
          subject: hotspotData['subject'] ?? '',
          hometown: hotspotData['hometown'] ?? '',
          workplace: hotspotData['workplace'] ?? '',
          places: hotspotData['places'] ?? '',
          createdAt: _parseTimestamp(hotspotData['createdAt']),
        );
      }).toList();

      _hotspots.clear();
      _hotspots.addAll(hotspots);
      notifyListeners();
    } catch (e) {
      debugPrint('Load patient hotspots error: $e');
      rethrow;
    }
  }

  /// Get hotspots for a subject
  List<HotspotResponse> get hotspotResponses =>
      List<HotspotResponse>.unmodifiable(_hotspots)..sort(
        (HotspotResponse a, HotspotResponse b) =>
            b.createdAt.compareTo(a.createdAt),
      );

  /// Get hotspots for a subject
  List<HotspotResponse> hotspotResponsesForSubject(String subject) {
    return _hotspots.where((HotspotResponse h) => h.subject == subject).toList()
      ..sort(
        (HotspotResponse a, HotspotResponse b) =>
            b.createdAt.compareTo(a.createdAt),
      );
  }

  // ============ Helpers ============

  String _filterToString(TimelineFilter filter) {
    switch (filter) {
      case TimelineFilter.last24h:
        return 'last24h';
      case TimelineFilter.last3Days:
        return 'last3Days';
      case TimelineFilter.last7Days:
        return 'last7Days';
    }
  }

  DateTime _parseTimestamp(dynamic raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    if (raw is Map && raw['_seconds'] != null) {
      final seconds = (raw['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }
}

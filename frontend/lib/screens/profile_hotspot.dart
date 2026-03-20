import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/input_sections.dart';
import 'auth.dart';
import 'root_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController emailController;
  UserRole? _loadedForRole;
  Timer? _refreshTimer;

  String _otpTimestampText() {
    final DateTime now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
  }

  void _showOtpSentSnackBar({String? devOtp}) {
    final AppState app = AppScope.of(context);
    final String suffix = (devOtp != null && devOtp.isNotEmpty)
        ? ' • DEV: $devOtp'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${app.t('otp_sent_at')} • ${_otpTimestampText()}$suffix',
        ),
      ),
    );
  }

  String _formatPhoneForDisplay(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('94')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 10 && digits.startsWith('7')) {
      return '0$digits';
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    final currentUser = app.currentUser;
    if (currentUser != null) {
      emailController.text = currentUser.email ?? '';

      if (_loadedForRole != currentUser.role) {
        _loadedForRole = currentUser.role;
        _refreshTimer?.cancel();
        unawaited(_loadRelationships(app, currentUser.role));
        _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
          if (!mounted) return;
          final current = app.currentUser;
          if (current == null) return;
          unawaited(_loadRelationships(app, current.role));
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRelationships(AppState app, UserRole role) async {
    try {
      if (role == UserRole.patient) {
        await app.loadPatientCaregivers();
      } else {
        await app.loadCaregiverPatients();
      }
    } catch (_) {}
  }

  Future<void> _switchRole(AppState app, UserRole role) async {
    if (app.currentUser == null || app.currentUser!.role == role) {
      return;
    }

    try {
      await app.switchActiveRole(role);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardRouter()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    }
  }

  Future<void> _enableCaregiver(AppState app) async {
    try {
      await app.enableCaregiverRole();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('caregiver_mode_enabled'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    }
  }

  Future<void> _addEmail(AppState app) async {
    final TextEditingController localEmailController = TextEditingController();

    final String? email = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(app.t('email')),
          content: TextField(
            controller: localEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: app.t('email')),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(app.t('cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(localEmailController.text),
              child: Text(app.t('save')),
            ),
          ],
        );
      },
    );
    localEmailController.dispose();

    if (email == null) return;
    final String normalized = email.trim();
    if (normalized.isEmpty || !normalized.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('invalid_email'))));
      return;
    }

    try {
      await app.updateProfile(
        name: app.currentUser?.name ?? '',
        phone: app.currentUser?.phone ?? '',
        email: normalized,
      );
      await app.reloadUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('profile_updated'))));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    }
  }

  Future<void> _startEmailVerification(AppState app) async {
    final String email = (app.currentUser?.email ?? '').trim();
    if (email.isEmpty) {
      return;
    }

    String? otpFromResponse;
    try {
      final response = await app.sendEmailVerificationOtp();
      // Extract OTP if available (dev mode only)
      otpFromResponse = response['otp'] as String?;
      if (!mounted) return;
      _showOtpSentSnackBar(devOtp: otpFromResponse);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
      return;
    }

    if (!mounted) return;

    final bool verified =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OtpVerificationScreen(
              title: app.t('otp_verification'),
              subtitle: app.t('enter_otp_sent_email'),
              credential: email,
              devModeOtp: otpFromResponse,
              onVerifyOtp: (otp) => app.confirmEmailVerification(otp: otp),
              onResendOtp: () => app.sendEmailVerificationOtp(),
            ),
          ),
        ) ??
        false;

    if (!mounted) return;

    if (verified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('email_verified_success'))));
    }
  }

  Widget _profileInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF0A1430),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final user = app.currentUser;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final List<Map<String, dynamic>> linkedCaregivers = app.patientCaregivers(
      user.id,
    );
    final bool hasPatientRole = app.hasRole(UserRole.patient);
    final bool hasCaregiverRole = app.hasRole(UserRole.caregiver);
    final bool canSwitchRoles = hasPatientRole && hasCaregiverRole;

    return ResponsiveListView(
      children: <Widget>[
        SectionHeader(
          title: app.t('profile'),
          subtitle: user.role == UserRole.patient
              ? app.t('patient')
              : app.t('caregiver'),
          icon: Icons.person_outline,
        ),
        UiSpace.xs,
        _profileInfoTile(
          context,
          icon: Icons.person_outline,
          label: app.t('name'),
          value: user.name,
        ),
        _profileInfoTile(
          context,
          icon: Icons.phone_outlined,
          label: app.t('phone'),
          value: _formatPhoneForDisplay(user.phone),
        ),
        if ((user.email ?? '').trim().isNotEmpty) ...<Widget>[
          _profileInfoTile(
            context,
            icon: Icons.email_outlined,
            label: app.t('email'),
            value: user.email!,
          ),
          if (!user.emailVerified)
            FilledButton.tonalIcon(
              onPressed: () => _startEmailVerification(app),
              icon: const Icon(Icons.mark_email_read_outlined),
              label: Text(app.t('verify_email')),
            ),
        ] else
          FilledButton.tonal(
            onPressed: () => _addEmail(app),
            child: Text(app.t('add_email')),
          ),
        UiSpace.xs,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  app.t('language'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<AppLanguage>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<AppLanguage>>[
                    ButtonSegment<AppLanguage>(
                      value: AppLanguage.english,
                      label: Text(app.t('language_english_title')),
                    ),
                    ButtonSegment<AppLanguage>(
                      value: AppLanguage.sinhala,
                      label: Text(app.t('language_sinhala_title')),
                    ),
                  ],
                  selected: <AppLanguage>{
                    app.selectedLanguage ?? AppLanguage.english,
                  },
                  onSelectionChanged: (selection) {
                    final nextLanguage = selection.first;
                    if (nextLanguage == app.selectedLanguage) return;
                    app.setLanguage(nextLanguage);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(app.t('language_changed'))),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        UiSpace.xs,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  app.t('caregiver_options'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (canSwitchRoles)
                  SegmentedButton<UserRole>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      textStyle: WidgetStatePropertyAll(
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    segments: <ButtonSegment<UserRole>>[
                      ButtonSegment<UserRole>(
                        value: UserRole.patient,
                        label: Text(
                          app.t('patient'),
                          textAlign: TextAlign.center,
                        ),
                        icon: const Icon(Icons.favorite_outline),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.caregiver,
                        label: Text(
                          app.t('caregiver'),
                          textAlign: TextAlign.center,
                        ),
                        icon: const Icon(Icons.people_outline),
                      ),
                    ],
                    selected: <UserRole>{user.role},
                    onSelectionChanged: (selection) {
                      final nextRole = selection.first;
                      unawaited(_switchRole(app, nextRole));
                    },
                    showSelectedIcon: false,
                  )
                else if (!hasCaregiverRole)
                  FilledButton.tonalIcon(
                    onPressed: () => _enableCaregiver(app),
                    icon: const Icon(Icons.add_moderator_outlined),
                    label: Text(app.t('enable_caregiver_mode')),
                  ),
              ],
            ),
          ),
        ),
        if (user.role == UserRole.patient) ...<Widget>[
          UiSpace.sm,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD5DEEF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  app.t('patient_caregiver_settings'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF0A1430),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E73D8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            app.t('connect_with_caregiver'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF0A1430),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.t('share_realtime_health_data'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF5F7391)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      String code;
                      try {
                        code = await app.generateCaregiverCode();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${app.t('error')}: $e')),
                        );
                        return;
                      }

                      if (!context.mounted) return;
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(app.t('caregiver_code')),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  app.t('share_this_code_with_caregiver'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(app.t('code_copied')),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: Text(app.t('copy')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(app.t('close')),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(app.t('generate_6_digit_code')),
                  ),
                ),
              ],
            ),
          ),
          if (linkedCaregivers.isNotEmpty) ...<Widget>[
            UiSpace.xs,
            Text(
              app.t('caregivers_list'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: linkedCaregivers
                      .map(
                        (Map<String, dynamic> c) =>
                            (c['name'] ?? '').toString().trim(),
                      )
                      .where((String n) => n.isNotEmpty)
                      .map(
                        (String n) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F1FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            n,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF1E73D8),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
        UiSpace.sm,
        OutlinedButton(
          onPressed: () {
            app.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
          child: Text(app.t('logout')),
        ),
      ],
    );
  }
}

class HotspotMapScreen extends StatefulWidget {
  const HotspotMapScreen({super.key, required this.forCaregiverPatientData});

  final bool forCaregiverPatientData;

  @override
  State<HotspotMapScreen> createState() => _HotspotMapScreenState();
}

class _HotspotMapScreenState extends State<HotspotMapScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();
  bool _saving = false;
  bool _loadingMap = false;
  bool _showLegend = true;
  bool _showDetails = true;
  bool _showTopHotspots = true;
  DiseaseType _selectedMapDisease = DiseaseType.dengue;
  String? _selectedPatientId;
  String? _selectedDistrict;

  final TextEditingController _hometownController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  static final Map<String, LatLng> _districtCenters = <String, LatLng>{
    'ampara': const LatLng(7.2965, 81.6820),
    'anuradhapura': const LatLng(8.3114, 80.4037),
    'badulla': const LatLng(6.9934, 81.0550),
    'batticaloa': const LatLng(7.7170, 81.7000),
    'colombo': const LatLng(6.9271, 79.8612),
    'galle': const LatLng(6.0535, 80.2210),
    'gampaha': const LatLng(7.0917, 79.9992),
    'hambantota': const LatLng(6.1241, 81.1185),
    'jaffna': const LatLng(9.6615, 80.0255),
    'kalutara': const LatLng(6.5854, 79.9607),
    'kandy': const LatLng(7.2906, 80.6337),
    'kegalle': const LatLng(7.2513, 80.3464),
    'kilinochchi': const LatLng(9.3964, 80.3982),
    'kurunegala': const LatLng(7.4863, 80.3647),
    'mannar': const LatLng(8.9770, 79.9042),
    'matale': const LatLng(7.4675, 80.6234),
    'matara': const LatLng(5.9549, 80.5550),
    'monaragala': const LatLng(6.8728, 81.3507),
    'mullaitivu': const LatLng(9.2671, 80.8128),
    'nuwara eliya': const LatLng(6.9497, 80.7891),
    'polonnaruwa': const LatLng(7.9396, 81.0000),
    'puttalam': const LatLng(8.0362, 79.8283),
    'ratnapura': const LatLng(6.6828, 80.3992),
    'trincomalee': const LatLng(8.5874, 81.2152),
    'vavuniya': const LatLng(8.7514, 80.4971),
  };

  @override
  void initState() {
    super.initState();
    unawaited(_loadMapData());
  }

  Future<void> _loadMapData() async {
    setState(() => _loadingMap = true);
    final AppState app = AppScope.of(context);

    try {
      if (widget.forCaregiverPatientData) {
        await app.loadCaregiverPatients();
        if (!mounted) return;
        final patients = app.caregiverPatients(app.currentUser!.id);
        if (patients.isNotEmpty) {
          _selectedPatientId ??= patients.first.id;
          await app.loadPatientHotspots(_selectedPatientId!);
        } else if (app.hasRole(UserRole.patient)) {
          await app.loadPatientHotspots(app.currentUser!.id);
        }
      } else {
        await app.loadPatientHotspots(app.currentUser!.id);
      }

      await app.loadRegionalHeatmapData(disease: _selectedDiseaseApiValue());
    } catch (_) {
      // Keep UI usable even if map data loading fails.
    } finally {
      if (mounted) {
        setState(() => _loadingMap = false);
      }
    }
  }

  @override
  void dispose() {
    _hometownController.dispose();
    _workplaceController.dispose();
    _placesController.dispose();
    super.dispose();
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB42318);
      case 'high':
        return const Color(0xFFDD6B20);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF1D9A6C);
    }
  }

  String _prettyDistrict(String district) {
    return district
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  Future<void> _onCaregiverPatientChanged(
    AppState app,
    String? patientId,
  ) async {
    if (patientId == null || patientId == _selectedPatientId) {
      return;
    }
    setState(() => _selectedPatientId = patientId);
    try {
      await app.loadPatientHotspots(patientId);
    } catch (_) {}
  }

  Future<void> _switchMapDisease(AppState app, DiseaseType disease) async {
    if (_selectedMapDisease == disease) {
      return;
    }
    setState(() {
      _selectedMapDisease = disease;
      _selectedDistrict = null;
      _loadingMap = true;
    });

    try {
      await app.loadRegionalHeatmapData(disease: _selectedDiseaseApiValue());
    } catch (_) {
      // Keep UI usable even if disease-specific fetch fails.
    } finally {
      if (mounted) {
        setState(() => _loadingMap = false);
      }
    }
  }

  String _selectedDiseaseApiValue() {
    return _selectedMapDisease == DiseaseType.ratFever ? 'ratFever' : 'dengue';
  }

  String _diseaseLabel(DiseaseType disease) {
    final AppState app = AppScope.of(context);
    return disease == DiseaseType.ratFever
        ? app.t('rat_fever')
        : app.t('dengue');
  }

  String _diseaseTextFromApi(String disease) {
    final AppState app = AppScope.of(context);
    final normalized = disease.toLowerCase();
    if (normalized == 'ratfever' || normalized == 'rat_fever') {
      return app.t('rat_fever');
    }
    if (normalized == 'dengue') {
      return app.t('dengue');
    }
    return app.t('unknown');
  }

  bool _matchesSelectedMapDisease(String disease) {
    final normalized = disease.toLowerCase();
    if (_selectedMapDisease == DiseaseType.ratFever) {
      return normalized == 'ratfever' ||
          normalized == 'rat_fever' ||
          normalized == 'rat fever';
    }
    return normalized == 'dengue';
  }

  PatientSummary? _findSelectedPatient(List<PatientSummary> patients) {
    for (final patient in patients) {
      if (patient.id == _selectedPatientId) {
        return patient;
      }
    }
    return null;
  }

  HotspotRegionSummary? _findRegionByDistrict(
    List<HotspotRegionSummary> regions,
    String? district,
  ) {
    if (district == null) {
      return null;
    }
    for (final region in regions) {
      if (region.district == district) {
        return region;
      }
    }
    return null;
  }

  void _zoomMapBy(double delta) {
    try {
      final camera = _mapController.camera;
      final nextZoom = (camera.zoom + delta).clamp(5.5, 14.0).toDouble();
      _mapController.move(camera.center, nextZoom);
    } catch (_) {
      // Ignore zoom interactions until map camera is ready.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final currentUser = app.currentUser;

    if (currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    final String defaultSubject = currentUser.name;
    final List<PatientSummary> caregiverPatients =
        widget.forCaregiverPatientData
        ? app.caregiverPatients(currentUser.id)
        : <PatientSummary>[];
    final bool showCaregiverPatientPicker =
        widget.forCaregiverPatientData && caregiverPatients.isNotEmpty;

    final PatientSummary? selectedPatient = showCaregiverPatientPicker
        ? _findSelectedPatient(caregiverPatients)
        : null;

    final DiseaseType submissionDisease = showCaregiverPatientPicker
        ? (selectedPatient?.disease ?? DiseaseType.dengue)
        : _selectedMapDisease;

    final String? selectedPatientId = showCaregiverPatientPicker
        ? (selectedPatient?.id ?? _selectedPatientId)
        : currentUser.id;

    final List<HotspotResponse> rawHistory = showCaregiverPatientPicker
        ? app.hotspotResponses
              .where((h) => h.patientId == selectedPatientId)
              .toList()
        : widget.forCaregiverPatientData
        ? app.hotspotResponses
              .where((h) => h.patientId == currentUser.id)
              .toList()
        : app.hotspotResponsesForSubject(defaultSubject);

    final List<HotspotResponse> history = rawHistory
        .where((h) => _matchesSelectedMapDisease(h.disease))
        .toList();

    final List<HotspotRegionSummary> regionalSummary =
        app.regionalHotspotSummary;

    final List<HotspotRegionSummary> topHotspots = regionalSummary
        .where((r) => r.totalEvents > 0)
        .take(5)
        .toList();

    final HotspotRegionSummary? selectedRegion = _findRegionByDistrict(
      regionalSummary,
      _selectedDistrict,
    );

    final double mapHeight = _showDetails ? 360 : 520;

    return ResponsiveListView(
      children: <Widget>[
        InputSection(
          title: app.t('hotspot_map'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                app.t('map_view'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<DiseaseType>(
                segments: <ButtonSegment<DiseaseType>>[
                  ButtonSegment<DiseaseType>(
                    value: DiseaseType.dengue,
                    label: Text(app.t('dengue')),
                  ),
                  ButtonSegment<DiseaseType>(
                    value: DiseaseType.ratFever,
                    label: Text(app.t('rat_fever')),
                  ),
                ],
                selected: <DiseaseType>{_selectedMapDisease},
                onSelectionChanged: (selection) {
                  final next = selection.first;
                  unawaited(_switchMapDisease(app, next));
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 8),
              Text(
                app
                    .t('showing_hotspots')
                    .replaceAll(
                      '{disease}',
                      _diseaseLabel(_selectedMapDisease),
                    ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilterChip(
                    label: Text(app.t('legend')),
                    selected: _showLegend,
                    onSelected: (v) => setState(() => _showLegend = v),
                  ),
                  FilterChip(
                    label: Text(app.t('details')),
                    selected: _showDetails,
                    onSelected: (v) {
                      setState(() {
                        _showDetails = v;
                        if (!v) {
                          _showTopHotspots = false;
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: Text(app.t('top_areas')),
                    selected: _showTopHotspots,
                    onSelected: (v) => setState(() => _showTopHotspots = v),
                  ),
                ],
              ),
              if (!_showDetails)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    app.t('large_map_mode_enabled'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: mapHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _loadingMap
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: <Widget>[
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _sriLankaCenter,
                                initialZoom: 7,
                                minZoom: 5.5,
                                maxZoom: 14,
                              ),
                              children: <Widget>[
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.vitaltrack.app',
                                ),
                                MarkerLayer(
                                  markers: regionalSummary
                                      .where(
                                        (r) =>
                                            r.totalEvents > 0 &&
                                            _districtCenters.containsKey(
                                              r.district,
                                            ),
                                      )
                                      .map((region) {
                                        final color = _riskColor(
                                          region.riskLevel,
                                        );
                                        final size = (14 + (region.score * 1.2))
                                            .clamp(14, 34)
                                            .toDouble();
                                        return Marker(
                                          point:
                                              _districtCenters[region
                                                  .district]!,
                                          width: size,
                                          height: size,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => _selectedDistrict =
                                                    region.district,
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color.withValues(
                                                  alpha: 0.82,
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Column(
                                children: <Widget>[
                                  FloatingActionButton.small(
                                    heroTag: 'hotspot_zoom_in',
                                    onPressed: () => _zoomMapBy(0.7),
                                    child: const Icon(Icons.add),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    heroTag: 'hotspot_zoom_out',
                                    onPressed: () => _zoomMapBy(-0.7),
                                    child: const Icon(Icons.remove),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_showLegend) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    _legendItem(app.t('risk_low'), _riskColor('low')),
                    _legendItem(app.t('risk_medium'), _riskColor('medium')),
                    _legendItem(app.t('risk_high'), _riskColor('high')),
                    _legendItem(app.t('risk_critical'), _riskColor('critical')),
                  ],
                ),
              ],
              if (_showDetails && selectedRegion != null) ...<Widget>[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _prettyDistrict(selectedRegion.district),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app
                              .t('risk_score_line')
                              .replaceAll(
                                '{risk}',
                                selectedRegion.riskLevel.toUpperCase(),
                              )
                              .replaceAll(
                                '{score}',
                                selectedRegion.score.toStringAsFixed(1),
                              ),
                        ),
                        Text(
                          app
                              .t('patients_events_line')
                              .replaceAll(
                                '{patients}',
                                selectedRegion.patients.toString(),
                              )
                              .replaceAll(
                                '{events}',
                                selectedRegion.totalEvents.toString(),
                              ),
                        ),
                        Text(
                          app
                              .t('home_work_visits_line')
                              .replaceAll(
                                '{home}',
                                selectedRegion.hometownCount.toString(),
                              )
                              .replaceAll(
                                '{work}',
                                selectedRegion.workplaceCount.toString(),
                              )
                              .replaceAll(
                                '{visits}',
                                selectedRegion.visitCount.toString(),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_showTopHotspots && topHotspots.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  app.t('top_hotspot_districts'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...topHotspots.map(
                  (r) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: _riskColor(r.riskLevel),
                    ),
                    title: Text(_prettyDistrict(r.district)),
                    subtitle: Text(
                      app
                          .t('score_events_line')
                          .replaceAll('{score}', r.score.toStringAsFixed(1))
                          .replaceAll('{events}', r.totalEvents.toString()),
                    ),
                    onTap: () => setState(() => _selectedDistrict = r.district),
                  ),
                ),
              ],
            ],
          ),
        ),
        InputSection(
          title: showCaregiverPatientPicker
              ? app.t('add_patient_hotspot_data')
              : app.t('add_hotspot_data'),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                if (showCaregiverPatientPicker) ...<Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: selectedPatientId,
                    decoration: InputDecoration(
                      labelText: app.t('patient_name'),
                    ),
                    items: caregiverPatients
                        .map(
                          (patient) => DropdownMenuItem<String>(
                            value: patient.id,
                            child: Text(patient.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      unawaited(_onCaregiverPatientChanged(app, value));
                    },
                    validator: (value) => (value == null || value.isEmpty)
                        ? app.t('required_field')
                        : null,
                  ),
                  UiSpace.xs,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      app
                          .t('submission_disease')
                          .replaceAll(
                            '{disease}',
                            _diseaseLabel(submissionDisease),
                          ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  UiSpace.xs,
                ],
                TextFormField(
                  controller: _hometownController,
                  decoration: InputDecoration(
                    labelText:
                        '${app.t('hometown')} (${app.t('town_district')})',
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                UiSpace.xs,
                TextFormField(
                  controller: _workplaceController,
                  decoration: InputDecoration(
                    labelText:
                        '${app.t('workplace')} (${app.t('town_district')})',
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                UiSpace.xs,
                TextFormField(
                  controller: _placesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: app.t('places_last_3_days'),
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                const SizedBox(height: 10),
                BusyFilledButton(
                  isBusy: _saving,
                  label: app.t('save'),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() != true) return;
                    setState(() => _saving = true);
                    final String subject = showCaregiverPatientPicker
                        ? (selectedPatient?.name ?? app.t('patient'))
                        : defaultSubject;
                    try {
                      await app.submitHotspot(
                        subject: subject,
                        subjectPatientId: showCaregiverPatientPicker
                            ? selectedPatientId
                            : null,
                        disease: submissionDisease == DiseaseType.ratFever
                            ? 'ratFever'
                            : 'dengue',
                        hometown: _hometownController.text.trim(),
                        workplace: _workplaceController.text.trim(),
                        places: _placesController.text.trim(),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${app.t('error')}: $e')),
                      );
                      return;
                    }
                    _hometownController.clear();
                    _workplaceController.clear();
                    _placesController.clear();
                    await app.loadRegionalHeatmapData(
                      disease: _selectedDiseaseApiValue(),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(app.t('saved'))));
                    setState(() => _saving = false);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          app.t('recent_submissions'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        if (history.isEmpty)
          EmptyStateCard(
            icon: Icons.location_off_outlined,
            title: app.t('no_data'),
            subtitle: app
                .t('no_submissions_yet')
                .replaceAll(
                  '{disease}',
                  _diseaseLabel(_selectedMapDisease).toLowerCase(),
                ),
          )
        else
          ...history.take(5).map((HotspotResponse h) {
            final String when = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(h.createdAt);
            final String normalizedDisease = h.disease.toLowerCase();
            final bool isRatFever =
                normalizedDisease == 'ratfever' ||
                normalizedDisease == 'rat_fever' ||
                normalizedDisease == 'rat fever';
            final bool isDengue = normalizedDisease == 'dengue';
            final String diseaseLabel = _diseaseTextFromApi(h.disease);
            return Card(
              child: ListTile(
                title: Row(
                  children: <Widget>[
                    Expanded(child: Text('${h.hometown} • ${h.workplace}')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isRatFever
                            ? const Color(0xFFFDECEC)
                            : isDengue
                            ? const Color(0xFFFFF5DF)
                            : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        diseaseLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                subtitle: Text('${h.places}\n$when'),
              ),
            );
          }),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

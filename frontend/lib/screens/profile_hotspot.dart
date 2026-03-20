import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    final String suffix = (devOtp != null && devOtp.isNotEmpty)
        ? ' • DEV: $devOtp'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('OTP sent • ${_otpTimestampText()}$suffix'),
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
      await app.switchActiveRole(UserRole.caregiver);
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
            decoration: const InputDecoration(hintText: 'name@example.com'),
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
              subtitle: 'Enter the OTP sent to your email',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully')),
      );
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
              label: const Text('Verify Email'),
            ),
        ] else
          FilledButton.tonal(
            onPressed: () => _addEmail(app),
            child: const Text('Add Email'),
          ),
        UiSpace.xs,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Caregiver Options',
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
                    label: const Text('Enable Caregiver Mode'),
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
                  'Patient Caregiver Settings',
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
                            'Connect with Caregiver',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF0A1430),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share real-time health data with caregivers',
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
  bool _saving = false;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _hometownController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _hometownController.dispose();
    _workplaceController.dispose();
    _placesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final currentUser = app.currentUser;

    if (currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    final String defaultSubject = currentUser.name;
    final List<HotspotResponse> history = widget.forCaregiverPatientData
        ? app.hotspotResponses
        : app.hotspotResponsesForSubject(defaultSubject);

    return ResponsiveListView(
      children: <Widget>[
        InputSection(
          title: widget.forCaregiverPatientData
              ? app.t('add_patient_hotspot_data')
              : app.t('add_hotspot_data'),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for hotspots',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFB),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.forCaregiverPatientData)
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: app.t('patient_name'),
                    ),
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty)
                        ? app.t('required_field')
                        : null,
                  ),
                if (widget.forCaregiverPatientData) UiSpace.xs,
                TextFormField(
                  controller: _hometownController,
                  decoration: InputDecoration(labelText: app.t('hometown')),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                UiSpace.xs,
                TextFormField(
                  controller: _workplaceController,
                  decoration: InputDecoration(labelText: app.t('workplace')),
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
                    final String subject = widget.forCaregiverPatientData
                        ? _subjectController.text.trim()
                        : defaultSubject;
                    try {
                      await app.submitHotspot(
                        subject: subject,
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
                    _subjectController.clear();
                    _hometownController.clear();
                    _workplaceController.clear();
                    _placesController.clear();
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
            subtitle: app.t('add_hotspot_data'),
          )
        else
          ...history.take(5).map((HotspotResponse h) {
            final String when = DateFormat(
              'yyyy-MM-dd hh:mm a',
            ).format(h.createdAt);
            return Card(
              child: ListTile(
                title: Text('${h.hometown} • ${h.workplace}'),
                subtitle: Text('${h.places}\n$when'),
              ),
            );
          }),
      ],
    );
  }
}

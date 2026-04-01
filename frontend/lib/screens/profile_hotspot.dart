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

bool _isValidEmailAddress(String value) {
  final String normalized = value.trim();
  return RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  ).hasMatch(normalized);
}

bool _isValidLkPhoneNumber(String value) {
  final String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
  return RegExp(r'^(07[0-9]{8}|7[0-9]{8}|94[0-9]{9})$').hasMatch(cleaned);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController emailController;
  UserRole? _loadedForRole;
  Timer? _refreshTimer;
  bool _loadingRelationships = false;
  final Set<String> _removingLinkedUserIds = <String>{};

  String _otpTimestampText() {
    final DateTime now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
  }

  void _showOtpSentSnackBar({
    String? devOtp,
    int? remainingAttempts,
    int? maxAttempts,
  }) {
    final AppState app = AppScope.of(context);
    final String attemptsSuffix =
        remainingAttempts != null && maxAttempts != null
        ? ' • ${app.t('otp_attempts_left')}: $remainingAttempts/$maxAttempts'
        : '';
    final String suffix = (devOtp != null && devOtp.isNotEmpty)
        ? '$attemptsSuffix • DEV: $devOtp'
        : attemptsSuffix;
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
        _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
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
    if (_loadingRelationships) {
      return;
    }

    _loadingRelationships = true;
    try {
      if (role == UserRole.patient) {
        await app.loadPatientCaregivers();
      } else {
        await app.loadCaregiverPatients();
      }
    } catch (_) {
      // Ignore background refresh errors.
    } finally {
      _loadingRelationships = false;
    }
  }

  Future<void> _switchRole(AppState app, UserRole role) async {
    if (app.currentUser == null) {
      return;
    }

    try {
      if (role == UserRole.caregiver && !app.hasRole(UserRole.caregiver)) {
        await app.enableCaregiverRole();
      }

      if (app.currentUser == null || app.currentUser!.role == role) {
        return;
      }

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

  Future<void> _confirmAndRemoveLinkedUser({
    required AppState app,
    required String linkedUserId,
    required String linkedUserName,
    required bool isRemovingCaregiver,
  }) async {
    if (_removingLinkedUserIds.contains(linkedUserId)) {
      return;
    }

    final String dialogTitle = isRemovingCaregiver
        ? app.t('remove_caregiver')
        : app.t('remove_patient');
    final String dialogMessageTemplate = isRemovingCaregiver
        ? app.t('confirm_remove_caregiver_message')
        : app.t('confirm_remove_patient_message');
    final String dialogMessage = dialogMessageTemplate.replaceAll(
      '{name}',
      linkedUserName,
    );

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: Text(dialogMessage),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(app.t('cancel')),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFB42318),
                  ),
                  child: Text(app.t('remove')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _removingLinkedUserIds.add(linkedUserId));
    try {
      await app.removeRelationshipWithUser(linkedUserId);
      if (!mounted) return;

      if (isRemovingCaregiver) {
        await _loadRelationships(app, UserRole.patient);
      } else {
        await _loadRelationships(app, UserRole.caregiver);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRemovingCaregiver
                ? app.t('caregiver_removed')
                : app.t('patient_removed'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    } finally {
      if (mounted) {
        setState(() => _removingLinkedUserIds.remove(linkedUserId));
      }
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
            decoration: const InputDecoration(),
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
    if (normalized.isEmpty || !_isValidEmailAddress(normalized)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('invalid_email'))));
      return;
    }

    try {
      await app.updateProfile(email: normalized);
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

  Future<void> _addPhone(AppState app) async {
    final TextEditingController localPhoneController = TextEditingController();

    final String? phone = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(app.t('phone')),
          content: TextField(
            controller: localPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(app.t('cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(localPhoneController.text),
              child: Text(app.t('save')),
            ),
          ],
        );
      },
    );

    localPhoneController.dispose();

    if (phone == null) return;
    final String normalized = phone.trim();
    if (normalized.isEmpty || !_isValidLkPhoneNumber(normalized)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('invalid_lk_phone'))));
      return;
    }

    try {
      await app.updateProfile(phone: normalized);
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
    int? remainingAttempts;
    int? maxAttempts;
    try {
      final response = await app.sendEmailVerificationOtp();
      // Extract OTP if available (dev mode only)
      otpFromResponse = response['otp'] as String?;
      remainingAttempts = (response['remainingAttempts'] as num?)?.toInt();
      maxAttempts = (response['maxAttempts'] as num?)?.toInt();
      if (!mounted) return;
      _showOtpSentSnackBar(
        devOtp: otpFromResponse,
        remainingAttempts: remainingAttempts,
        maxAttempts: maxAttempts,
      );
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

  Future<void> _startPhoneVerification(AppState app) async {
    final String phone = (app.currentUser?.phone ?? '').trim();
    if (phone.isEmpty) {
      return;
    }

    String? otpFromResponse;
    int? remainingAttempts;
    int? maxAttempts;
    try {
      final response = await app.sendPhoneVerificationOtp();
      otpFromResponse = response['otp'] as String?;
      remainingAttempts = (response['remainingAttempts'] as num?)?.toInt();
      maxAttempts = (response['maxAttempts'] as num?)?.toInt();
      if (!mounted) return;
      _showOtpSentSnackBar(
        devOtp: otpFromResponse,
        remainingAttempts: remainingAttempts,
        maxAttempts: maxAttempts,
      );
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
              subtitle: app.t('enter_otp_sent_phone'),
              credential: phone,
              devModeOtp: otpFromResponse,
              onVerifyOtp: (otp) => app.confirmPhoneVerification(otp: otp),
              onResendOtp: () => app.sendPhoneVerificationOtp(),
            ),
          ),
        ) ??
        false;

    if (!mounted) return;

    if (verified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('phone_verified_success'))));
    }
  }

  Widget _sectionCaption(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 14, top: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.5,
          color: const Color(0xFF98A2B3),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8EF), width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _verifiedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD1F4E9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA8E5D5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF17B26A),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            AppScope.of(context).t('verified').toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF17B26A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileField({
    required BuildContext context,
    required String label,
    required Widget value,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF98A2B3),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        value,
        if (showDivider) ...<Widget>[
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFE3E8EF)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _dashedActionButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: const Color(0xFF0A56B0),
        side: const BorderSide(color: Color(0xFFBFD0EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final List<PatientSummary> linkedPatients = app.caregiverPatients(user.id);
    final bool hasPhone = user.phone.trim().isNotEmpty;
    final bool hasEmail = (user.email ?? '').trim().isNotEmpty;
    const String personalInfoTitle = 'PERSONAL INFORMATION';
    const String appSettingsTitle = 'APP SETTINGS';
    const String fullNameTitle = 'FULL NAME';
    const String phoneNumberTitle = 'PHONE NUMBER';
    const String emailAddressTitle = 'EMAIL ADDRESS';
    const String addEmailAddressTitle = 'ADD EMAIL ADDRESS';
    const String preferredLanguageTitle = 'PREFERRED LANGUAGE';
    const String accountRoleTitle = 'ACCOUNT ROLE';

    return ResponsiveListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: <Widget>[
        _sectionCaption(context, personalInfoTitle),
        _surfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _profileField(
                context: context,
                label: fullNameTitle,
                value: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _profileField(
                context: context,
                label: phoneNumberTitle,
                showDivider: hasEmail,
                value: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (hasPhone)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _formatPhoneForDisplay(user.phone),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF111827),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (user.phoneVerified) _verifiedBadge(context),
                        ],
                      )
                    else
                      _dashedActionButton(
                        context: context,
                        onPressed: () => _addPhone(app),
                        icon: Icons.add,
                        label: app.t('add_phone').toUpperCase(),
                      ),
                    if (hasPhone && !user.phoneVerified) ...<Widget>[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _startPhoneVerification(app),
                          icon: const Icon(Icons.verified_outlined),
                          label: Text(app.t('verify_phone')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _profileField(
                context: context,
                label: emailAddressTitle,
                showDivider: false,
                value: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (hasEmail)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              user.email!,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF111827),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (user.emailVerified) _verifiedBadge(context),
                        ],
                      )
                    else
                      _dashedActionButton(
                        context: context,
                        onPressed: () => _addEmail(app),
                        icon: Icons.add,
                        label: addEmailAddressTitle,
                      ),
                    if (hasEmail && !user.emailVerified) ...<Widget>[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _startEmailVerification(app),
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: Text(app.t('verify_email')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _sectionCaption(context, appSettingsTitle),
        _surfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.public, color: Color(0xFF0F66D9)),
                  const SizedBox(width: 10),
                  Text(
                    preferredLanguageTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF141B2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<AppLanguage>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFE8F1FF);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF0A56B0);
                      }
                      return const Color(0xFF8A98B4);
                    }),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: Colors.transparent),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  segments: const <ButtonSegment<AppLanguage>>[
                    ButtonSegment<AppLanguage>(
                      value: AppLanguage.english,
                      label: Text('English'),
                    ),
                    ButtonSegment<AppLanguage>(
                      value: AppLanguage.sinhala,
                      label: Text('Sinhala'),
                    ),
                  ],
                  selected: <AppLanguage>{
                    app.selectedLanguage ?? AppLanguage.english,
                  },
                  onSelectionChanged: (Set<AppLanguage> selection) {
                    final AppLanguage nextLanguage = selection.first;
                    if (nextLanguage == app.selectedLanguage) return;
                    app.setLanguage(nextLanguage);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(app.t('language_changed'))),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  const Icon(Icons.badge, color: Color(0xFF0F66D9)),
                  const SizedBox(width: 10),
                  Text(
                    accountRoleTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF141B2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<UserRole>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFE8F1FF);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF0A56B0);
                      }
                      return const Color(0xFF8A98B4);
                    }),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: Colors.transparent),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  segments: <ButtonSegment<UserRole>>[
                    ButtonSegment<UserRole>(
                      value: UserRole.patient,
                      label: Text(app.t('patient')),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.caregiver,
                      label: Text(app.t('caregiver')),
                    ),
                  ],
                  selected: <UserRole>{user.role},
                  onSelectionChanged: (Set<UserRole> selection) {
                    final UserRole nextRole = selection.first;
                    unawaited(_switchRole(app, nextRole));
                  },
                ),
              ),
            ],
          ),
        ),
        if (user.role == UserRole.patient) ...<Widget>[
          const SizedBox(height: 18),
          _surfaceCard(
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD4E2FA)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.people_alt_outlined,
                        color: Color(0xFF0A56B0),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.t('connect_with_caregiver'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF0A56B0),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    app.t('share_realtime_health_data'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3C4C68),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0A56B0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: code),
                                    );
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
                      child: Text(
                        app.t('generate_6_digit_code'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (linkedCaregivers.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    ...linkedCaregivers.map((Map<String, dynamic> caregiver) {
                      final String caregiverId = (caregiver['id'] ?? '')
                          .toString();
                      final String caregiverName = (caregiver['name'] ?? '')
                          .toString()
                          .trim();
                      final bool isLast = identical(
                        caregiver,
                        linkedCaregivers.last,
                      );
                      final bool isRemoving = _removingLinkedUserIds.contains(
                        caregiverId,
                      );

                      return Container(
                        margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD8E3F7)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: Color(0xFF0A56B0),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                caregiverName,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: const Color(0xFF141B2C),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isRemoving || caregiverId.isEmpty
                                  ? null
                                  : () => _confirmAndRemoveLinkedUser(
                                      app: app,
                                      linkedUserId: caregiverId,
                                      linkedUserName: caregiverName,
                                      isRemovingCaregiver: true,
                                    ),
                              icon: isRemoving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_remove_outlined,
                                      size: 18,
                                    ),
                              label: Text(app.t('remove')),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFFB42318),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ] else if (linkedPatients.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          _surfaceCard(
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD4E2FA)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.groups_2_outlined,
                        color: Color(0xFF0A56B0),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.t('patients'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF0A56B0),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Linked accounts you are currently caring for.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3C4C68),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...linkedPatients.map((PatientSummary p) {
                    final bool isLast = identical(p, linkedPatients.last);
                    final bool isRemoving = _removingLinkedUserIds.contains(
                      p.id,
                    );
                    return Container(
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD8E3F7)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: Color(0xFF0A56B0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: const Color(0xFF141B2C),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isRemoving
                                ? null
                                : () => _confirmAndRemoveLinkedUser(
                                    app: app,
                                    linkedUserId: p.id,
                                    linkedUserName: p.name,
                                    isRemovingCaregiver: false,
                                  ),
                            icon: isRemoving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_remove_outlined,
                                    size: 18,
                                  ),
                            label: Text(app.t('remove')),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB42318),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFBE1E2D),
            side: const BorderSide(color: Color(0xFFF0B7BC)),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            app.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.logout, size: 22),
              const SizedBox(width: 10),
              Text(
                app.t('logout'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
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
  bool _backgroundRefreshingMap = false;
  bool _mapRequestInProgress = false;
  bool _hasLoadedMapOnce = false;
  bool _showLegend = true;
  bool _showDetails = true;
  bool _showTopHotspots = true;
  bool _didInitialLoad = false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) {
      return;
    }
    _didInitialLoad = true;
    unawaited(_loadMapData());
  }

  Future<void> _runMapRequest(Future<void> Function() request) async {
    if (_mapRequestInProgress) {
      return;
    }

    _mapRequestInProgress = true;
    final bool useBackgroundRefresh = _hasLoadedMapOnce;

    if (mounted) {
      setState(() {
        if (useBackgroundRefresh) {
          _backgroundRefreshingMap = true;
        } else {
          _loadingMap = true;
        }
      });
    }

    try {
      await request();
      _hasLoadedMapOnce = true;
    } finally {
      _mapRequestInProgress = false;
      if (mounted) {
        setState(() {
          _loadingMap = false;
          _backgroundRefreshingMap = false;
        });
      }
    }
  }

  Future<void> _refreshMapDataForCurrentSelection(
    AppState app, {
    bool reloadCaregiverPatients = false,
  }) async {
    String? targetPatientId;

    if (widget.forCaregiverPatientData) {
      if (reloadCaregiverPatients) {
        await app.loadCaregiverPatients();
      }

      final patients = app.caregiverPatients(app.currentUser!.id);
      if (patients.isNotEmpty) {
        if (_selectedPatientId == null) {
          _selectedPatientId = patients.first.id;
          _selectedMapDisease = patients.first.disease;
        }
        targetPatientId = _selectedPatientId!;
      } else if (app.currentUser?.role == UserRole.patient) {
        targetPatientId = app.currentUser!.id;
      }
    } else {
      targetPatientId = app.currentUser!.id;
    }

    final List<Future<void>> mapLoads = <Future<void>>[
      app.loadRegionalHeatmapData(disease: _selectedDiseaseApiValue()),
    ];

    if (targetPatientId != null) {
      mapLoads.add(app.loadPatientHotspots(targetPatientId));
    }

    await Future.wait(mapLoads);
  }

  Future<void> _loadMapData() async {
    final AppState app = AppScope.of(context);
    try {
      await _runMapRequest(() async {
        await _refreshMapDataForCurrentSelection(
          app,
          reloadCaregiverPatients: true,
        );
      });
    } catch (_) {
      // Keep UI usable even if map data loading fails.
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

    if (_mapRequestInProgress) {
      return;
    }

    final List<PatientSummary> patients = app.caregiverPatients(
      app.currentUser!.id,
    );
    DiseaseType nextDisease = _selectedMapDisease;
    for (final patient in patients) {
      if (patient.id == patientId) {
        nextDisease = patient.disease;
        break;
      }
    }

    setState(() {
      _selectedPatientId = patientId;
      _selectedMapDisease = nextDisease;
      _selectedDistrict = null;
    });

    try {
      await _runMapRequest(() async {
        await _refreshMapDataForCurrentSelection(app);
      });
    } catch (_) {}
  }

  Future<void> _switchMapDisease(AppState app, DiseaseType disease) async {
    if (_selectedMapDisease == disease) {
      return;
    }

    if (_mapRequestInProgress) {
      return;
    }

    setState(() {
      _selectedMapDisease = disease;
      _selectedDistrict = null;
    });

    try {
      await _runMapRequest(() async {
        await _refreshMapDataForCurrentSelection(app);
      });
    } catch (_) {
      // Keep UI usable even if disease-specific fetch fails.
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
              if (_backgroundRefreshingMap) ...<Widget>[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 10),
              ],
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
                    unawaited(_loadMapData());
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

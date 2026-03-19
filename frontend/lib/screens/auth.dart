import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/form_screen_scaffold.dart';
import '../services/index.dart';
import 'root_router.dart';

String _friendlyAuthError(
  Object error, {
  required AppState app,
  required String fallback,
}) {
  if (error is DioException) {
    final Object? responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final Object? errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic>) {
        final String code = (errorObj['code'] ?? '').toString();
        final String message = (errorObj['message'] ?? '').toString();

        if (code == 'EMAIL_ALREADY_EXISTS' ||
            message.toLowerCase().contains('email already')) {
          return app.t('email_exists_error');
        }

        if (code == 'PHONE_ALREADY_EXISTS' ||
            message.toLowerCase().contains('phone') &&
                message.toLowerCase().contains('already')) {
          return app.t('phone_exists_error');
        }

        if (message.isNotEmpty) {
          return message;
        }
      }
    }
  }

  final String raw = error.toString().toLowerCase();
  if (raw.contains('email already')) {
    return app.t('email_exists_error');
  }
  if (raw.contains('phone') && raw.contains('already')) {
    return app.t('phone_exists_error');
  }
  if (raw.contains('invalid otp')) {
    return app.t('invalid_otp_error');
  }
  if (raw.contains('otp has expired') || raw.contains('otp not found')) {
    return app.t('otp_expired_error');
  }
  return fallback;
}

String _normalizeLkPhoneForApi(String localInput) {
  return localInput.replaceAll(RegExp(r'\D'), '');
}

bool _isValidLkPhone(String phone) {
  final String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return RegExp(r'^07[0-9]{8}$').hasMatch(cleaned);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  UserRole _role = UserRole.patient;
  LoginMethod _method = LoginMethod.number4n;
  bool _submitting = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final Size size = MediaQuery.of(context).size;
    final bool isSmall = size.width < 380;
    final bool isTablet = size.width >= 768;
    final double contentMaxWidth = isTablet ? 620 : 560;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: isSmall ? 18 : 28,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/vitaltrack_logo_symbol.png',
                      height: isTablet ? 128 : (isSmall ? 92 : 108),
                      fit: BoxFit.contain,
                      semanticLabel: 'VitalTrack Logo',
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.monitor_heart,
                        size: 96,
                        color: Color(0xFF1E5AA8),
                      ),
                    ),
                    SizedBox(height: isSmall ? 18 : 22),
                    Text(
                      app.t('monitor_precision'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF475467),
                        fontSize: isTablet ? 24 : (isSmall ? 16 : 18),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isSmall ? 18 : 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x190F172A),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(isSmall ? 16 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _role = UserRole.patient,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      margin: const EdgeInsets.all(6),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _role == UserRole.patient
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        app.t('patient'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _role == UserRole.patient
                                              ? const Color(0xFF1570EF)
                                              : const Color(0xFF475467),
                                          fontSize: isSmall ? 16 : 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _role = UserRole.caregiver,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      margin: const EdgeInsets.all(6),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _role == UserRole.caregiver
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        app.t('caregiver'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _role == UserRole.caregiver
                                              ? const Color(0xFF1570EF)
                                              : const Color(0xFF475467),
                                          fontSize: isSmall ? 16 : 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmall ? 18 : 24),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _method = LoginMethod.number4n,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      margin: const EdgeInsets.all(6),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _method == LoginMethod.number4n
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        app.t('via_mobile_number'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _method == LoginMethod.number4n
                                              ? const Color(0xFF1570EF)
                                              : const Color(0xFF475467),
                                          fontSize: isSmall ? 14 : 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _method = LoginMethod.email,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      margin: const EdgeInsets.all(6),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _method == LoginMethod.email
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        app.t('via_email'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _method == LoginMethod.email
                                              ? const Color(0xFF1570EF)
                                              : const Color(0xFF475467),
                                          fontSize: isSmall ? 14 : 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmall ? 16 : 20),
                          if (_method == LoginMethod.number4n) ...<Widget>[
                            Text(
                              app.t('phone_number_lk'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: '07XXXXXXXX',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (String? value) {
                                if (_method != LoginMethod.number4n) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return app.t('required_field');
                                }
                                final String normalizedPhone =
                                    _normalizeLkPhoneForApi(value.trim());
                                if (!_isValidLkPhone(normalizedPhone)) {
                                  return app.t('invalid_lk_phone');
                                }
                                return null;
                              },
                            ),
                          ] else ...<Widget>[
                            Text(
                              app.t('email'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'example@email.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (String? value) {
                                if (_method != LoginMethod.email) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return app.t('required_field');
                                }
                                if (!value.contains('@')) {
                                  return app.t('invalid_email');
                                }
                                return null;
                              },
                            ),
                          ],
                          SizedBox(height: isSmall ? 16 : 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                app.t('password'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF101828),
                                    ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1570EF),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(app.t('forgot_password')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (String? value) {
                              if (value == null || value.length < 6) {
                                return app.t('password_min');
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmall ? 20 : 26),
                          SizedBox(
                            height: isSmall ? 52 : 58,
                            child: FilledButton(
                              onPressed: _submitting
                                  ? null
                                  : () async {
                                      if (_formKey.currentState?.validate() !=
                                          true) {
                                        return;
                                      }

                                      setState(() => _submitting = true);
                                      final NavigatorState navigator =
                                          Navigator.of(context);
                                      final String credential =
                                          _method == LoginMethod.email
                                          ? _emailController.text.trim()
                                          : _normalizeLkPhoneForApi(
                                              _phoneController.text.trim(),
                                            );
                                      final String otpType =
                                          _method == LoginMethod.email
                                          ? 'email'
                                          : 'phone';

                                      try {
                                        await authService.sendOtp(
                                          credential: credential,
                                          type: otpType,
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        final String friendly =
                                            _friendlyAuthError(
                                              e,
                                              app: app,
                                              fallback: app.t(
                                                'send_otp_failed',
                                              ),
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(friendly)),
                                        );
                                        setState(() => _submitting = false);
                                        return;
                                      }

                                      final bool otpOk =
                                          await navigator.push<bool>(
                                            MaterialPageRoute<bool>(
                                              builder: (_) =>
                                                  OtpVerificationScreen(
                                                    title: app.t(
                                                      'otp_verification',
                                                    ),
                                                    subtitle: app.t(
                                                      'enter_otp_login',
                                                    ),
                                                    credential: credential,
                                                    navigateToDashboardOnSuccess:
                                                        true,
                                                    onVerifiedSuccess: () async {
                                                      await app.login(
                                                        credential: credential,
                                                        password:
                                                            _passwordController
                                                                .text
                                                                .trim(),
                                                      );
                                                    },
                                                  ),
                                            ),
                                          ) ??
                                          false;
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (!otpOk) {
                                        setState(() => _submitting = false);
                                        return;
                                      }
                                      setState(() => _submitting = false);
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1570EF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      app.t('login_to_account'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isSmall ? 18 : 20,
                                          ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 20 : 26),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: <Widget>[
                          Text(
                            app.t('dont_have_account'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF475467),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              app.t('signup'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF1570EF),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 14 : 20),
                    Text(
                      app.t('terms_privacy_notice'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontSize: isSmall ? 14 : 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  UserRole _role = UserRole.patient;
  bool _submitting = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidSriLankanPhone(String value) {
    return _isValidLkPhone(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final Size size = MediaQuery.of(context).size;
    final bool isSmall = size.width < 380;
    final bool isTablet = size.width >= 768;
    final double contentMaxWidth = isTablet ? 620 : 560;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: isSmall ? 18 : 28,
              ),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x190F172A),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmall ? 16 : 24,
                          isSmall ? 20 : 26,
                          isSmall ? 16 : 24,
                          isSmall ? 16 : 20,
                        ),
                        child: Column(
                          children: <Widget>[
                            ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Color(0x38FFFFFF),
                                BlendMode.screen,
                              ),
                              child: Image.asset(
                                'assets/images/vitaltrack_logo_symbol.png',
                                height: isTablet ? 110 : (isSmall ? 80 : 96),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                semanticLabel: 'VitalTrack Logo',
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.monitor_heart,
                                  size: 84,
                                  color: Color(0xFF1E5AA8),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            Text(
                              app.t('create_account'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w700,
                                    fontSize: isSmall ? 40 * 0.8 : 40 * 0.9,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              app.t('join_vitaltrack'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF667085),
                                    fontWeight: FontWeight.w500,
                                    fontSize: isSmall ? 16 : 18,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE4E7EC)),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmall ? 16 : 24,
                          isSmall ? 18 : 24,
                          isSmall ? 16 : 24,
                          isSmall ? 20 : 26,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _role = UserRole.patient,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        margin: const EdgeInsets.all(6),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _role == UserRole.patient
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          app.t('patient'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _role == UserRole.patient
                                                ? const Color(0xFF1570EF)
                                                : const Color(0xFF475467),
                                            fontSize: isSmall ? 15 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _role = UserRole.caregiver,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        margin: const EdgeInsets.all(6),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _role == UserRole.caregiver
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          app.t('caregiver'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _role == UserRole.caregiver
                                                ? const Color(0xFF1570EF)
                                                : const Color(0xFF475467),
                                            fontSize: isSmall ? 15 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            Text(
                              app.t('name'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().length < 2) {
                                  return app.t('required_field');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            Text(
                              app.t('phone_number_lk'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: '07XXXXXXXX',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return app.t('required_field');
                                }
                                final String fullPhone =
                                    _normalizeLkPhoneForApi(value.trim());
                                if (!_isValidSriLankanPhone(fullPhone)) {
                                  return app.t('invalid_lk_phone');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            Text(
                              '${app.t('email')} (${app.t('optional')})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'name@example.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                if (!value.contains('@')) {
                                  return app.t('invalid_email');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            Text(
                              app.t('password'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (String? value) {
                                if (value == null || value.length < 6) {
                                  return app.t('password_min');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            Text(
                              app.t('re_enter_password'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              validator: (String? value) {
                                if (value != _passwordController.text) {
                                  return app.t('password_mismatch');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmall ? 12 : 16),
                            SizedBox(
                              height: isSmall ? 52 : 58,
                              child: FilledButton(
                                onPressed: _submitting
                                    ? null
                                    : () async {
                                        if (_formKey.currentState?.validate() !=
                                            true) {
                                          return;
                                        }

                                        setState(() => _submitting = true);
                                        final NavigatorState navigator =
                                            Navigator.of(context);
                                        final String phone =
                                            _normalizeLkPhoneForApi(
                                              _phoneController.text.trim(),
                                            );
                                        final String? email =
                                            _emailController.text.trim().isEmpty
                                            ? null
                                            : _emailController.text.trim();
                                        final String typedName = _nameController
                                            .text
                                            .trim();
                                        final String signupName = typedName;

                                        try {
                                          await authService.sendOtp(
                                            credential: phone,
                                            type: 'phone',
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          final String friendly =
                                              _friendlyAuthError(
                                                e,
                                                app: app,
                                                fallback: app.t(
                                                  'send_otp_failed',
                                                ),
                                              );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(friendly)),
                                          );
                                          setState(() => _submitting = false);
                                          return;
                                        }

                                        final bool otpOk =
                                            await navigator.push<bool>(
                                              MaterialPageRoute<bool>(
                                                builder: (_) => OtpVerificationScreen(
                                                  title: app.t(
                                                    'phone_otp_verification',
                                                  ),
                                                  subtitle: app.t(
                                                    'enter_otp_signup',
                                                  ),
                                                  credential: phone,
                                                  navigateToDashboardOnSuccess:
                                                      true,
                                                  onVerifiedSuccess: () async {
                                                    await app.signup(
                                                      email: email,
                                                      phone: phone,
                                                      password:
                                                          _passwordController
                                                              .text
                                                              .trim(),
                                                      name: signupName,
                                                      role:
                                                          _role ==
                                                              UserRole.patient
                                                          ? 'patient'
                                                          : 'caregiver',
                                                    );
                                                  },
                                                ),
                                              ),
                                            ) ??
                                            false;
                                        if (!context.mounted) {
                                          return;
                                        }
                                        if (!otpOk) {
                                          setState(() => _submitting = false);
                                          return;
                                        }
                                        setState(() => _submitting = false);
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1570EF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        app.t('signup'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                              ),
                            ),
                            SizedBox(height: isSmall ? 16 : 20),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6,
                                children: <Widget>[
                                  Text(
                                    app.t('already_have_account'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: const Color(0xFF475467),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      app.t('login'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF1570EF),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.credential,
    this.onVerifyOtp,
    this.onVerifiedSuccess,
    this.navigateToDashboardOnSuccess = false,
  });

  final String title;
  final String subtitle;
  final String credential;
  final Future<void> Function(String otp)? onVerifyOtp;
  final Future<void> Function()? onVerifiedSuccess;
  final bool navigateToDashboardOnSuccess;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    return FormScreenScaffold(
      title: widget.title,
      maxWidth: 520,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(
            title: app.t('otp_verification'),
            subtitle: widget.subtitle,
            icon: Icons.verified_user_outlined,
          ),
          UiSpace.xs,
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(labelText: app.t('otp_code')),
          ),
          UiSpace.xs,
          BusyFilledButton(
            isBusy: _verifying,
            label: app.t('verify'),
            onPressed: () async {
              if (_otpController.text.trim().length == 6) {
                setState(() => _verifying = true);
                try {
                  if (widget.onVerifyOtp != null) {
                    await widget.onVerifyOtp!(_otpController.text.trim());
                  } else {
                    await authService.verifyOtp(
                      credential: widget.credential,
                      otp: _otpController.text.trim(),
                    );
                  }

                  if (widget.onVerifiedSuccess != null) {
                    await widget.onVerifiedSuccess!();
                  }

                  if (!context.mounted) return;

                  if (widget.navigateToDashboardOnSuccess) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const DashboardRouter(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                    return;
                  }

                  Navigator.of(context).pop(true);
                } catch (e) {
                  if (!context.mounted) return;
                  final String friendly = _friendlyAuthError(
                    e,
                    app: app,
                    fallback: app.t('otp_verify_failed'),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(friendly)));
                  setState(() => _verifying = false);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(app.t('enter_valid_otp'))),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

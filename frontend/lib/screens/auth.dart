import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../app/scope.dart';
import '../app/state.dart';
import '../services/index.dart';
import 'root_router.dart';

String _friendlyAuthError(
  Object error, {
  required AppState app,
  required String fallback,
}) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError) {
      return app.t('backend_unreachable');
    }

    if (error.response?.statusCode == 409) {
      return app.t('account_exists_login');
    }

    final Object? responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final Object? errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic>) {
        final String code = (errorObj['code'] ?? '').toString();
        final String message = (errorObj['message'] ?? '').toString();
        final Map<String, dynamic>? details =
            errorObj['details'] is Map<String, dynamic>
            ? errorObj['details'] as Map<String, dynamic>
            : null;

        if (code == 'EMAIL_ALREADY_EXISTS' ||
            message.toLowerCase().contains('email already')) {
          return app.t('email_exists_error');
        }

        if (code == 'PHONE_ALREADY_EXISTS' ||
            message.toLowerCase().contains('phone') &&
                message.toLowerCase().contains('already')) {
          return app.t('phone_exists_error');
        }

        if (code == 'USER_ALREADY_EXISTS' ||
            message.toLowerCase().contains('already registered') ||
            message.toLowerCase().contains('user already')) {
          return app.t('account_exists_login');
        }

        if (code == 'AUTHENTICATION_ERROR' &&
            (message.toLowerCase().contains('invalid credentials') ||
                message.toLowerCase().contains('user not found'))) {
          return app.t('invalid_login_credentials');
        }

        if (message.toLowerCase().contains('otp request limit reached')) {
          final int? retryAfterSeconds = (details?['retryAfterSeconds'] as num?)
              ?.toInt();
          if (retryAfterSeconds != null && retryAfterSeconds > 0) {
            return '${app.t('otp_send_limit_reached')} ${app.t('try_again_in_seconds')} ${_formatSecondsAsMmSs(retryAfterSeconds)}.';
          }
          return app.t('otp_send_limit_reached');
        }

        if (message.toLowerCase().contains('password must include')) {
          return app.t('password_policy_error');
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
  if (raw.contains('already registered') || raw.contains('user already')) {
    return app.t('account_exists_login');
  }
  if (raw.contains('invalid otp')) {
    return app.t('invalid_otp_error');
  }
  if (raw.contains('invalid credentials') || raw.contains('user not found')) {
    return app.t('invalid_login_credentials');
  }
  if (raw.contains('otp request limit reached')) {
    return app.t('otp_send_limit_reached');
  }
  if (raw.contains('password must include')) {
    return app.t('password_policy_error');
  }
  if (raw.contains('phone number is not verified')) {
    return app.t('phone_not_verified_profile');
  }
  if (raw.contains('not verified')) {
    return app.t('email_not_verified_profile');
  }
  if (raw.contains('otp has expired') || raw.contains('otp not found')) {
    return app.t('otp_expired_error');
  }
  if (raw.contains('connection refused') ||
      raw.contains('xmlhttprequest onerror')) {
    return app.t('backend_unreachable');
  }
  return fallback;
}

int? _extractRetryAfterSeconds(Object error) {
  if (error is! DioException) {
    return null;
  }

  final Object? responseData = error.response?.data;
  if (responseData is! Map<String, dynamic>) {
    return null;
  }

  final Object? errorObj = responseData['error'];
  if (errorObj is! Map<String, dynamic>) {
    return null;
  }

  final Object? detailsObj = errorObj['details'];
  if (detailsObj is! Map<String, dynamic>) {
    return null;
  }

  return (detailsObj['retryAfterSeconds'] as num?)?.toInt();
}

String _formatSecondsAsMmSs(int totalSeconds) {
  final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  final int minutes = safeSeconds ~/ 60;
  final int seconds = safeSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _normalizeLkPhoneForApi(String localInput) {
  return localInput.replaceAll(RegExp(r'\D'), '');
}

bool _isEmailCredential(String value) {
  return value.trim().contains('@');
}

String _credentialType(String value) {
  return _isEmailCredential(value) ? 'email' : 'phone';
}

String _normalizeCredentialForApi(String value) {
  final String trimmed = value.trim();
  if (_isEmailCredential(trimmed)) {
    return trimmed;
  }
  return _normalizeLkPhoneForApi(trimmed);
}

bool _isValidLkPhone(String phone) {
  final String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return RegExp(r'^(07[0-9]{8}|7[0-9]{8}|94[0-9]{9})$').hasMatch(cleaned);
}

bool _isValidEmail(String value) {
  final String normalized = value.trim();
  return RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  ).hasMatch(normalized);
}

bool _isStrongPassword(String password) {
  final String value = password.trim();
  return value.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(value) &&
      !RegExp(r'\s').hasMatch(value);
}

String _otpTimestampText() {
  final DateTime now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
}

void _showOtpSentSnackBar(
  BuildContext context, {
  String? devOtp,
  int? remainingAttempts,
  int? maxAttempts,
}) {
  final AppState app = AppScope.of(context);
  final String ts = _otpTimestampText();
  final String attemptsSuffix = remainingAttempts != null && maxAttempts != null
      ? ' • ${app.t('otp_attempts_left')}: $remainingAttempts/$maxAttempts'
      : '';
  final String codeSuffix = (devOtp != null && devOtp.isNotEmpty)
      ? ' • DEV: $devOtp'
      : '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('${app.t('otp_sent_at')} • $ts$attemptsSuffix$codeSuffix'),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetLoginInputs() {
    _credentialController.clear();
    _passwordController.clear();
    _formKey.currentState?.reset();
  }

  bool _shouldClearLoginInputs(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return true;
    }

    final String raw = error.toString().toLowerCase();
    return raw.contains('invalid credentials') ||
        raw.contains('user not found');
  }

  Future<void> _startForgotPasswordFlow(AppState app) async {
    final String initialCredential = _credentialController.text.trim();

    final TextEditingController credentialController = TextEditingController(
      text: initialCredential,
    );
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    Map<String, String>? result;

    try {
      result = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          bool submitting = false;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: Text(app.t('forgot_password')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: credentialController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: app.t('mobile_or_email'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: app.t('forgot_new_password'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: app.t('forgot_confirm_password'),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(app.t('cancel')),
                  ),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () {
                            final String credentialRaw = credentialController
                                .text
                                .trim();
                            final String newPassword = newPasswordController
                                .text
                                .trim();
                            final String confirmPassword =
                                confirmPasswordController.text.trim();

                            if (credentialRaw.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(app.t('required_field')),
                                ),
                              );
                              return;
                            }

                            if (_isEmailCredential(credentialRaw)) {
                              if (!_isValidEmail(credentialRaw)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(app.t('invalid_email')),
                                  ),
                                );
                                return;
                              }
                            } else {
                              final String phone = _normalizeLkPhoneForApi(
                                credentialRaw,
                              );
                              if (!_isValidLkPhone(phone)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(app.t('invalid_lk_phone')),
                                  ),
                                );
                                return;
                              }
                            }

                            if (!_isStrongPassword(newPassword)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(app.t('password_policy_error')),
                                ),
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(app.t('password_mismatch')),
                                ),
                              );
                              return;
                            }

                            final String normalizedCredential =
                                _normalizeCredentialForApi(credentialRaw);

                            setDialogState(() => submitting = true);
                            Navigator.of(dialogContext).pop(<String, String>{
                              'credential': normalizedCredential,
                              'type': _credentialType(credentialRaw),
                              'newPassword': newPassword,
                            });
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(app.t('send_otp')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      credentialController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }

    if (result == null || !mounted) {
      return;
    }

    final String credential = result['credential'] ?? '';
    final String type = result['type'] ?? 'phone';
    final String newPassword = result['newPassword'] ?? '';

    String? devOtp;
    int? remainingAttempts;
    int? maxAttempts;
    try {
      final response = await authService.sendForgotPasswordOtp(
        credential: credential,
        type: type,
      );
      devOtp = response['otp']?.toString();
      remainingAttempts = (response['remainingAttempts'] as num?)?.toInt();
      maxAttempts = (response['maxAttempts'] as num?)?.toInt();
      if (!mounted) return;
      _showOtpSentSnackBar(
        context,
        devOtp: devOtp,
        remainingAttempts: remainingAttempts,
        maxAttempts: maxAttempts,
      );
    } catch (e) {
      if (!mounted) return;
      final String friendly = _friendlyAuthError(
        e,
        app: app,
        fallback: app.t('send_otp_failed'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
      return;
    }

    final bool resetOk =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OtpVerificationScreen(
              title: app.t('otp_verification'),
              subtitle: app.t('reset_password_otp_subtitle'),
              credential: credential,
              devModeOtp: devOtp,
              onVerifyOtp: (String otp) async {
                await authService.resetPassword(
                  credential: credential,
                  otp: otp,
                  newPassword: newPassword,
                );
              },
              onResendOtp: () async {
                return authService.sendForgotPasswordOtp(
                  credential: credential,
                  type: type,
                );
              },
            ),
          ),
        ) ??
        false;

    if (!mounted) return;
    if (resetOk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('password_reset_success'))));
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final Size size = MediaQuery.of(context).size;
    final bool isSmall = size.width < 380;
    final bool isTablet = size.width >= 768;
    final double contentMaxWidth = isTablet ? 620 : 560;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: isSmall ? 24 : 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/vitaltrack_logo_symbol.png',
                      height: isTablet ? 120 : (isSmall ? 88 : 104),
                      fit: BoxFit.contain,
                      semanticLabel: 'VitalTrack Logo',
                      errorBuilder: (_, _, _) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEE9FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monitor_heart,
                          size: 64,
                          color: Color(0xFF0F66D9),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 24 : 32),
                    Text(
                      app.t('monitor_precision'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF344054),
                            fontSize: isTablet ? 22 : (isSmall ? 18 : 20),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: isSmall ? 24 : 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(isSmall ? 18 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            app.t('mobile_or_email'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _credentialController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const <String>[
                              AutofillHints.username,
                            ],
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return app.t('required_field');
                              }

                              if (_isEmailCredential(value)) {
                                if (!_isValidEmail(value)) {
                                  return app.t('invalid_email');
                                }
                                return null;
                              }

                              final String normalizedPhone =
                                  _normalizeLkPhoneForApi(value.trim());
                              if (!_isValidLkPhone(normalizedPhone)) {
                                return app.t('invalid_lk_phone');
                              }
                              return null;
                            },
                          ),
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
                                onPressed: () => _startForgotPasswordFlow(app),
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
                              if (value == null || value.trim().isEmpty) {
                                return app.t('required_field');
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
                                      final String rawCredential =
                                          _credentialController.text.trim();
                                      final String credential =
                                          _normalizeCredentialForApi(
                                            rawCredential,
                                          );
                                      final String otpType = _credentialType(
                                        rawCredential,
                                      );
                                      String? devOtp;
                                      int? remainingAttempts;
                                      int? maxAttempts;

                                      try {
                                        await authService.checkLoginCredentials(
                                          credential: credential,
                                          password: _passwordController.text
                                              .trim(),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        final String friendly =
                                            _friendlyAuthError(
                                              e,
                                              app: app,
                                              fallback: app.t(
                                                'invalid_login_credentials',
                                              ),
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(friendly)),
                                        );
                                        if (_shouldClearLoginInputs(e)) {
                                          _resetLoginInputs();
                                        }
                                        setState(() => _submitting = false);
                                        return;
                                      }

                                      try {
                                        final response = await authService
                                            .sendOtp(
                                              credential: credential,
                                              type: otpType,
                                              purpose: 'login',
                                            );
                                        devOtp = response['otp']?.toString();
                                        remainingAttempts =
                                            (response['remainingAttempts']
                                                    as num?)
                                                ?.toInt();
                                        maxAttempts =
                                            (response['maxAttempts'] as num?)
                                                ?.toInt();
                                        if (!context.mounted) return;
                                        _showOtpSentSnackBar(
                                          context,
                                          devOtp: devOtp,
                                          remainingAttempts: remainingAttempts,
                                          maxAttempts: maxAttempts,
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
                                                    devModeOtp: devOtp,
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
  final GlobalKey<FormState> _identifierFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

  bool _otpSending = false;
  bool _identifierVerified = false;
  bool _creating = false;
  String? _verifiedCredentialType;
  String? _verifiedCredential;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool get _isPasswordMismatch {
    final String confirm = _confirmController.text.trim();
    if (confirm.isEmpty) {
      return false;
    }
    return confirm != _passwordController.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyIdentifierFirst(AppState app) async {
    if (_identifierFormKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _otpSending = true);
    final NavigatorState navigator = Navigator.of(context);
    final String rawCredential = _identifierController.text.trim();
    final String type = _credentialType(rawCredential);
    final String normalizedCredential = _normalizeCredentialForApi(
      rawCredential,
    );

    String? devOtp;
    int? remainingAttempts;
    int? maxAttempts;
    try {
      final response = await authService.sendOtp(
        credential: normalizedCredential,
        type: type,
        purpose: 'signup',
      );
      devOtp = response['otp']?.toString();
      remainingAttempts = (response['remainingAttempts'] as num?)?.toInt();
      maxAttempts = (response['maxAttempts'] as num?)?.toInt();
      if (!mounted) return;
      _showOtpSentSnackBar(
        context,
        devOtp: devOtp,
        remainingAttempts: remainingAttempts,
        maxAttempts: maxAttempts,
      );
    } catch (e) {
      if (!mounted) return;
      final String friendly = _friendlyAuthError(
        e,
        app: app,
        fallback: app.t('send_otp_failed'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
      setState(() => _otpSending = false);
      return;
    }

    final bool otpOk =
        await navigator.push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OtpVerificationScreen(
              title: app.t('otp_verification'),
              subtitle: type == 'email'
                  ? app.t('enter_otp_sent_email')
                  : app.t('enter_otp_signup'),
              credential: normalizedCredential,
              devModeOtp: devOtp,
              onResendOtp: () async {
                return authService.sendOtp(
                  credential: normalizedCredential,
                  type: type,
                  purpose: 'signup',
                );
              },
            ),
          ),
        ) ??
        false;

    if (!mounted) {
      return;
    }

    if (otpOk) {
      setState(() {
        _identifierVerified = true;
        _verifiedCredentialType = type;
        _verifiedCredential = normalizedCredential;
        _otpSending = false;
      });
      return;
    }

    setState(() => _otpSending = false);
  }

  Future<void> _createAccount(AppState app) async {
    if (_profileFormKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _creating = true);
    final String verifiedType = _verifiedCredentialType ?? '';
    final String verifiedCredential = _verifiedCredential ?? '';

    if (verifiedType.isEmpty || verifiedCredential.isEmpty) {
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('verify_identifier_first'))));
      return;
    }

    final String? email = verifiedType == 'email' ? verifiedCredential : null;
    final String? phone = verifiedType == 'phone' ? verifiedCredential : null;

    try {
      await app.signup(
        identifier: verifiedCredential,
        email: email,
        phone: phone,
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        verifiedCredentialType: verifiedType,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardRouter()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final String friendly = _friendlyAuthError(
        e,
        app: app,
        fallback: app.t('signup_failed'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
      setState(() => _creating = false);
    }
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
                            _identifierVerified
                                ? app.t('identifier_verified_complete_profile')
                                : app.t('verify_identifier_first'),
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
                          if (!_identifierVerified)
                            Form(
                              key: _identifierFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Text(
                                    app.t('mobile_or_email'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _identifierController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const <String>[
                                      AutofillHints.username,
                                    ],
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.alternate_email,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return app.t('required_field');
                                      }

                                      if (_isEmailCredential(value.trim())) {
                                        if (!_isValidEmail(value.trim())) {
                                          return app.t('invalid_email');
                                        }
                                        return null;
                                      }

                                      final String fullPhone =
                                          _normalizeLkPhoneForApi(value.trim());
                                      if (!_isValidLkPhone(fullPhone)) {
                                        return app.t('invalid_lk_phone');
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isSmall ? 14 : 18),
                                  SizedBox(
                                    height: isSmall ? 52 : 58,
                                    child: FilledButton(
                                      onPressed: _otpSending
                                          ? null
                                          : () => _verifyIdentifierFirst(app),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1570EF,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: _otpSending
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Text(app.t('verify_identifier')),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Form(
                              key: _profileFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.verified_user,
                                        color: Color(0xFF1570EF),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _verifiedCredential ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: const Color(0xFF101828),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _creating
                                            ? null
                                            : () => setState(() {
                                                _identifierVerified = false;
                                                _verifiedCredentialType = null;
                                                _verifiedCredential = null;
                                              }),
                                        child: Text(app.t('change')),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmall ? 14 : 18),
                                  Text(
                                    app.t('name'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().length < 2) {
                                        return app.t('required_field');
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isSmall ? 14 : 18),
                                  Text(
                                    app.t('password'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          !_isStrongPassword(value)) {
                                        return app.t('password_policy_error');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Builder(
                                    builder: (context) {
                                      final String value = _passwordController
                                          .text
                                          .trim();
                                      final List<Map<String, dynamic>>
                                      rules = <Map<String, dynamic>>[
                                        <String, dynamic>{
                                          'ok': value.length >= 8,
                                          'label': app.t(
                                            'password_rule_min_length',
                                          ),
                                        },
                                        <String, dynamic>{
                                          'ok': RegExp(
                                            r'[A-Z]',
                                          ).hasMatch(value),
                                          'label': app.t(
                                            'password_rule_uppercase',
                                          ),
                                        },
                                        <String, dynamic>{
                                          'ok': RegExp(
                                            r'[a-z]',
                                          ).hasMatch(value),
                                          'label': app.t(
                                            'password_rule_lowercase',
                                          ),
                                        },
                                        <String, dynamic>{
                                          'ok': RegExp(r'\d').hasMatch(value),
                                          'label': app.t(
                                            'password_rule_number',
                                          ),
                                        },
                                        <String, dynamic>{
                                          'ok': RegExp(
                                            r'[^A-Za-z0-9]',
                                          ).hasMatch(value),
                                          'label': app.t(
                                            'password_rule_special',
                                          ),
                                        },
                                        <String, dynamic>{
                                          'ok': !RegExp(r'\s').hasMatch(value),
                                          'label': app.t(
                                            'password_rule_no_spaces',
                                          ),
                                        },
                                      ];

                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE4E7EC),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: rules.map((rule) {
                                            final bool ok =
                                                rule['ok'] as bool? ?? false;
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                children: <Widget>[
                                                  Icon(
                                                    ok
                                                        ? Icons.check_circle
                                                        : Icons
                                                              .radio_button_unchecked,
                                                    size: 16,
                                                    color: ok
                                                        ? const Color(
                                                            0xFF12B76A,
                                                          )
                                                        : const Color(
                                                            0xFF98A2B3,
                                                          ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      rule['label']
                                                              as String? ??
                                                          '',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: ok
                                                                ? const Color(
                                                                    0xFF027A48,
                                                                  )
                                                                : const Color(
                                                                    0xFF475467,
                                                                  ),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: isSmall ? 14 : 18),
                                  Text(
                                    app.t('re_enter_password'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: true,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.verified_user_outlined,
                                      ),
                                      errorText: _isPasswordMismatch
                                          ? app.t('password_mismatch')
                                          : null,
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
                                      onPressed: _creating
                                          ? null
                                          : () => _createAccount(app),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1570EF,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: _creating
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Text(app.t('signup')),
                                    ),
                                  ),
                                ],
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
                                  style: Theme.of(context).textTheme.titleMedium
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
    this.onResendOtp,
    this.onVerifiedSuccess,
    this.navigateToDashboardOnSuccess = false,
    this.devModeOtp,
  });

  final String title;
  final String subtitle;
  final String credential;
  final Future<void> Function(String otp)? onVerifyOtp;
  final Future<Map<String, dynamic>?> Function()? onResendOtp;
  final Future<void> Function()? onVerifiedSuccess;
  final bool navigateToDashboardOnSuccess;
  final String? devModeOtp;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendCooldownTimer;

  String get _otpValue => _otpController.text;

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _resendCooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = seconds);

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
      } else {
        setState(() => _resendCooldownSeconds -= 1);
      }
    });
  }

  Future<void> _verifyOtp(AppState app) async {
    if (_verifying) {
      return;
    }

    if (_otpValue.trim().length == 6) {
      setState(() => _verifying = true);
      try {
        if (widget.onVerifyOtp != null) {
          await widget.onVerifyOtp!(_otpValue.trim());
        } else {
          await authService.verifyOtp(
            credential: widget.credential,
            otp: _otpValue.trim(),
          );
        }

        if (widget.onVerifiedSuccess != null) {
          await widget.onVerifiedSuccess!();
        }

        if (!mounted) return;

        if (widget.navigateToDashboardOnSuccess) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const DashboardRouter()),
            (Route<dynamic> route) => false,
          );
          return;
        }

        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('enter_valid_otp'))));
    }
  }

  Future<void> _resendOtp(AppState app) async {
    if (_resending || _resendCooldownSeconds > 0) return;
    setState(() => _resending = true);
    try {
      if (widget.onResendOtp != null) {
        final response = await widget.onResendOtp!();
        final String? devOtp = response?['otp']?.toString();
        final int? remainingAttempts = (response?['remainingAttempts'] as num?)
            ?.toInt();
        final int? maxAttempts = (response?['maxAttempts'] as num?)?.toInt();
        if (!mounted) return;
        _showOtpSentSnackBar(
          context,
          devOtp: devOtp,
          remainingAttempts: remainingAttempts,
          maxAttempts: maxAttempts,
        );
        return;
      } else {
        final String type = widget.credential.contains('@') ? 'email' : 'phone';
        final response = await authService.sendOtp(
          credential: widget.credential,
          type: type,
        );
        final String? devOtp = response['otp']?.toString();
        final int? remainingAttempts = (response['remainingAttempts'] as num?)
            ?.toInt();
        final int? maxAttempts = (response['maxAttempts'] as num?)?.toInt();
        if (!mounted) return;
        _showOtpSentSnackBar(
          context,
          devOtp: devOtp,
          remainingAttempts: remainingAttempts,
          maxAttempts: maxAttempts,
        );
        return;
      }
    } catch (e) {
      final int? retryAfterSeconds = _extractRetryAfterSeconds(e);
      if (retryAfterSeconds != null && retryAfterSeconds > 0) {
        _startResendCooldown(retryAfterSeconds);
      }

      if (!mounted) return;
      final String friendly = _friendlyAuthError(
        e,
        app: app,
        fallback: app.t('send_otp_failed'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final Size size = MediaQuery.of(context).size;
    final bool isSmall = size.width < 380;
    final bool isTablet = size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 14 : 24,
                    vertical: isSmall ? 14 : 18,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x1A0F172A),
                          blurRadius: 26,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: isSmall ? 74 : 84,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 14 : 20,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF344054),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 17 : 19,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B1736),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFD9DEE8),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 56 : (isSmall ? 20 : 28),
                              vertical: isSmall ? 26 : 36,
                            ),
                            child: Column(
                              children: <Widget>[
                                Image.asset(
                                  'assets/images/vitaltrack_logo_symbol.png',
                                  height: isSmall ? 120 : 146,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'VitalTrack Logo',
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.monitor_heart,
                                    size: 120,
                                    color: Color(0xFF1E5AA8),
                                  ),
                                ),
                                SizedBox(height: isSmall ? 22 : 30),
                                Text(
                                  widget.credential.contains('@')
                                      ? app.t('verify_your_email')
                                      : app.t('verify_your_number'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 26 : 30,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B1736),
                                  ),
                                ),
                                SizedBox(height: isSmall ? 10 : 12),
                                Text(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 14 : 16,
                                    height: 1.35,
                                    color: const Color(0xFF475467),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.credential,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                                ),
                                SizedBox(height: isSmall ? 26 : 34),
                                SizedBox(
                                  width: isTablet ? 420 : double.infinity,
                                  child: TextField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    onSubmitted: (_) => _verifyOtp(app),
                                    style: TextStyle(
                                      fontSize: isSmall ? 22 : 24,
                                      letterSpacing: 7,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B1736),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '------',
                                      hintStyle: TextStyle(
                                        letterSpacing: 7,
                                        color: const Color(0xFF98A2B3),
                                        fontSize: isSmall ? 20 : 22,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F8FA),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: isSmall ? 18 : 22,
                                        horizontal: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD0D7E2),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD0D7E2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF2B77CB),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmall ? 30 : 38),
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmall ? 56 : 64,
                                  child: FilledButton(
                                    onPressed: _verifying
                                        ? null
                                        : () => _verifyOtp(app),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF1F78D1),
                                      disabledBackgroundColor: const Color(
                                        0xFF1F78D1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 6,
                                      shadowColor: const Color(0x3306458A),
                                    ),
                                    child: _verifying
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            app.t('verify'),
                                            style: TextStyle(
                                              fontSize: isSmall ? 22 / 1.2 : 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(height: isSmall ? 24 : 30),
                                // Dev mode OTP display
                                if (widget.devModeOtp != null &&
                                    widget.devModeOtp!.isNotEmpty) ...<Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      border: Border.all(
                                        color: Colors.amber[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          app.t('dev_mode_otp'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber[900],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          widget.devModeOtp!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.amber[900],
                                            letterSpacing: 2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmall ? 24 : 30),
                                ],
                                Text(
                                  app.t('didnt_receive_code'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 14 : 15,
                                    color: const Color(0xFF667085),
                                  ),
                                ),
                                if (_resendCooldownSeconds > 0) ...<Widget>[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${app.t('try_again_in_seconds')} ${_formatSecondsAsMmSs(_resendCooldownSeconds)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isSmall ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475467),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed:
                                      _resending || _resendCooldownSeconds > 0
                                      ? null
                                      : () => _resendOtp(app),
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: Color(0xFF1F78D1),
                                  ),
                                  label: Text(
                                    app.t('resend_code'),
                                    style: TextStyle(
                                      fontSize: isSmall ? 15 : 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F78D1),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1F78D1),
                                    disabledForegroundColor: const Color(
                                      0xFF1F78D1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isSmall ? 16 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../app/models.dart';
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
    if (error.response?.statusCode == 409) {
      return 'Account already exists. Please login.';
    }

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

        if (code == 'USER_ALREADY_EXISTS' ||
            message.toLowerCase().contains('already registered') ||
            message.toLowerCase().contains('user already')) {
          return 'Account already exists. Please login.';
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
    return 'Account already exists. Please login.';
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

  Future<void> _startForgotPasswordFlow(AppState app) async {
    final bool isEmail = _method == LoginMethod.email;
    final String initialCredential = isEmail
        ? _emailController.text.trim()
        : _phoneController.text.trim();

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
                        keyboardType: isEmail
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: isEmail ? app.t('email') : app.t('phone'),
                          hintText: isEmail
                              ? 'example@email.com'
                              : '07XXXXXXXX',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
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
                    child: const Text('Cancel'),
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

                            if (isEmail) {
                              if (!credentialRaw.contains('@')) {
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

                            if (newPassword.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(app.t('password_min'))),
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Passwords do not match'),
                                ),
                              );
                              return;
                            }

                            final String normalizedCredential = isEmail
                                ? credentialRaw
                                : _normalizeLkPhoneForApi(credentialRaw);

                            setDialogState(() => submitting = true);
                            Navigator.of(dialogContext).pop(<String, String>{
                              'credential': normalizedCredential,
                              'type': isEmail ? 'email' : 'phone',
                              'newPassword': newPassword,
                            });
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send OTP'),
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

    try {
      await authService.sendForgotPasswordOtp(
        credential: credential,
        type: type,
      );
      if (!mounted) return;
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
              subtitle: 'Enter the 6-digit code to reset your password',
              credential: credential,
              onVerifyOtp: (String otp) async {
                await authService.resetPassword(
                  credential: credential,
                  otp: otp,
                  newPassword: newPassword,
                );
              },
              onResendOtp: () async {
                await authService.sendForgotPasswordOtp(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful. Please login again.'),
        ),
      );
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
                                                    'otp_verification',
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
    this.onResendOtp,
    this.onVerifiedSuccess,
    this.navigateToDashboardOnSuccess = false,
  });

  final String title;
  final String subtitle;
  final String credential;
  final Future<void> Function(String otp)? onVerifyOtp;
  final Future<void> Function()? onResendOtp;
  final Future<void> Function()? onVerifiedSuccess;
  final bool navigateToDashboardOnSuccess;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _digitControllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List<FocusNode>.generate(
    6,
    (_) => FocusNode(),
  );
  bool _verifying = false;
  bool _resending = false;

  String get _otpValue => _digitControllers
      .map((TextEditingController controller) => controller.text)
      .join();

  @override
  void initState() {
    super.initState();
    for (final FocusNode focusNode in _digitFocusNodes) {
      focusNode.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _digitControllers) {
      controller.dispose();
    }
    for (final FocusNode focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleDigitChanged(int index, String value) {
    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 1) {
      for (int i = 0; i < 6; i++) {
        _digitControllers[i].text = i < digitsOnly.length ? digitsOnly[i] : '';
      }
      if (digitsOnly.length >= 6) {
        _digitFocusNodes.last.unfocus();
      } else {
        _digitFocusNodes[digitsOnly.length].requestFocus();
      }
      setState(() {});
      return;
    }

    _digitControllers[index].text = digitsOnly;

    if (digitsOnly.isNotEmpty) {
      if (index < 5) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _digitFocusNodes[index - 1].requestFocus();
    }

    setState(() {});
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
    if (_resending) return;
    setState(() => _resending = true);
    try {
      if (widget.onResendOtp != null) {
        await widget.onResendOtp!();
      } else {
        final String type = widget.credential.contains('@') ? 'email' : 'phone';
        await authService.sendOtp(credential: widget.credential, type: type);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent')));
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
        child: Center(
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
                              'Verify your number',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmall ? 30 : 34,
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
                                fontSize: isSmall ? 17 : 19,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF101828),
                              ),
                            ),
                            SizedBox(height: isSmall ? 26 : 34),
                            SizedBox(
                              width: isTablet ? 420 : double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(6, (int index) {
                                  return Container(
                                    width: isSmall ? 44 : 52,
                                    height: isSmall ? 64 : 74,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isSmall ? 4 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _digitFocusNodes[index].hasFocus
                                            ? const Color(0xFF2B77CB)
                                            : const Color(0xFFD0D7E2),
                                        width: _digitFocusNodes[index].hasFocus
                                            ? 2
                                            : 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: TextField(
                                      controller: _digitControllers[index],
                                      focusNode: _digitFocusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      textInputAction: index == 5
                                          ? TextInputAction.done
                                          : TextInputAction.next,
                                      maxLength: 1,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(1),
                                      ],
                                      onChanged: (String value) =>
                                          _handleDigitChanged(index, value),
                                      onSubmitted: (_) {
                                        if (index == 5) {
                                          _verifyOtp(app);
                                        }
                                      },
                                      style: TextStyle(
                                        fontSize: isSmall ? 20 : 24,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0B1736),
                                      ),
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        filled: false,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        isCollapsed: true,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  );
                                }),
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
                            Text(
                              "Didn't receive a code?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmall ? 15 : 16,
                                color: const Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _resending
                                  ? null
                                  : () => _resendOtp(app),
                              icon: const Icon(
                                Icons.refresh,
                                size: 20,
                                color: Color(0xFF1F78D1),
                              ),
                              label: Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: isSmall ? 17 : 18,
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
      ),
    );
  }
}

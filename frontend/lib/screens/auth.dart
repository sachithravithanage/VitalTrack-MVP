import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/form_screen_scaffold.dart';
import '../widgets/selection_controls.dart';
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
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    return FormScreenScaffold(
      title: app.t('login'),
      maxWidth: 560,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _AuthHeaderCard(
              title: app.t('login'),
              subtitle: app.t('login_subtitle'),
            ),
            UiSpace.sm,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedInputSection<UserRole>(
                  label: app.t('login_as'),
                  selected: _role,
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
                  onSelectionChanged: (Set<UserRole> value) {
                    setState(() => _role = value.first);
                  },
                ),
              ),
            ),
            UiSpace.md,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SegmentedInputSection<LoginMethod>(
                      label: app.t('login_method'),
                      selected: _method,
                      segments: <ButtonSegment<LoginMethod>>[
                        ButtonSegment<LoginMethod>(
                          value: LoginMethod.number4n,
                          label: Text(app.t('n4_number')),
                        ),
                        ButtonSegment<LoginMethod>(
                          value: LoginMethod.email,
                          label: Text(app.t('email')),
                        ),
                      ],
                      onSelectionChanged: (Set<LoginMethod> value) {
                        setState(() => _method = value.first);
                      },
                    ),
                    UiSpace.sm,
                    TextFormField(
                      controller: _credentialController,
                      keyboardType: _method == LoginMethod.email
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          _method == LoginMethod.email
                              ? Icons.alternate_email_rounded
                              : Icons.phone_outlined,
                        ),
                        labelText: _method == LoginMethod.email
                            ? app.t('email')
                            : app.t('n4_number'),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return app.t('required_field');
                        }
                        if (_method == LoginMethod.email &&
                            !value.contains('@')) {
                          return app.t('invalid_email');
                        }
                        return null;
                      },
                    ),
                    UiSpace.sm,
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        labelText: app.t('password'),
                      ),
                      validator: (String? value) {
                        if (value == null || value.length < 6) {
                          return app.t('password_min');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            UiSpace.md,
            BusyFilledButton(
              isBusy: _submitting,
              label: app.t('continue'),
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                setState(() => _submitting = true);
                final NavigatorState navigator = Navigator.of(context);
                final String credential = _credentialController.text.trim();
                final String otpType = _method == LoginMethod.email
                    ? 'email'
                    : 'phone';

                try {
                  await authService.sendOtp(
                    credential: credential,
                    type: otpType,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  final String friendly = _friendlyAuthError(
                    e,
                    app: app,
                    fallback: app.t('send_otp_failed'),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(friendly)));
                  setState(() => _submitting = false);
                  return;
                }

                final bool otpOk =
                    await navigator.push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => OtpVerificationScreen(
                          title: app.t('otp_verification'),
                          subtitle: app.t('enter_otp_login'),
                          credential: credential,
                          navigateToDashboardOnSuccess: true,
                          onVerifiedSuccess: () async {
                            await app.login(
                              credential: credential,
                              password: _passwordController.text.trim(),
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
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
                );
              },
              child: Text(app.t('no_account_signup')),
            ),
          ],
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
    final String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return RegExp(r'^(94|0)?7[0-9]{8}$').hasMatch(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    return FormScreenScaffold(
      title: app.t('signup'),
      maxWidth: 560,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _AuthHeaderCard(
              title: app.t('signup'),
              subtitle: app.t('signup_subtitle'),
            ),
            UiSpace.sm,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedInputSection<UserRole>(
                  label: app.t('login_as'),
                  selected: _role,
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
                  onSelectionChanged: (Set<UserRole> value) =>
                      setState(() => _role = value.first),
                ),
              ),
            ),
            UiSpace.sm,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        labelText: app.t('name'),
                      ),
                      validator: (String? value) =>
                          (value == null || value.trim().isEmpty)
                          ? app.t('required_field')
                          : null,
                    ),
                    UiSpace.sm,
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_outlined),
                        labelText: app.t('phone_number_lk'),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return app.t('required_field');
                        }
                        if (!_isValidSriLankanPhone(value.trim())) {
                          return app.t('invalid_lk_phone');
                        }
                        return null;
                      },
                    ),
                    UiSpace.sm,
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        labelText: '${app.t('email')} (${app.t('optional')})',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (!value.contains('@')) return app.t('invalid_email');
                        return null;
                      },
                    ),
                    UiSpace.sm,
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        labelText: app.t('password'),
                      ),
                      validator: (String? value) {
                        if (value == null || value.length < 6) {
                          return app.t('password_min');
                        }
                        return null;
                      },
                    ),
                    UiSpace.sm,
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        labelText: app.t('re_enter_password'),
                      ),
                      validator: (String? value) {
                        if (value != _passwordController.text) {
                          return app.t('password_mismatch');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            UiSpace.md,
            BusyFilledButton(
              isBusy: _submitting,
              label: app.t('create_account'),
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                setState(() => _submitting = true);
                final NavigatorState navigator = Navigator.of(context);
                final String phone = _phoneController.text.trim();

                try {
                  await authService.sendOtp(credential: phone, type: 'phone');
                } catch (e) {
                  if (!context.mounted) return;
                  final String friendly = _friendlyAuthError(
                    e,
                    app: app,
                    fallback: app.t('send_otp_failed'),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(friendly)));
                  setState(() => _submitting = false);
                  return;
                }

                final bool otpOk =
                    await navigator.push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => OtpVerificationScreen(
                          title: app.t('phone_otp_verification'),
                          subtitle: app.t('enter_otp_signup'),
                          credential: phone,
                          navigateToDashboardOnSuccess: true,
                          onVerifiedSuccess: () async {
                            await app.signup(
                              email: _emailController.text.trim(),
                              phone: phone,
                              password: _passwordController.text.trim(),
                              name: _nameController.text.trim(),
                              role: _role == UserRole.patient
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
            ),
          ],
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

class _AuthHeaderCard extends StatelessWidget {
  const _AuthHeaderCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                height: 52,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/vitaltrack_logo_symbol.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.monitor_heart,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

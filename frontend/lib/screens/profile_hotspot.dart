import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../services/index.dart';
import '../widgets/action_buttons.dart';
import '../widgets/input_sections.dart';
import 'auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final user = app.currentUser!;
    final TextEditingController nameController = TextEditingController(
      text: user.name,
    );
    final TextEditingController phoneController = TextEditingController(
      text: user.phone,
    );
    final TextEditingController emailController = TextEditingController(
      text: user.email ?? '',
    );
    final List<PatientSummary> linked = app.caregiverPatients(user.id);

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
        Text(app.t('profile'), style: Theme.of(context).textTheme.titleLarge),
        UiSpace.sm,
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: app.t('name')),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(labelText: app.t('phone')),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: app.t('email')),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () async {
            final String emailCredential = emailController.text.trim();
            if (emailCredential.isEmpty || !emailCredential.contains('@')) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(app.t('invalid_email'))));
              return;
            }

            try {
              await authService.sendOtp(
                credential: emailCredential,
                type: 'email',
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
              return;
            }

            final bool verified =
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => OtpVerificationScreen(
                      title: app.t('email_verification'),
                      subtitle: app.t('enter_email_otp'),
                      credential: emailCredential,
                    ),
                  ),
                ) ??
                false;
            if (verified) {
              app.markEmailVerified();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(app.t('email_verified'))),
                );
              }
            }
          },
          child: Text(
            user.emailVerified ? app.t('verified') : app.t('verify_email'),
          ),
        ),
        UiSpace.xs,
        FilledButton(
          onPressed: () {
            app.updateProfile(
              name: nameController.text.trim(),
              phone: phoneController.text.trim(),
              email: emailController.text.trim(),
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(app.t('profile_updated'))));
          },
          child: Text(app.t('save')),
        ),
        if (user.role == UserRole.patient) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            app.t('add_caregiver'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          UiSpace.xs,
          FilledButton.tonal(
            onPressed: () async {
              final String code = await app.generateCaregiverCode();
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(app.t('caregiver_code')),
                    content: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: <Widget>[
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
          UiSpace.xs,
          Text(
            app.t('caregivers_list'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (linked.isEmpty)
            EmptyStateCard(
              icon: Icons.group_outlined,
              title: app.t('no_caregivers_yet'),
              subtitle: app.t('generate_6_digit_code'),
            )
          else
            Text(linked.map((PatientSummary p) => p.name).join(', ')),
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
    final String defaultSubject = app.currentUser!.name;
    final List<HotspotResponse> history = app.hotspotResponsesForSubject(
      defaultSubject,
    );

    return ResponsiveListView(
      children: <Widget>[
        SectionHeader(
          title: app.t('hotspot_map'),
          subtitle: widget.forCaregiverPatientData
              ? app.t('patients')
              : app.t('patient'),
          icon: Icons.map_outlined,
        ),
        UiSpace.xs,
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.teal.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Text(
              app.t('hotspot_map_placeholder'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        UiSpace.sm,
        InputSection(
          title: widget.forCaregiverPatientData
              ? app.t('add_patient_hotspot_data')
              : app.t('add_hotspot_data'),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
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
                    app.submitHotspot(
                      subject: subject,
                      hometown: _hometownController.text.trim(),
                      workplace: _workplaceController.text.trim(),
                      places: _placesController.text.trim(),
                    );
                    _subjectController.clear();
                    _hometownController.clear();
                    _workplaceController.clear();
                    _placesController.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(app.t('saved'))));
                      setState(() => _saving = false);
                    }
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

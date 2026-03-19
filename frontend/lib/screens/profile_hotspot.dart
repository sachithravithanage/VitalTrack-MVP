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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController emailController;
  bool _relationshipsLoaded = false;
  Timer? _refreshTimer;

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

      if (!_relationshipsLoaded) {
        _relationshipsLoaded = true;
        unawaited(_loadRelationships(app, currentUser.role));
        _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
          if (!mounted) return;
          unawaited(_loadRelationships(app, currentUser.role));
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

  Future<void> _addEmail(AppState app) async {
    final String? email = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(app.t('email')),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'name@example.com'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(app.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(emailController.text),
              child: Text(app.t('save')),
            ),
          ],
        );
      },
    );

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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.t('profile_updated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
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
        if ((user.email ?? '').trim().isNotEmpty)
          _profileInfoTile(
            context,
            icon: Icons.email_outlined,
            label: app.t('email'),
            value: user.email!,
          )
        else
          FilledButton.tonal(
            onPressed: () => _addEmail(app),
            child: const Text('Add Email'),
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
                            style: Theme.of(context).textTheme.titleMedium
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
                      final String code = await app.generateCaregiverCode();
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
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  linkedCaregivers
                      .map(
                        (Map<String, dynamic> c) =>
                            (c['name'] ?? '').toString(),
                      )
                      .where((String n) => n.trim().isNotEmpty)
                      .join(', '),
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

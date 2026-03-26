import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/selection_controls.dart';
import 'records.dart';

class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  State<CaregiverPatientsScreen> createState() =>
      _CaregiverPatientsScreenState();
}

class _CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  Timer? _refreshTimer;
  bool _loadingPatients = false;

  Future<void> _refreshPatients(AppState app) async {
    if (_loadingPatients) {
      return;
    }

    _loadingPatients = true;
    try {
      await app.loadCaregiverPatients();
    } catch (_) {
      // Ignore background refresh errors.
    } finally {
      _loadingPatients = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    unawaited(_refreshPatients(app));
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      unawaited(_refreshPatients(app));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final caregiver = app.currentUser!;
    final List<PatientSummary> patients = app.caregiverPatients(caregiver.id);

    return ResponsiveListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      children: <Widget>[
        Text(
          app.t('patient_directory'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF0A1430),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          app.t('review_linked_patients'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607089)),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              app
                  .t('active_patients_count')
                  .replaceAll('{count}', patients.length.toString()),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1E73D8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (patients.isEmpty)
          EmptyStateCard(
            icon: Icons.person_search_outlined,
            title: app.t('no_patients'),
            subtitle: app.t('add_patient'),
          )
        else
          ...patients.map((PatientSummary patient) {
            final String diseaseLabel = patient.disease == DiseaseType.dengue
                ? app.t('dengue')
                : app.t('rat_fever');
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CaregiverPatientRecordsScreen(patient: patient),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF1E73D8),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              patient.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: const Color(0xFF0A1430),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  diseaseLabel,
                                ).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                diseaseLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: _statusColor(diseaseLabel),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF95A5BC),
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 10),
        BusyFilledButton(
          isBusy: false,
          label: app.t('add_patient'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddPatientScreen()),
            );
          },
        ),
      ],
    );
  }

  Color _statusColor(String disease) {
    if (disease.toLowerCase().contains('rat')) {
      return const Color(0xFFC62828);
    }
    if (disease.toLowerCase().contains('recover')) {
      return const Color(0xFF0C7A53);
    }
    if (disease.toLowerCase().contains('influenza')) {
      return const Color(0xFF1E73D8);
    }
    return const Color(0xFFB45309);
  }
}

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  bool _useCode = true;
  bool _saving = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DiseaseType _disease = DiseaseType.dengue;

  String _friendlyAttachPatientError(Object error, AppState app) {
    if (error is DioException) {
      final int? statusCode = error.response?.statusCode;

      String backendCode = '';
      String backendMessage = '';
      final Object? responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final Object? errorObj = responseData['error'];
        if (errorObj is Map<String, dynamic>) {
          backendCode = (errorObj['code'] ?? '').toString().toLowerCase();
          backendMessage = (errorObj['message'] ?? '').toString();
        }
      }

      final String messageLower = backendMessage.toLowerCase();
      final bool invalidCodeError =
          (statusCode == 404 &&
              (backendCode == 'not_found' ||
                  messageLower.contains('invalid link code'))) ||
          (statusCode == 400 && messageLower.contains('expired'));

      if (invalidCodeError) {
        return app.t('invalid_code');
      }

      if (statusCode == 409 && messageLower.contains('already linked')) {
        return app.t('patient_linked');
      }

      if (backendMessage.isNotEmpty) {
        return backendMessage;
      }
    }

    return '${app.t('error')}: ${error.toString()}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          app.t('add_patient'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A1430),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4EAF3)),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            children: <Widget>[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EFFB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.pin_outlined,
                          color: Color(0xFF1E73D8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _useCode
                              ? app.t('enter_caregiver_code')
                              : app.t('create_patient_profile'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF0A1430),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SegmentedInputSection<bool>(
                        label: app.t('use_6_digit_code'),
                        selected: _useCode,
                        segments: <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(app.t('use_6_digit_code')),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(app.t('create_new_patient')),
                          ),
                        ],
                        onSelectionChanged: (Set<bool> value) {
                          setState(() => _useCode = value.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _useCode
                            ? app.t('enter_code_shared_by_patient')
                            : app.t('create_link_patient_manually'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF607089),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_useCode)
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 3.5,
                            fontWeight: FontWeight.w700,
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().length != 6) {
                              return app.t('invalid_code');
                            }
                            return null;
                          },
                        ),
                      if (!_useCode) ...<Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: app.t('patient_name'),
                            hintText: app.t('patient_name'),
                          ),
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                              ? app.t('required_field')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<DiseaseType>(
                          initialValue: _disease,
                          decoration: InputDecoration(
                            labelText: app.t('condition'),
                          ),
                          items: <DropdownMenuItem<DiseaseType>>[
                            DropdownMenuItem<DiseaseType>(
                              value: DiseaseType.dengue,
                              child: Text(app.t('dengue')),
                            ),
                            DropdownMenuItem<DiseaseType>(
                              value: DiseaseType.ratFever,
                              child: Text(app.t('rat_fever')),
                            ),
                          ],
                          onChanged: (DiseaseType? value) {
                            if (value != null) setState(() => _disease = value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              BusyFilledButton(
                isBusy: _saving,
                label: app.t('confirm'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true) return;
                  setState(() => _saving = true);

                  if (_useCode) {
                    final String code = _codeController.text.trim();
                    try {
                      await app.attachPatientToCaregiver(
                        code: code,
                        disease: _disease.toString().split('.').last,
                      );
                      unawaited(app.loadCaregiverPatients());
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_friendlyAttachPatientError(e, app)),
                        ),
                      );
                      setState(() => _saving = false);
                      return;
                    }
                  } else {
                    try {
                      await app.createManagedPatient(
                        name: _nameController.text.trim(),
                        disease: _disease.toString().split('.').last,
                      );
                      unawaited(app.loadCaregiverPatients());
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${app.t('error')}: $e')),
                      );
                      setState(() => _saving = false);
                      return;
                    }
                  }

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(app.t('patient_added'))),
                  );
                  setState(() => _saving = false);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaregiverPatientRecordsScreen extends StatefulWidget {
  const CaregiverPatientRecordsScreen({super.key, required this.patient});

  final PatientSummary patient;

  @override
  State<CaregiverPatientRecordsScreen> createState() =>
      _CaregiverPatientRecordsScreenState();
}

class _CaregiverPatientRecordsScreenState
    extends State<CaregiverPatientRecordsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final List<Widget> pages = <Widget>[
      RecordFormScreen(
        patientId: widget.patient.id,
        disease: widget.patient.disease,
        titlePrefix: app.t('add_record'),
      ),
      RecordsListScreen(
        patientId: widget.patient.id,
        canAddFromHere: false,
        defaultDisease: widget.patient.disease,
      ),
    ];
    final List<DashboardDestination> destinations = <DashboardDestination>[
      DashboardDestination(icon: Icons.edit, label: app.t('add_record')),
      DashboardDestination(icon: Icons.list, label: app.t('show_records')),
    ];

    return AdaptiveDashboardShell(
      title: app.t('patient_options_title'),
      selectedIndex: _tab,
      onDestinationSelected: (int value) => setState(() => _tab = value),
      destinations: destinations,
      pages: pages,
    );
  }
}

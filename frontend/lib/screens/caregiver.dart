import 'package:flutter/material.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/selection_controls.dart';
import 'records.dart';

class CaregiverPatientsScreen extends StatelessWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final caregiver = app.currentUser!;
    final List<PatientSummary> patients = app.caregiverPatients(caregiver.id);

    return ResponsiveListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _HeaderTab(label: 'My Patients', selected: true, onTap: () {}),
              const SizedBox(width: 20),
              _HeaderTab(
                label: 'Recent Activity',
                selected: false,
                onTap: () {},
              ),
              const SizedBox(width: 20),
              _HeaderTab(label: 'Resources', selected: false, onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Patient Directory',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: const Color(0xFF0A1430),
            fontWeight: FontWeight.w800,
          ),
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
              '${patients.length} Active',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              margin: const EdgeInsets.only(bottom: 12),
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
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              patient.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: const Color(0xFF0A1430),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      diseaseLabel,
                                    ).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    diseaseLabel.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: _statusColor(diseaseLabel),
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '• ${_diseaseStateLabel(patient.disease)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: const Color(0xFF61728E),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF95A5BC),
                        size: 34,
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
          label: 'Add New Patient',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddPatientScreen()),
            );
          },
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(36),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x331E73D8),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Text(
              '✱',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
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

  String _diseaseStateLabel(DiseaseType type) {
    return type == DiseaseType.dengue ? 'Stable' : 'Monitoring';
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
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
              Row(
                children: <Widget>[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7EFFB),
                      borderRadius: BorderRadius.circular(31),
                    ),
                    child: const Icon(
                      Icons.pin_outlined,
                      color: Color(0xFF1E73D8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _useCode
                          ? 'Enter 6-Digit Patient Code'
                          : 'Create New Patient Profile',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: const Color(0xFF0A1430),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _useCode
                    ? 'If the patient is already registered, enter the unique code shared by them or their primary caregiver to link accounts.'
                    : 'Set up a brand new profile to start tracking health metrics and medications for a new patient.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF435874),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 18),
              if (_useCode) ...<Widget>[
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  style: const TextStyle(
                    fontSize: 1,
                    color: Colors.transparent,
                  ),
                  cursorColor: Colors.transparent,
                  validator: (String? value) {
                    if (value == null || value.trim().length != 6) {
                      return app.t('invalid_code');
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double gap = 8;
                    final double width =
                        ((constraints.maxWidth - (gap * 5)) / 6).clamp(36, 56);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(6, (int i) {
                        final String text = i < _codeController.text.length
                            ? _codeController.text[i]
                            : '';
                        return Container(
                          width: width,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD4DFEE)),
                          ),
                          child: Text(
                            text,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E2C44),
                                ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
              if (!_useCode) ...<Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    hintText: 'Enter patient full name',
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DiseaseType>(
                  initialValue: _disease,
                  decoration: const InputDecoration(labelText: 'Condition'),
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
              const SizedBox(height: 18),
              if (_useCode) ...<Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider(color: Color(0xFFD7E1EF))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF8C9CB3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFD7E1EF))),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _useCode = false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4DFEE)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Start Registration',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: const Color(0xFF0A1430),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'This takes about 2 minutes',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: const Color(0xFF6D7D95)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF95A5BC),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
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
                      await app.loadCaregiverPatients();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${app.t('error')}: $e')),
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
                      await app.loadCaregiverPatients();
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
              const SizedBox(height: 16),
              Text(
                'Need help? Contact VitalTrack Support',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF5E708A),
                ),
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

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: selected
              ? const Border(
                  bottom: BorderSide(color: Color(0xFF1E73D8), width: 3),
                )
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: selected ? const Color(0xFF1E73D8) : const Color(0xFF657892),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
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
      title: widget.patient.name,
      selectedIndex: _tab,
      onDestinationSelected: (int value) => setState(() => _tab = value),
      destinations: destinations,
      pages: pages,
    );
  }
}

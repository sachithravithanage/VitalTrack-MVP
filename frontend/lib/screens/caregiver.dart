import 'package:flutter/material.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/form_screen_scaffold.dart';
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
      children: <Widget>[
        SectionHeader(
          title: app.t('patients'),
          subtitle: app.t('add_patient'),
          icon: Icons.groups_2_outlined,
        ),
        UiSpace.xs,
        FilledButton.icon(
          icon: const Icon(Icons.person_add),
          label: Text(app.t('add_patient')),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddPatientScreen()),
            );
          },
        ),
        UiSpace.sm,
        if (patients.isEmpty)
          EmptyStateCard(
            icon: Icons.person_search_outlined,
            title: app.t('no_patients'),
            subtitle: app.t('add_patient'),
          )
        else
          ...patients.map((PatientSummary patient) {
            return Card(
              child: ListTile(
                title: Text(patient.name),
                subtitle: Text(
                  patient.disease == DiseaseType.dengue
                      ? app.t('dengue')
                      : app.t('rat_fever'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CaregiverPatientRecordsScreen(patient: patient),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
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

    return FormScreenScaffold(
      title: app.t('add_patient'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(
              title: app.t('add_patient'),
              subtitle: app.t('use_6_digit_code'),
              icon: Icons.person_add_alt_1,
            ),
            UiSpace.sm,
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
              onSelectionChanged: (Set<bool> value) =>
                  setState(() => _useCode = value.first),
            ),
            UiSpace.sm,
            if (_useCode)
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: app.t('caregiver_code')),
                validator: (String? value) {
                  if (value == null || value.trim().length != 6) {
                    return app.t('invalid_code');
                  }
                  return null;
                },
              ),
            if (!_useCode)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: app.t('patient_name')),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? app.t('required_field')
                    : null,
              ),
            if (!_useCode) const SizedBox(height: 10),
            if (!_useCode)
              DropdownButtonFormField<DiseaseType>(
                initialValue: _disease,
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
            const SizedBox(height: 14),
            BusyFilledButton(
              isBusy: _saving,
              label: app.t('confirm'),
              onPressed: () {
                if (_formKey.currentState?.validate() != true) return;
                setState(() => _saving = true);

                if (_useCode) {
                  final String code = _codeController.text.trim();
                  app.attachPatientToCaregiver(
                    code: code,
                    disease: _disease.toString().split('.').last,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(app.t('manual_entry_not_supported')),
                    ),
                  );
                  setState(() => _saving = false);
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(app.t('patient_added'))));
                setState(() => _saving = false);
                Navigator.of(context).pop();
              },
            ),
          ],
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
      title: widget.patient.name,
      selectedIndex: _tab,
      onDestinationSelected: (int value) => setState(() => _tab = value),
      destinations: destinations,
      pages: pages,
    );
  }
}

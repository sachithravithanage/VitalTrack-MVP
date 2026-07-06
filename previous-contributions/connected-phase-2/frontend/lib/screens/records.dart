import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';

class KeepRecordsSelectorScreen extends StatelessWidget {
  const KeepRecordsSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final String patientId = app.currentUser!.id;
    final String firstName = app.currentUser!.name.trim().isEmpty
        ? app.t('patient')
        : app.currentUser!.name.trim().split(' ').first;

    final RecordEntry? latest =
        app.filteredRecords(patientId, TimelineFilter.last24h).isNotEmpty
        ? app.filteredRecords(patientId, TimelineFilter.last24h).first
        : null;

    return ResponsiveListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: <Widget>[
        Text(
          app.t('good_morning_name').replaceAll('{name}', firstName),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0A1430),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          app.t('how_feeling_today'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: const Color(0xFF5F7391)),
        ),
        const SizedBox(height: 28),
        Text(
          app.t('keep_records'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A1430),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          app.t('select_condition_track_daily'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xFF5F7391)),
        ),
        const SizedBox(height: 16),
        _DiseaseSelectorTile(
          title: app.t('dengue'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RecordFormScreen(
                  patientId: patientId,
                  disease: DiseaseType.dengue,
                  titlePrefix: app.t('add_record'),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _DiseaseSelectorTile(
          title: app.t('rat_fever'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RecordFormScreen(
                  patientId: patientId,
                  disease: DiseaseType.ratFever,
                  titlePrefix: app.t('add_record'),
                ),
              ),
            );
          },
        ),
        if (latest != null) const SizedBox(height: 16),
        if (latest != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD5E5FA)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.history, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        app
                            .t('last_entry_prefix')
                            .replaceAll(
                              '{time}',
                              _relativeTimeLabel(context, latest.createdAt),
                            ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF24344F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app
                            .t('disease_monitoring')
                            .replaceAll(
                              '{disease}',
                              latest.disease == DiseaseType.dengue
                                  ? app.t('dengue')
                                  : app.t('rat_fever'),
                            ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: const Color(0xFF5F7391)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({
    super.key,
    required this.patientId,
    required this.disease,
    required this.titlePrefix,
  });

  final String patientId;
  final DiseaseType disease;
  final String titlePrefix;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _fluidController = TextEditingController();
  final TextEditingController _urineOutputController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _ratUrineColor = 'yellow';
  String _eyeColoration = 'normal';

  final Map<String, bool> _dengueSymptoms = <String, bool>{
    'feverDrop': false,
    'coldClammyHandsFeet': false,
    'vomiting': false,
    'dizziness': false,
    'severeRightUpperAbdominalPain': false,
    'poorAppetite': false,
    'suddenReturnOfAppetite': false,
  };

  final Map<String, bool> _ratSymptoms = <String, bool>{
    'suddenReductionUrineOutput': false,
    'inabilityToPassUrine': false,
    'musclePains': false,
    'calfOrLowerBackTenderness': false,
    'bloodshotEyes': false,
    'skinJaundice': false,
    'difficultyBreathing': false,
    'rapidBreathing': false,
    'coughingUpBlood': false,
    'dizziness': false,
  };

  @override
  void dispose() {
    _tempController.dispose();
    _fluidController.dispose();
    _urineOutputController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final bool isDengue = widget.disease == DiseaseType.dengue;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDengue
              ? app.t('record_taking_dengue')
              : app.t('record_taking_rat_fever'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            children: <Widget>[
              Text(
                isDengue
                    ? app.t('dengue_instruction')
                    : app.t('rat_instruction'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF5F7391),
                ),
              ),
              const SizedBox(height: 18),
              if (isDengue) ...<Widget>[
                _FieldLabel(
                  text: app.t('body_temperature_c'),
                  icon: Icons.device_thermostat,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tempController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _formDecoration(hint: '37.8'),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                const SizedBox(height: 16),
                _FieldLabel(
                  text: app.t('fluid_intake_ml_label'),
                  icon: Icons.opacity_rounded,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fluidController,
                  keyboardType: TextInputType.number,
                  decoration: _formDecoration(hint: '250'),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? app.t('required_field')
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              _FieldLabel(
                text: app.t('urine_output_ml_label'),
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urineOutputController,
                keyboardType: TextInputType.number,
                decoration: _formDecoration(hint: isDengue ? '200' : '500'),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? app.t('required_field')
                    : null,
              ),
              const SizedBox(height: 16),
              if (isDengue)
                ..._buildYesNoGroup(
                  context,
                  data: _dengueSymptoms,
                  labels: <String, String>{
                    'feverDrop': app.t('symptom_fever_drop'),
                    'coldClammyHandsFeet': app.t(
                      'symptom_cold_clammy_hands_feet',
                    ),
                    'vomiting': app.t('symptom_vomiting'),
                    'dizziness': app.t('symptom_dizziness'),
                    'severeRightUpperAbdominalPain': app.t(
                      'symptom_severe_abdominal_pain',
                    ),
                    'poorAppetite': app.t('symptom_poor_appetite'),
                    'suddenReturnOfAppetite': app.t(
                      'symptom_return_of_appetite',
                    ),
                  },
                )
              else ...<Widget>[
                _FieldLabel(
                  text: app.t('urine_color'),
                  icon: Icons.colorize_outlined,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _ratUrineColor,
                  decoration: _formDecoration(hint: app.t('urine_color_hint')),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'white',
                      child: Text(app.t('color_white')),
                    ),
                    DropdownMenuItem(
                      value: 'yellow',
                      child: Text(app.t('color_yellow')),
                    ),
                    DropdownMenuItem(
                      value: 'brown',
                      child: Text(app.t('color_brown')),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Text(app.t('color_dark')),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _ratUrineColor = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel(
                  text: app.t('eye_coloration'),
                  icon: Icons.remove_red_eye_outlined,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _eyeColoration,
                  decoration: _formDecoration(
                    hint: app.t('eye_coloration_hint'),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text(app.t('color_normal')),
                    ),
                    DropdownMenuItem(
                      value: 'red',
                      child: Text(app.t('color_red')),
                    ),
                    DropdownMenuItem(
                      value: 'yellow',
                      child: Text(app.t('color_yellow')),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _eyeColoration = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ..._buildYesNoGroup(
                  context,
                  data: _ratSymptoms,
                  labels: <String, String>{
                    'suddenReductionUrineOutput': app.t(
                      'symptom_reduced_urine',
                    ),
                    'inabilityToPassUrine': app.t('symptom_no_urine'),
                    'musclePains': app.t('symptom_muscle_pains'),
                    'calfOrLowerBackTenderness': app.t(
                      'symptom_tenderness_calf_back',
                    ),
                    'bloodshotEyes': app.t('symptom_bloodshot_eyes'),
                    'skinJaundice': app.t('symptom_skin_jaundice'),
                    'difficultyBreathing': app.t(
                      'symptom_difficulty_breathing',
                    ),
                    'rapidBreathing': app.t('symptom_rapid_breathing'),
                    'coughingUpBlood': app.t('symptom_coughing_blood'),
                    'dizziness': app.t('symptom_dizziness'),
                  },
                ),
              ],
              const SizedBox(height: 20),
              _FieldLabel(
                text: app.t('additional_notes_label'),
                icon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: _formDecoration(
                  hint: isDengue
                      ? app.t('notes_hint_dengue')
                      : app.t('notes_hint_rat'),
                ),
              ),
              const SizedBox(height: 24),
              BusyFilledButton(
                isBusy: _saving,
                label: app.t('save_record'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true) return;
                  final isDengue = widget.disease == DiseaseType.dengue;
                  final Map<String, String> values = <String, String>{
                    'urineOutput': _urineOutputController.text.trim(),
                  };
                  final Map<String, bool> symptoms = isDengue
                      ? Map<String, bool>.from(_dengueSymptoms)
                      : Map<String, bool>.from(_ratSymptoms);

                  String? temperature;
                  String? fluidIntake;
                  String? urineColor;

                  if (isDengue) {
                    temperature = _tempController.text.trim();
                    fluidIntake = _fluidController.text.trim();
                    values['temperature'] = temperature;
                    values['fluidIntake'] = fluidIntake;
                  } else {
                    urineColor = _ratUrineColor;
                    values['urineColor'] = _ratUrineColor;
                    values['eyeColoration'] = _eyeColoration;
                  }

                  setState(() => _saving = true);
                  try {
                    await app.addRecord(
                      patientId: widget.patientId,
                      disease: widget.disease == DiseaseType.dengue
                          ? 'dengue'
                          : 'ratFever',
                      temperature: temperature,
                      fluidIntake: fluidIntake,
                      urineOutput: _urineOutputController.text.trim(),
                      urineColor: urineColor,
                      values: values,
                      symptoms: symptoms.isNotEmpty ? symptoms : null,
                      notes: _notesController.text.trim(),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${app.t('error')}: $e')),
                    );
                    setState(() => _saving = false);
                    return;
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(app.t('record_saved'))),
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

  List<Widget> _buildYesNoGroup(
    BuildContext context, {
    required Map<String, bool> data,
    required Map<String, String> labels,
  }) {
    final List<Widget> children = <Widget>[];
    labels.forEach((String key, String label) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _YesNoSelector(
            label: label,
            value: data[key] ?? false,
            onChanged: (bool value) => setState(() => data[key] = value),
          ),
        ),
      );
    });
    return children;
  }

  InputDecoration _formDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF97A6BC), fontSize: 16),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD4DFEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD4DFEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E73D8), width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({
    super.key,
    required this.patientId,
    required this.canAddFromHere,
    this.defaultDisease,
    this.customTitle,
  });

  final String patientId;
  final bool canAddFromHere;
  final DiseaseType? defaultDisease;
  final String? customTitle;

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  TimelineFilter _filter = TimelineFilter.last24h;
  bool _exporting = false;
  bool _loadingRecords = false;
  bool _didInitialLoad = false;
  Timer? _refreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) return;
    _didInitialLoad = true;
    unawaited(_loadRecords());
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      unawaited(_loadRecords());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final AppState app = AppScope.of(context);
    try {
      if (mounted) setState(() => _loadingRecords = true);
      await app.loadPatientRecords(widget.patientId, filter: _filter);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    } finally {
      if (mounted) setState(() => _loadingRecords = false);
    }
  }

  Future<void> _onFilterChanged(TimelineFilter value) async {
    if (_filter == value) return;
    setState(() => _filter = value);
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final List<RecordEntry> records = app.filteredRecords(
      widget.patientId,
      _filter,
    );

    return ResponsiveListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      children: <Widget>[
        Text(
          app.t('recent_logs'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            letterSpacing: 1.2,
            color: const Color(0xFF62728C),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          app.t('disease_records_datetime'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8BA3)),
        ),
        const SizedBox(height: 14),
        if (widget.customTitle != null)
          Text(
            widget.customTitle!,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        if (widget.customTitle != null) const SizedBox(height: 12),
        DropdownButton<TimelineFilter>(
          isExpanded: true,
          value: _filter,
          underline: Container(height: 1, color: const Color(0xFFD4DFEE)),
          items: <DropdownMenuItem<TimelineFilter>>[
            DropdownMenuItem<TimelineFilter>(
              value: TimelineFilter.last24h,
              child: Text(
                app.t('last_24h'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF0A1430)),
              ),
            ),
            DropdownMenuItem<TimelineFilter>(
              value: TimelineFilter.last3Days,
              child: Text(
                app.t('last_3_days'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF0A1430)),
              ),
            ),
            DropdownMenuItem<TimelineFilter>(
              value: TimelineFilter.last7Days,
              child: Text(
                app.t('last_7_days'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF0A1430)),
              ),
            ),
          ],
          onChanged: (TimelineFilter? newFilter) {
            if (newFilter != null) {
              _onFilterChanged(newFilter);
            }
          },
        ),
        const SizedBox(height: 16),
        if (widget.canAddFromHere)
          BusyFilledButton(
            isBusy: false,
            label: app.t('add_record'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecordFormScreen(
                    patientId: widget.patientId,
                    disease: widget.defaultDisease ?? DiseaseType.dengue,
                    titlePrefix: app.t('add_record'),
                  ),
                ),
              );
            },
          ),
        if (widget.canAddFromHere) const SizedBox(height: 10),
        if (_loadingRecords)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  app.t('refreshing'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else if (records.isEmpty)
          EmptyStateCard(
            icon: Icons.inbox_outlined,
            title: app.t('no_records'),
            subtitle: app.t('select_disease'),
          )
        else
          ...records.map((RecordEntry record) {
            final String title = record.disease == DiseaseType.dengue
                ? app.t('dengue_records')
                : app.t('rat_fever_records');
            final String subtitle = app
                .t('entered_datetime')
                .replaceAll(
                  '{datetime}',
                  DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt),
                );
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RecordDetailScreen(record: record),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EEFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF1E73D8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: const Color(0xFF0A1430),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF61728E)),
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
        const SizedBox(height: 14),
        BusyFilledButton(
          isBusy: _exporting,
          label: app.t('export_pdf'),
          onPressed: records.isEmpty
              ? null
              : () async {
                  setState(() => _exporting = true);
                  await _exportPdf(context, app, records);
                  if (mounted) setState(() => _exporting = false);
                },
        ),
      ],
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    AppState app,
    List<RecordEntry> records,
  ) async {
    try {
      // Call backend API to generate and download PDF
      final String pdfUrl = await app.exportRecordsPdf(
        filter: _filter,
        patientId: widget.patientId,
      );

      if (pdfUrl.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(app.t('export_failed'))));
        return;
      }

      final Uri uri = Uri.parse(pdfUrl);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (launched) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(app.t('pdf_downloaded'))));
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(app.t('cannot_open_pdf'))));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    }
  }
}

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});

  final RecordEntry record;

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final String diseaseLabel = record.disease == DiseaseType.dengue
        ? app.t('dengue')
        : app.t('rat_fever');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          app.t('record_details'),
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
      body: ResponsiveListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: <Widget>[
          _DetailHeader(
            title: diseaseLabel,
            subtitle: DateFormat('yyyy-MM-dd • HH:mm').format(record.createdAt),
          ),
          const SizedBox(height: 10),
          _LowPriorityMetaBlock(
            patientId: record.patientId,
            createdBy: record.createdBy,
            recordedAt: DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(record.createdAt),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFDCE4F2)),
          const SizedBox(height: 14),
          if (record.values.isEmpty)
            _DetailItem(title: app.t('data'), value: app.t('no_data'))
          else
            ...record.values.entries.map(
              (MapEntry<String, String> entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DetailItem(
                  title: _prettyFieldLabel(entry.key),
                  value: entry.value.trim().isEmpty ? '-' : entry.value,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            app.t('notes'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 1.2,
              color: const Color(0xFF62728C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _DetailItem(
            title: app.t('additional_notes_label'),
            value: record.notes.trim().isEmpty ? '-' : record.notes,
          ),
        ],
      ),
    );
  }

  String _prettyFieldLabel(String raw) {
    final String spaced = raw
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m.group(1)} ${m.group(2)}',
        )
        .replaceAll('_', ' ')
        .trim();
    if (spaced.isEmpty) return raw;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5E5FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF0A1430),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5F7391)),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7B93),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF0A1430),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowPriorityMetaBlock extends StatelessWidget {
  const _LowPriorityMetaBlock({
    required this.patientId,
    required this.createdBy,
    required this.recordedAt,
  });

  final String patientId;
  final String createdBy;
  final String recordedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppScope.of(
              context,
            ).t('patient_id_line').replaceAll('{value}', patientId),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF70819A),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            AppScope.of(
              context,
            ).t('created_by_line').replaceAll('{value}', createdBy),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF70819A),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            AppScope.of(
              context,
            ).t('recorded_at_line').replaceAll('{value}', recordedAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF70819A),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTimeLabel(BuildContext context, DateTime timestamp) {
  final AppState app = AppScope.of(context);
  final Duration diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 60) {
    return app
        .t('minutes_ago')
        .replaceAll('{count}', diff.inMinutes.clamp(1, 59).toString());
  }
  if (diff.inHours < 24) {
    return app.t('hours_ago').replaceAll('{count}', diff.inHours.toString());
  }
  if (diff.inDays == 1) return app.t('one_day_ago');
  return app.t('days_ago').replaceAll('{count}', diff.inDays.toString());
}

class _DiseaseSelectorTile extends StatelessWidget {
  const _DiseaseSelectorTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A1430),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF95A5BC),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF2D3E5B), size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C2D49),
          ),
        ),
      ],
    );
  }
}

class _YesNoSelector extends StatelessWidget {
  const _YesNoSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4DFEE)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1C2D49),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xFFD9E2F2)),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                label: Text(AppScope.of(context).t('yes')),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(AppScope.of(context).t('no')),
              ),
            ],
            selected: <bool>{value},
            onSelectionChanged: (Set<bool> selected) =>
                onChanged(selected.first),
          ),
        ],
      ),
    );
  }
}

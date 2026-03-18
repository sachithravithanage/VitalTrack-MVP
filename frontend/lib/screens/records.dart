import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import '../widgets/action_buttons.dart';
import '../widgets/form_screen_scaffold.dart';
import '../widgets/selection_controls.dart';

class KeepRecordsSelectorScreen extends StatelessWidget {
  const KeepRecordsSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final String patientId = app.currentUser!.id;
    return ResponsiveListView(
      children: <Widget>[
        SectionHeader(
          title: app.t('keep_records'),
          subtitle: app.t('select_disease'),
          icon: Icons.assignment_outlined,
        ),
        UiSpace.xs,
        Text(
          app.t('select_disease'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        UiSpace.sm,
        Card(
          child: ListTile(
            title: Text(app.t('dengue')),
            trailing: const Icon(Icons.chevron_right),
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
        ),
        Card(
          child: ListTile(
            title: Text(app.t('rat_fever')),
            trailing: const Icon(Icons.chevron_right),
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

  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _fluidController = TextEditingController();
  final TextEditingController _urineOutputController = TextEditingController();
  final TextEditingController _urineColorController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _bodyPain = false;
  bool _vomiting = false;

  @override
  void dispose() {
    _tempController.dispose();
    _fluidController.dispose();
    _urineOutputController.dispose();
    _urineColorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final bool isDengue = widget.disease == DiseaseType.dengue;
    return FormScreenScaffold(
      title:
          '${widget.titlePrefix} - ${isDengue ? app.t('dengue') : app.t('rat_fever')}',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(
              title: widget.titlePrefix,
              subtitle: isDengue ? app.t('dengue') : app.t('rat_fever'),
              icon: Icons.monitor_heart_outlined,
            ),
            UiSpace.sm,
            TextFormField(
              controller: _tempController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: app.t('body_temperature')),
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                  ? app.t('required_field')
                  : null,
            ),
            UiSpace.sm,
            if (isDengue)
              TextFormField(
                controller: _fluidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: app.t('fluid_intake_ml'),
                ),
              ),
            if (isDengue) UiSpace.sm,
            TextFormField(
              controller: _urineOutputController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: app.t('urine_output_ml')),
            ),
            UiSpace.sm,
            if (!isDengue)
              TextFormField(
                controller: _urineColorController,
                decoration: InputDecoration(labelText: app.t('urine_color')),
              ),
            if (!isDengue) UiSpace.sm,
            if (!isDengue)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _bodyPain,
                title: Text(app.t('body_pain')),
                onChanged: (bool? value) =>
                    setState(() => _bodyPain = value ?? false),
              ),
            if (!isDengue)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _vomiting,
                title: Text(app.t('vomiting')),
                onChanged: (bool? value) =>
                    setState(() => _vomiting = value ?? false),
              ),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(labelText: app.t('additional_notes')),
            ),
            UiSpace.md,
            FilledButton(
              onPressed: () {
                if (_formKey.currentState?.validate() != true) return;
                final isDengue = widget.disease == DiseaseType.dengue;
                final Map<String, bool> symptoms = <String, bool>{};
                if (!isDengue) {
                  symptoms['body_pain'] = _bodyPain;
                  symptoms['vomiting'] = _vomiting;
                }
                app.addRecord(
                  disease: widget.disease == DiseaseType.dengue
                      ? 'dengue'
                      : 'ratFever',
                  temperature: _tempController.text.trim(),
                  fluidIntake: isDengue ? _fluidController.text.trim() : null,
                  urineOutput: _urineOutputController.text.trim(),
                  urineColor: isDengue
                      ? null
                      : _urineColorController.text.trim(),
                  symptoms: symptoms.isNotEmpty ? symptoms : null,
                  notes: _notesController.text.trim(),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(app.t('record_saved'))));
                Navigator.of(context).pop();
              },
              child: Text(app.t('save')),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final List<RecordEntry> records = app.filteredRecords(
      widget.patientId,
      _filter,
    );

    return ResponsiveListView(
      children: <Widget>[
        SectionHeader(
          title: app.t('show_records'),
          subtitle: app.t('last_24h'),
          icon: Icons.fact_check_outlined,
        ),
        UiSpace.xs,
        if (widget.customTitle != null)
          Text(
            widget.customTitle!,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        if (widget.customTitle != null) UiSpace.xs,
        TimelineFilterChips(
          current: _filter,
          label24h: app.t('last_24h'),
          label3d: app.t('last_3_days'),
          label7d: app.t('last_7_days'),
          onChanged: (TimelineFilter value) => setState(() => _filter = value),
        ),
        UiSpace.sm,
        if (widget.canAddFromHere)
          FilledButton.tonal(
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
            child: Text(app.t('add_record')),
          ),
        if (widget.canAddFromHere) UiSpace.xs,
        if (records.isEmpty)
          EmptyStateCard(
            icon: Icons.inbox_outlined,
            title: app.t('no_records'),
            subtitle: app.t('select_disease'),
          )
        else
          ...records.map((RecordEntry record) {
            final String ts = DateFormat(
              'yyyy-MM-dd hh:mm a',
            ).format(record.createdAt);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${record.disease == DiseaseType.dengue ? app.t('dengue') : app.t('rat_fever')} • $ts',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...record.values.entries.map(
                      (MapEntry<String, String> e) =>
                          Text('${e.key}: ${e.value}'),
                    ),
                    if (record.notes.isNotEmpty) const SizedBox(height: 4),
                    if (record.notes.isNotEmpty)
                      Text('${app.t('additional_notes')}: ${record.notes}'),
                  ],
                ),
              ),
            );
          }),
        UiSpace.xs,
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
    final pw.Document pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text('VitalTrack Records', style: pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 12),
            ...records.map((RecordEntry record) {
              final String timestamp = DateFormat(
                'yyyy-MM-dd hh:mm a',
              ).format(record.createdAt);
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      '${record.disease == DiseaseType.dengue ? app.t('dengue') : app.t('rat_fever')} - $timestamp',
                    ),
                    ...record.values.entries.map(
                      (MapEntry<String, String> e) =>
                          pw.Text('${e.key}: ${e.value}'),
                    ),
                    if (record.notes.isNotEmpty)
                      pw.Text('${app.t('additional_notes')}: ${record.notes}'),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}

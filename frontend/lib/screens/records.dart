import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(app.t('dengue')),
            subtitle: Text(
              app.t('add_record'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
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
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.bug_report_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(app.t('rat_fever')),
            subtitle: Text(
              app.t('add_record'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
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
  bool _saving = false;

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
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  value: _bodyPain,
                  title: Text(app.t('body_pain')),
                  onChanged: (bool? value) =>
                      setState(() => _bodyPain = value ?? false),
                ),
              ),
            if (!isDengue)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  value: _vomiting,
                  title: Text(app.t('vomiting')),
                  onChanged: (bool? value) =>
                      setState(() => _vomiting = value ?? false),
                ),
              ),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(labelText: app.t('additional_notes')),
            ),
            UiSpace.md,
            BusyFilledButton(
              isBusy: _saving,
              label: app.t('save'),
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                final isDengue = widget.disease == DiseaseType.dengue;
                final Map<String, bool> symptoms = <String, bool>{};
                if (!isDengue) {
                  symptoms['bodyPain'] = _bodyPain;
                  symptoms['vomiting'] = _vomiting;
                }

                setState(() => _saving = true);
                try {
                  await app.addRecord(
                    patientId: widget.patientId,
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
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${app.t('error')}: $e')),
                  );
                  setState(() => _saving = false);
                  return;
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(app.t('record_saved'))));
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) return;
    _didInitialLoad = true;
    _loadRecords();
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

  String _prettyLabel(String key) {
    final normalized = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    if (normalized.isEmpty) return key;
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

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
          onChanged: _onFilterChanged,
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
            final String ts = DateFormat(
              'yyyy-MM-dd hh:mm a',
            ).format(record.createdAt);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      record.disease == DiseaseType.dengue
                          ? app.t('dengue')
                          : app.t('rat_fever'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ts,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...record.values.entries.map(
                      (MapEntry<String, String> e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('${_prettyLabel(e.key)}: ${e.value}'),
                      ),
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

      // Open PDF URL in browser/default app
      // This will download on web and open in PDF viewer on mobile
      final Uri uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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

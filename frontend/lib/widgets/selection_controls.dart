import 'package:flutter/material.dart';

import '../app/models.dart';
import '../app/ui.dart';

class SegmentedInputSection<T> extends StatelessWidget {
  const SegmentedInputSection({
    super.key,
    required this.label,
    required this.selected,
    required this.segments,
    required this.onSelectionChanged,
  });

  final String label;
  final T selected;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        UiSpace.xs,
        SegmentedButton<T>(
          segments: segments,
          selected: <T>{selected},
          onSelectionChanged: onSelectionChanged,
        ),
      ],
    );
  }
}

class TimelineFilterChips extends StatelessWidget {
  const TimelineFilterChips({
    super.key,
    required this.current,
    required this.label24h,
    required this.label3d,
    required this.label7d,
    required this.onChanged,
  });

  final TimelineFilter current;
  final String label24h;
  final String label3d;
  final String label7d;
  final ValueChanged<TimelineFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: <Widget>[
        ChoiceChip(
          label: Text(label24h),
          selected: current == TimelineFilter.last24h,
          onSelected: (_) => onChanged(TimelineFilter.last24h),
        ),
        ChoiceChip(
          label: Text(label3d),
          selected: current == TimelineFilter.last3Days,
          onSelected: (_) => onChanged(TimelineFilter.last3Days),
        ),
        ChoiceChip(
          label: Text(label7d),
          selected: current == TimelineFilter.last7Days,
          onSelected: (_) => onChanged(TimelineFilter.last7Days),
        ),
      ],
    );
  }
}

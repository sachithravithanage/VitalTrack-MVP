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
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        UiSpace.xs,
        SegmentedButton<T>(
          style: ButtonStyle(
            side: const WidgetStatePropertyAll(
              BorderSide(color: Color(0xFFD9E2F2)),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      children: <Widget>[
        ChoiceChip(
          label: Text(label24h),
          selected: current == TimelineFilter.last24h,
          selectedColor: colorScheme.primary.withValues(alpha: 0.16),
          side: const BorderSide(color: Color(0xFFD9E2F2)),
          labelStyle: TextStyle(
            color: current == TimelineFilter.last24h
                ? colorScheme.primary
                : const Color(0xFF475467),
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onChanged(TimelineFilter.last24h),
        ),
        ChoiceChip(
          label: Text(label3d),
          selected: current == TimelineFilter.last3Days,
          selectedColor: colorScheme.primary.withValues(alpha: 0.16),
          side: const BorderSide(color: Color(0xFFD9E2F2)),
          labelStyle: TextStyle(
            color: current == TimelineFilter.last3Days
                ? colorScheme.primary
                : const Color(0xFF475467),
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onChanged(TimelineFilter.last3Days),
        ),
        ChoiceChip(
          label: Text(label7d),
          selected: current == TimelineFilter.last7Days,
          selectedColor: colorScheme.primary.withValues(alpha: 0.16),
          side: const BorderSide(color: Color(0xFFD9E2F2)),
          labelStyle: TextStyle(
            color: current == TimelineFilter.last7Days
                ? colorScheme.primary
                : const Color(0xFF475467),
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onChanged(TimelineFilter.last7Days),
        ),
      ],
    );
  }
}

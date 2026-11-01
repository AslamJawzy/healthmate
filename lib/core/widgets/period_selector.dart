import 'package:flutter/material.dart';

import '../utils/period.dart';

/// Day / Week / Month segmented button (Material 3 component).
class PeriodSelector extends StatelessWidget {
  final Period selected;
  final ValueChanged<Period> onChanged;

  const PeriodSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Period>(
      segments: Period.values
          .map((p) => ButtonSegment<Period>(value: p, label: Text(p.label)))
          .toList(),
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

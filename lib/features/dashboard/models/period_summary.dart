import 'package:flutter/material.dart';

/// Totals for a chosen period (day, week or month), shown on the Dashboard.
class PeriodSummary {
  final DateTimeRange range;
  final int totalSteps;
  final int totalCalories;
  final int totalWater;
  final int daysRecorded; // how many days in the range have a record

  const PeriodSummary({
    required this.range,
    required this.totalSteps,
    required this.totalCalories,
    required this.totalWater,
    required this.daysRecorded,
  });

  /// Number of calendar days in the period (1, 7 or 28 to 31).
  int get daysInRange => range.end.difference(range.start).inDays + 1;

  bool get isEmpty => daysRecorded == 0;

  /// Average per recorded day, so missing days do not pull the average down.
  int averageOf(int total) => daysRecorded == 0 ? 0 : (total / daysRecorded).round();
}

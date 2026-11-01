import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'period.dart';

/// Helper functions for working with dates in one consistent way.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dbFormat = DateFormat('yyyy-MM-dd');

  /// Today's date with the time removed (00:00).
  static DateTime today() => dateOnly(DateTime.now());

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Format used in the database, e.g. 2026-08-18.
  /// This format sorts correctly as text, so SQL can compare dates.
  static String toDbString(DateTime d) => _dbFormat.format(d);

  /// e.g. "Tue, 18 Aug 2026"
  static String friendly(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);

  /// e.g. "18 August 2026"
  static String headline(DateTime d) => DateFormat('d MMMM yyyy').format(d);

  static bool isToday(DateTime d) => dateOnly(d) == today();

  /// Returns the first and last day of the chosen period.
  /// Week = Monday to Sunday. Month = 1st to last day of the month.
  static DateTimeRange rangeFor(Period period, DateTime anchor) {
    final d = dateOnly(anchor);
    switch (period) {
      case Period.day:
        return DateTimeRange(start: d, end: d);
      case Period.week:
        final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        return DateTimeRange(start: monday, end: sunday);
      case Period.month:
        final first = DateTime(d.year, d.month, 1);
        final last = DateTime(d.year, d.month + 1, 0); // day 0 = last day of previous month
        return DateTimeRange(start: first, end: last);
    }
  }

  /// Human readable label for a period, e.g. "Today - 18 August 2026",
  /// "12 Aug - 18 Aug 2026" or "August 2026".
  static String periodLabel(Period period, DateTime anchor) {
    final range = rangeFor(period, anchor);
    switch (period) {
      case Period.day:
        return isToday(anchor) ? 'Today - ${headline(anchor)}' : headline(anchor);
      case Period.week:
        return '${DateFormat('d MMM').format(range.start)} - ${DateFormat('d MMM yyyy').format(range.end)}';
      case Period.month:
        return DateFormat('MMMM yyyy').format(anchor);
    }
  }
}

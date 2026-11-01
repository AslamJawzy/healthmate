import 'package:flutter/material.dart';

import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/period.dart';
import '../../../core/utils/validators.dart';
import '../../dashboard/models/period_summary.dart';
import '../models/health_record.dart';
import '../repositories/health_record_repository.dart';

/// Filter options on the Records screen. "all" shows every record.
enum RecordFilter { all, day, week, month }

extension RecordFilterLabel on RecordFilter {
  String get label {
    switch (this) {
      case RecordFilter.all:
        return 'All';
      case RecordFilter.day:
        return 'Day';
      case RecordFilter.week:
        return 'Week';
      case RecordFilter.month:
        return 'Month';
    }
  }

  Period? get asPeriod {
    switch (this) {
      case RecordFilter.all:
        return null;
      case RecordFilter.day:
        return Period.day;
      case RecordFilter.week:
        return Period.week;
      case RecordFilter.month:
        return Period.month;
    }
  }
}

/// VIEWMODEL LAYER (MVVM)
/// Holds the state of health records for the UI and contains the logic.
/// It extends ChangeNotifier: when data changes it calls notifyListeners()
/// and Provider rebuilds every screen that is listening.
class HealthRecordViewModel extends ChangeNotifier {
  final HealthRecordRepository _repository;

  HealthRecordViewModel(this._repository);

  List<HealthRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  RecordFilter _filter = RecordFilter.all;
  DateTime _filterDate = AppDateUtils.today();

  // ---------- Getters (the UI reads these) ----------
  List<HealthRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RecordFilter get filter => _filter;
  DateTime get filterDate => _filterDate;

  /// Records after applying the selected filter (search by date / period).
  List<HealthRecord> get filteredRecords {
    final period = _filter.asPeriod;
    if (period == null) return records;
    return recordsInRange(AppDateUtils.rangeFor(period, _filterDate));
  }

  String get filterLabel {
    final period = _filter.asPeriod;
    if (period == null) return 'All records';
    return AppDateUtils.periodLabel(period, _filterDate);
  }

  // ---------- Loading ----------
  Future<void> loadRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _records = await _repository.getAllRecords();
    } catch (e) {
      _errorMessage = 'Could not load records. Please try again.';
      debugPrint('loadRecords error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- CRUD ----------
  /// Returns null on success, or an error message to show the user.
  Future<String?> addRecord(HealthRecord record) async {
    try {
      final existing = await _repository.getRecordByDate(record.date);
      if (existing != null) {
        return 'A record for this date already exists. Please edit that record instead.';
      }
      await _repository.insertRecord(record);
      await loadRecords();
      return null;
    } catch (e) {
      debugPrint('addRecord error: $e');
      return 'Could not save the record. Please try again.';
    }
  }

  Future<String?> updateRecord(HealthRecord record) async {
    try {
      final existing = await _repository.getRecordByDate(record.date);
      if (existing != null && existing.id != record.id) {
        return 'Another record already uses this date.';
      }
      await _repository.updateRecord(record);
      await loadRecords();
      return null;
    } catch (e) {
      debugPrint('updateRecord error: $e');
      return 'Could not update the record. Please try again.';
    }
  }

  Future<String?> deleteRecord(HealthRecord record) async {
    if (record.id == null) return 'This record has not been saved yet.';
    // Remove from the list first so the swipe animation finishes cleanly,
    // then delete from the database.
    _records.removeWhere((r) => r.id == record.id);
    notifyListeners();
    try {
      await _repository.deleteRecord(record.id!);
      return null;
    } catch (e) {
      debugPrint('deleteRecord error: $e');
      await loadRecords(); // put the list back the way the database has it
      return 'Could not delete the record.';
    }
  }

  /// Used by the "Undo" button after deleting.
  Future<void> restoreRecord(HealthRecord record) async {
    try {
      await _repository.insertRecord(record); // keeps the original id
      await loadRecords();
    } catch (e) {
      debugPrint('restoreRecord error: $e');
    }
  }

  /// Quick add water from the Dashboard (+250 ml / +500 ml).
  /// Updates the day's record, or creates one if the day has none yet.
  Future<String?> addWater(DateTime date, int ml) async {
    final existing = recordForDate(date);
    if (existing != null) {
      final newWater = (existing.water + ml).clamp(0, Validators.maxWater);
      return updateRecord(existing.copyWith(water: newWater));
    }
    return addRecord(HealthRecord(
      date: AppDateUtils.toDbString(date),
      steps: 0,
      calories: 0,
      water: ml,
    ));
  }

  // ---------- Search / filter ----------
  void setFilter(RecordFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  /// Search by date: show only the chosen day.
  void searchByDate(DateTime date) {
    _filterDate = AppDateUtils.dateOnly(date);
    if (_filter == RecordFilter.all) _filter = RecordFilter.day;
    notifyListeners();
  }

  void clearFilter() {
    _filter = RecordFilter.all;
    _filterDate = AppDateUtils.today();
    notifyListeners();
  }

  // ---------- Helpers used by the Dashboard and forms ----------
  HealthRecord? recordForDate(DateTime date) {
    final key = AppDateUtils.toDbString(date);
    for (final r in _records) {
      if (r.date == key) return r;
    }
    return null;
  }

  List<HealthRecord> recordsInRange(DateTimeRange range) {
    final start = AppDateUtils.toDbString(range.start);
    final end = AppDateUtils.toDbString(range.end);
    // yyyy-MM-dd strings compare in the same order as the dates themselves
    return _records
        .where((r) => r.date.compareTo(start) >= 0 && r.date.compareTo(end) <= 0)
        .toList();
  }

  PeriodSummary summaryFor(Period period, DateTime anchor) {
    final range = AppDateUtils.rangeFor(period, anchor);
    final list = recordsInRange(range);
    int steps = 0, calories = 0, water = 0;
    for (final r in list) {
      steps += r.steps;
      calories += r.calories;
      water += r.water;
    }
    return PeriodSummary(
      range: range,
      totalSteps: steps,
      totalCalories: calories,
      totalWater: water,
      daysRecorded: list.length,
    );
  }
}

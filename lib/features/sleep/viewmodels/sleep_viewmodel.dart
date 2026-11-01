import 'package:flutter/material.dart';

import '../../../core/utils/app_date_utils.dart';
import '../models/sleep_record.dart';
import '../repositories/sleep_repository.dart';

/// VIEWMODEL: sleep history, last night, and the 7-night average.
class SleepViewModel extends ChangeNotifier {
  final SleepRepository _repository;

  SleepViewModel(this._repository);

  List<SleepRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SleepRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The record for the night that ended this morning, if logged.
  SleepRecord? get lastNight {
    final today = AppDateUtils.toDbString(AppDateUtils.today());
    for (final r in _records) {
      if (r.date == today) return r;
    }
    return null;
  }

  SleepRecord? recordForDate(DateTime date) {
    final key = AppDateUtils.toDbString(date);
    for (final r in _records) {
      if (r.date == key) return r;
    }
    return null;
  }

  /// Average minutes slept over the last 7 logged nights.
  int get weeklyAverageMinutes {
    final recent = _records.take(7).toList();
    if (recent.isEmpty) return 0;
    final total = recent.fold<int>(0, (sum, r) => sum + r.durationMinutes);
    return total ~/ recent.length;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _records = await _repository.getAll();
    } catch (e) {
      debugPrint('Sleep load error: $e');
      _errorMessage = 'Could not load sleep records.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save({
    int? id,
    required DateTime date,
    required TimeOfDay bedTime,
    required TimeOfDay wakeTime,
    required int quality,
  }) async {
    if (date.isAfter(AppDateUtils.today())) return 'Date cannot be in the future';
    final minutes = SleepRecord.calculateDuration(bedTime, wakeTime);
    if (minutes > 16 * 60) return 'That is more than 16 hours. Please check the times.';
    if (minutes < 30) return 'Sleep must be at least 30 minutes.';
    try {
      await _repository.save(SleepRecord(
        id: id,
        date: AppDateUtils.toDbString(date),
        bedTime: SleepRecord.timeToText(bedTime),
        wakeTime: SleepRecord.timeToText(wakeTime),
        durationMinutes: minutes,
        quality: quality,
      ));
      await load();
      return null;
    } catch (e) {
      debugPrint('Sleep save error: $e');
      return 'Could not save. Another record may already use this date.';
    }
  }

  Future<void> delete(SleepRecord record) async {
    if (record.id == null) return;
    _records.removeWhere((r) => r.id == record.id);
    notifyListeners();
    try {
      await _repository.delete(record.id!);
    } catch (e) {
      debugPrint('Sleep delete error: $e');
      await load();
    }
  }

  Future<void> restore(SleepRecord record) async {
    await _repository.save(SleepRecord(
      date: record.date,
      bedTime: record.bedTime,
      wakeTime: record.wakeTime,
      durationMinutes: record.durationMinutes,
      quality: record.quality,
    ));
    await load();
  }
}

import 'package:flutter/material.dart';

/// MODEL: one night of sleep (`sleep_records` table).
/// [date] is the morning the user woke up (yyyy-MM-dd).
class SleepRecord {
  final int? id;
  final String date;
  final String bedTime; // "22:30"
  final String wakeTime; // "06:15"
  final int durationMinutes;
  final int quality; // 1 (poor) to 5 (great)

  const SleepRecord({
    this.id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.durationMinutes,
    required this.quality,
  });

  DateTime get dateTime => DateTime.parse(date);

  factory SleepRecord.fromMap(Map<String, dynamic> map) => SleepRecord(
        id: map['id'] as int?,
        date: map['date'] as String,
        bedTime: map['bed_time'] as String,
        wakeTime: map['wake_time'] as String,
        durationMinutes: map['duration_minutes'] as int,
        quality: map['quality'] as int,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'bed_time': bedTime,
      'wake_time': wakeTime,
      'duration_minutes': durationMinutes,
      'quality': quality,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  /// e.g. "7h 30m"
  String get durationText => formatDuration(durationMinutes);

  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  /// Minutes slept between bed time and wake time. Handles going to bed
  /// before midnight (e.g. 22:30 -> 06:00 = 7h 30m).
  static int calculateDuration(TimeOfDay bed, TimeOfDay wake) {
    final bedMinutes = bed.hour * 60 + bed.minute;
    final wakeMinutes = wake.hour * 60 + wake.minute;
    var diff = wakeMinutes - bedMinutes;
    if (diff <= 0) diff += 24 * 60; // crossed midnight
    return diff;
  }

  static String timeToText(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay textToTime(String text) {
    final parts = text.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static const qualityLabels = ['Very poor', 'Poor', 'Okay', 'Good', 'Great'];
  static const qualityEmojis = ['😫', '😕', '😐', '🙂', '😄'];
}

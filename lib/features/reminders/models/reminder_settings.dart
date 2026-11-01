import 'package:flutter/material.dart';

/// MODEL: which reminders are on, and the user's daily routine.
/// All reminder times are worked out from these few settings.
class ReminderSettings {
  final bool breathingEnabled;
  final bool waterEnabled;
  final bool moveEnabled;
  final bool screenTimeEnabled;

  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final TimeOfDay breakfastTime;
  final TimeOfDay lunchTime;
  final TimeOfDay dinnerTime;

  const ReminderSettings({
    this.breathingEnabled = true,
    this.waterEnabled = true,
    this.moveEnabled = true,
    this.screenTimeEnabled = true,
    this.wakeTime = const TimeOfDay(hour: 6, minute: 30),
    this.sleepTime = const TimeOfDay(hour: 22, minute: 30),
    this.breakfastTime = const TimeOfDay(hour: 7, minute: 0),
    this.lunchTime = const TimeOfDay(hour: 13, minute: 0),
    this.dinnerTime = const TimeOfDay(hour: 19, minute: 0),
  });

  static const int waterIntervalMinutes = 90; // every 1.5 hours
  static const int moveIntervalMinutes = 60; // every hour
  static const int screenIntervalMinutes = 60; // every hour
  static const int afterMealMinutes = 120; // 2 hours after a meal

  bool get anyEnabled => breathingEnabled || waterEnabled || moveEnabled || screenTimeEnabled;

  /// Breathing: before breakfast, 2 hours after lunch, 2 hours after dinner.
  /// With the defaults: 7:00 AM, 3:00 PM and 9:00 PM.
  List<TimeOfDay> get breathingTimes => [
        breakfastTime,
        _addMinutes(lunchTime, afterMealMinutes),
        _addMinutes(dinnerTime, afterMealMinutes),
      ];

  /// Water every 1.5 hours, from 1.5 hours after waking until bed time.
  List<TimeOfDay> get waterTimes => _repeat(waterIntervalMinutes, waterIntervalMinutes);

  /// Move every hour, from 1 hour after waking until bed time.
  List<TimeOfDay> get moveTimes => _repeat(moveIntervalMinutes, moveIntervalMinutes);

  /// Screen time check every hour at half past, so it never arrives
  /// together with the "move" reminder.
  List<TimeOfDay> get screenTimeTimes => _repeat(30, screenIntervalMinutes);

  /// Times from (wake + firstOffset) every [step] minutes, before sleep time.
  List<TimeOfDay> _repeat(int firstOffset, int step) {
    final start = _toMinutes(wakeTime) + firstOffset;
    var end = _toMinutes(sleepTime);
    if (end <= _toMinutes(wakeTime)) end += 24 * 60; // bed time after midnight
    final result = <TimeOfDay>[];
    for (var t = start; t < end; t += step) {
      result.add(_fromMinutes(t));
    }
    return result;
  }

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static TimeOfDay _fromMinutes(int minutes) {
    final m = minutes % (24 * 60);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  static TimeOfDay _addMinutes(TimeOfDay t, int minutes) => _fromMinutes(_toMinutes(t) + minutes);

  ReminderSettings copyWith({
    bool? breathingEnabled,
    bool? waterEnabled,
    bool? moveEnabled,
    bool? screenTimeEnabled,
    TimeOfDay? wakeTime,
    TimeOfDay? sleepTime,
    TimeOfDay? breakfastTime,
    TimeOfDay? lunchTime,
    TimeOfDay? dinnerTime,
  }) {
    return ReminderSettings(
      breathingEnabled: breathingEnabled ?? this.breathingEnabled,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      moveEnabled: moveEnabled ?? this.moveEnabled,
      screenTimeEnabled: screenTimeEnabled ?? this.screenTimeEnabled,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
    );
  }
}

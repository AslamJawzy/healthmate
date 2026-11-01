import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';

/// REPOSITORY: saves reminder settings with shared_preferences.
/// Times are stored as text, e.g. "07:00".
class ReminderRepository {
  static const _kBreathing = 'rem_breathing';
  static const _kWater = 'rem_water';
  static const _kMove = 'rem_move';
  static const _kScreen = 'rem_screen';
  static const _kWake = 'rem_wake';
  static const _kSleep = 'rem_sleep';
  static const _kBreakfast = 'rem_breakfast';
  static const _kLunch = 'rem_lunch';
  static const _kDinner = 'rem_dinner';

  Future<ReminderSettings> load() async {
    final p = await SharedPreferences.getInstance();
    const d = ReminderSettings();
    return ReminderSettings(
      breathingEnabled: p.getBool(_kBreathing) ?? d.breathingEnabled,
      waterEnabled: p.getBool(_kWater) ?? d.waterEnabled,
      moveEnabled: p.getBool(_kMove) ?? d.moveEnabled,
      screenTimeEnabled: p.getBool(_kScreen) ?? d.screenTimeEnabled,
      wakeTime: _read(p, _kWake) ?? d.wakeTime,
      sleepTime: _read(p, _kSleep) ?? d.sleepTime,
      breakfastTime: _read(p, _kBreakfast) ?? d.breakfastTime,
      lunchTime: _read(p, _kLunch) ?? d.lunchTime,
      dinnerTime: _read(p, _kDinner) ?? d.dinnerTime,
    );
  }

  Future<void> save(ReminderSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBreathing, s.breathingEnabled);
    await p.setBool(_kWater, s.waterEnabled);
    await p.setBool(_kMove, s.moveEnabled);
    await p.setBool(_kScreen, s.screenTimeEnabled);
    await p.setString(_kWake, _write(s.wakeTime));
    await p.setString(_kSleep, _write(s.sleepTime));
    await p.setString(_kBreakfast, _write(s.breakfastTime));
    await p.setString(_kLunch, _write(s.lunchTime));
    await p.setString(_kDinner, _write(s.dinnerTime));
  }

  TimeOfDay? _read(SharedPreferences p, String key) {
    final text = p.getString(key);
    if (text == null) return null;
    final parts = text.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _write(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

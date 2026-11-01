import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

/// REPOSITORY: saves small key/value settings with shared_preferences.
/// (Health records go in SQLite; simple preferences do not need a table.)
class SettingsRepository {
  static const _kStepsGoal = 'goal_steps';
  static const _kCaloriesGoal = 'goal_calories';
  static const _kWaterGoal = 'goal_water';
  static const _kThemeMode = 'theme_mode';

  Future<UserSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = UserSettings();
    return UserSettings(
      stepsGoal: prefs.getInt(_kStepsGoal) ?? defaults.stepsGoal,
      caloriesGoal: prefs.getInt(_kCaloriesGoal) ?? defaults.caloriesGoal,
      waterGoal: prefs.getInt(_kWaterGoal) ?? defaults.waterGoal,
      themeMode: _themeFromString(prefs.getString(_kThemeMode)),
    );
  }

  Future<void> saveGoals({
    required int steps,
    required int calories,
    required int water,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStepsGoal, steps);
    await prefs.setInt(_kCaloriesGoal, calories);
    await prefs.setInt(_kWaterGoal, water);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name); // "system", "light" or "dark"
  }

  ThemeMode _themeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

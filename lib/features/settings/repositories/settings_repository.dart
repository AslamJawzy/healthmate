import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

/// REPOSITORY: saves small key/value settings with shared_preferences.
/// (Health records go in SQLite; simple preferences do not need a table.)
class SettingsRepository {
  static const _kStepsGoal = 'goal_steps';
  static const _kCaloriesGoal = 'goal_calories';
  static const _kWaterGoal = 'goal_water';
  static const _kFoodGoal = 'goal_food';
  static const _kThemeMode = 'theme_mode';
  static const _kHeight = 'profile_height_cm';
  static const _kWeight = 'profile_weight_kg';
  static const _kGender = 'profile_gender';
  static const _kAutoTrack = 'auto_track_steps';

  Future<UserSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = UserSettings();
    return UserSettings(
      stepsGoal: prefs.getInt(_kStepsGoal) ?? defaults.stepsGoal,
      caloriesGoal: prefs.getInt(_kCaloriesGoal) ?? defaults.caloriesGoal,
      waterGoal: prefs.getInt(_kWaterGoal) ?? defaults.waterGoal,
      foodGoal: prefs.getInt(_kFoodGoal) ?? defaults.foodGoal,
      themeMode: _themeFromString(prefs.getString(_kThemeMode)),
      heightCm: prefs.getInt(_kHeight) ?? defaults.heightCm,
      weightKg: prefs.getDouble(_kWeight) ?? defaults.weightKg,
      gender: _genderFromString(prefs.getString(_kGender)) ?? defaults.gender,
      autoTrackSteps: prefs.getBool(_kAutoTrack) ?? defaults.autoTrackSteps,
    );
  }

  Future<void> saveGoals({
    required int steps,
    required int calories,
    required int water,
    required int food,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStepsGoal, steps);
    await prefs.setInt(_kCaloriesGoal, calories);
    await prefs.setInt(_kWaterGoal, water);
    await prefs.setInt(_kFoodGoal, food);
  }

  Future<void> saveProfile({
    required int heightCm,
    required double weightKg,
    required Gender gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHeight, heightCm);
    await prefs.setDouble(_kWeight, weightKg);
    await prefs.setString(_kGender, gender.name);
  }

  Future<void> saveAutoTrack(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoTrack, enabled);
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

  Gender? _genderFromString(String? value) {
    for (final g in Gender.values) {
      if (g.name == value) return g;
    }
    return null;
  }
}

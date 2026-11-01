import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../repositories/settings_repository.dart';

/// VIEWMODEL: holds the current settings and saves changes.
/// The whole app listens to this for the theme (light / dark),
/// and the step tracker uses the profile to estimate calories.
class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsViewModel(this._repository);

  UserSettings _settings = const UserSettings();
  bool _loaded = false;

  UserSettings get settings => _settings;
  bool get loaded => _loaded;
  int get stepsGoal => _settings.stepsGoal;
  int get caloriesGoal => _settings.caloriesGoal;
  int get waterGoal => _settings.waterGoal;
  int get foodGoal => _settings.foodGoal;
  ThemeMode get themeMode => _settings.themeMode;
  int get heightCm => _settings.heightCm;
  double get weightKg => _settings.weightKg;
  Gender get gender => _settings.gender;
  bool get autoTrackSteps => _settings.autoTrackSteps;

  Future<void> load() async {
    try {
      _settings = await _repository.load();
    } catch (e) {
      debugPrint('Settings load error: $e'); // keep the defaults
    }
    _loaded = true;
    notifyListeners();
  }

  Future<String?> updateGoals({
    required int steps,
    required int calories,
    required int water,
    required int food,
  }) async {
    try {
      await _repository.saveGoals(steps: steps, calories: calories, water: water, food: food);
      _settings = _settings.copyWith(
        stepsGoal: steps,
        caloriesGoal: calories,
        waterGoal: water,
        foodGoal: food,
      );
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Save goals error: $e');
      return 'Could not save your goals.';
    }
  }

  Future<String?> updateProfile({
    required int heightCm,
    required double weightKg,
    required Gender gender,
  }) async {
    try {
      await _repository.saveProfile(heightCm: heightCm, weightKg: weightKg, gender: gender);
      _settings = _settings.copyWith(heightCm: heightCm, weightKg: weightKg, gender: gender);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Save profile error: $e');
      return 'Could not save your profile.';
    }
  }

  Future<void> setAutoTrackSteps(bool enabled) async {
    _settings = _settings.copyWith(autoTrackSteps: enabled);
    notifyListeners();
    try {
      await _repository.saveAutoTrack(enabled);
    } catch (e) {
      debugPrint('Save auto track error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners(); // update the UI straight away
    try {
      await _repository.saveThemeMode(mode);
    } catch (e) {
      debugPrint('Save theme error: $e');
    }
  }
}

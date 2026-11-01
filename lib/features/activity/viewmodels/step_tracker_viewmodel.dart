import 'package:flutter/material.dart';

import '../../../core/utils/activity_calculator.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../health_records/viewmodels/health_record_viewmodel.dart';
import '../../settings/viewmodels/settings_viewmodel.dart';
import '../models/step_counter_state.dart';
import '../services/step_counter_service.dart';

enum StepTrackerStatus { off, starting, tracking, permissionDenied, noSensor }

/// VIEWMODEL: reads the step sensor, works out today's steps and estimated
/// calories, and saves them into today's health record.
class StepTrackerViewModel extends ChangeNotifier {
  final StepCounterService _service;
  final HealthRecordViewModel _records;
  final SettingsViewModel _settings;

  StepTrackerViewModel(this._service, this._records, this._settings);

  StepTrackerStatus _status = StepTrackerStatus.off;
  StepCounterState? _state;
  DateTime? _lastSaved;
  int _lastSavedSteps = -1;

  StepTrackerStatus get status => _status;
  int get todaySteps => _state?.todaySteps ?? 0;
  bool get isTracking => _status == StepTrackerStatus.tracking;

  int get estimatedCalories => ActivityCalculator.caloriesFromSteps(
        steps: todaySteps,
        heightCm: _settings.heightCm,
        weightKg: _settings.weightKg,
        gender: _settings.gender,
      );

  String get statusText {
    switch (_status) {
      case StepTrackerStatus.off:
        return 'Automatic step tracking is off';
      case StepTrackerStatus.starting:
        return 'Starting step sensor...';
      case StepTrackerStatus.tracking:
        return 'Steps are counted automatically';
      case StepTrackerStatus.permissionDenied:
        return 'Allow "Physical activity" permission to count steps';
      case StepTrackerStatus.noSensor:
        return 'This device has no step sensor. Enter steps manually.';
    }
  }

  /// Called on app start, when the app comes back to the front,
  /// and when the user turns auto tracking on.
  Future<void> start() async {
    if (!_settings.autoTrackSteps) {
      stop();
      return;
    }
    if (_status == StepTrackerStatus.tracking) return;
    _status = StepTrackerStatus.starting;
    notifyListeners();

    try {
      final granted = await _service.requestPermission();
      if (!granted) {
        _status = StepTrackerStatus.permissionDenied;
        notifyListeners();
        return;
      }
      _state ??= await _service.loadState();
      _service.start(onReading: _onReading, onError: _onError);
      _status = StepTrackerStatus.tracking;
    } catch (e) {
      debugPrint('Step tracker start error: $e');
      _status = StepTrackerStatus.noSensor;
    }
    notifyListeners();
  }

  void stop() {
    _service.stop();
    _status = StepTrackerStatus.off;
    notifyListeners();
  }

  /// Save straight away (used when the app goes to the background).
  Future<void> flush() => _saveToRecord(force: true);

  void _onError(Object error) {
    debugPrint('Step sensor error: $error');
    _service.stop();
    _status = StepTrackerStatus.noSensor;
    notifyListeners();
  }

  Future<void> _onReading(int sensor) async {
    final today = AppDateUtils.toDbString(AppDateUtils.today());
    _state = StepCounterState.update(_state, sensor, today);
    notifyListeners();
    await _service.saveState(_state!);
    await _saveToRecord();
  }

  /// Writes steps and estimated calories into today's record.
  /// To avoid writing to the database on every single step, it saves at
  /// most every 30 seconds unless [force] is true.
  Future<void> _saveToRecord({bool force = false}) async {
    if (_state == null) return;
    final steps = todaySteps;
    if (steps == _lastSavedSteps) return;
    final now = DateTime.now();
    if (!force && _lastSaved != null && now.difference(_lastSaved!).inSeconds < 30) return;

    _lastSaved = now;
    _lastSavedSteps = steps;
    await _records.applyAutoActivity(
      date: AppDateUtils.today(),
      steps: steps,
      calories: estimatedCalories,
    );
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}

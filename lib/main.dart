import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'features/food/repositories/food_repository.dart';
import 'features/food/viewmodels/food_viewmodel.dart';
import 'features/health_records/repositories/health_record_repository.dart';
import 'features/health_records/viewmodels/health_record_viewmodel.dart';
import 'features/reminders/repositories/reminder_repository.dart';
import 'features/reminders/services/notification_service.dart';
import 'features/reminders/viewmodels/reminder_viewmodel.dart';
import 'features/settings/repositories/settings_repository.dart';
import 'features/settings/viewmodels/settings_viewmodel.dart';
import 'features/sleep/repositories/sleep_repository.dart';
import 'features/sleep/viewmodels/sleep_viewmodel.dart';

/// Entry point of the app.
/// MultiProvider makes the ViewModels available to every screen below it.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start setting up notifications, but do not wait for it:
  // the first screen should appear straight away.
  NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthRecordViewModel(HealthRecordRepository())..loadRecords(),
        ),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(SettingsRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => FoodViewModel(FoodRepository())..loadEntries(),
        ),
        ChangeNotifierProvider(
          create: (_) => SleepViewModel(SleepRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderViewModel(ReminderRepository(), NotificationService.instance)..load(),
        ),
      ],
      child: const HealthMateApp(),
    ),
  );
}

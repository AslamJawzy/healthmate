import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'features/health_records/repositories/health_record_repository.dart';
import 'features/health_records/viewmodels/health_record_viewmodel.dart';
import 'features/settings/repositories/settings_repository.dart';
import 'features/settings/viewmodels/settings_viewmodel.dart';

/// Entry point of the app.
/// MultiProvider makes the ViewModels available to every screen below it.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: const HealthMateApp(),
    ),
  );
}

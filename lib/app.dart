import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/settings/viewmodels/settings_viewmodel.dart';

class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the user switches light / dark mode.
    final themeMode = context.select<SettingsViewModel, ThemeMode>((vm) => vm.themeMode);

    return MaterialApp(
      title: 'HealthMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}

import 'package:flutter/material.dart';

import '../dashboard/views/dashboard_screen.dart';
import '../health_records/views/add_edit_record_screen.dart';
import '../health_records/views/records_list_screen.dart';
import '../settings/views/settings_screen.dart';

/// The main screen with the bottom navigation bar.
/// IndexedStack keeps each tab alive, so scroll positions are not lost.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    RecordsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // The Add Record button only makes sense on Dashboard and Records.
    final showFab = _currentIndex <= 1;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditRecordScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

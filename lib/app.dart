import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/features/doses/application/dose_providers.dart';
import 'package:medication_tracker/features/doses/presentation/schedule_screen.dart';
import 'package:medication_tracker/features/medications/presentation/medications_list_screen.dart';

class MedicationTrackerApp extends StatelessWidget {
  const MedicationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const _StartupGate(),
    );
  }
}

/// Waits for appStartupProvider (missed-sweep + 14-day top-up) to finish
/// once, then shows the real tabbed UI. Kept separate from the tabs
/// themselves so neither tab has to know or care about startup timing.
class _StartupGate extends ConsumerWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    return startup.when(
      data: (_) => const _RootTabs(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Startup failed: $error')),
      ),
    );
  }
}

class _RootTabs extends StatefulWidget {
  const _RootTabs();

  @override
  State<_RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<_RootTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ScheduleScreen(),
      const MedicationsListScreen(),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.medication), label: 'Medications'),
        ],
      ),
    );
  }
}

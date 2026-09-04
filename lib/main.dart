import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'services/medication_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final medicationRepository = MedicationRepository();

  runApp(PillReminderApp(repository: medicationRepository));
}

class PillReminderApp extends StatelessWidget {
  final MedicationRepository repository;

  const PillReminderApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    const baseBrandColor = Color.fromARGB(255, 31, 52, 171);

    // Light Color Scheme
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: baseBrandColor,
      brightness: Brightness.light,
    );

    // Dark Color Scheme
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: baseBrandColor,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Pills Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: lightColorScheme.surfaceContainer,
          foregroundColor: lightColorScheme.onSurface,
          titleTextStyle: TextStyle(
            color: lightColorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: darkColorScheme.surfaceContainer,
          foregroundColor: darkColorScheme.onSurface,
          titleTextStyle: TextStyle(
            color: darkColorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: MainNavigationScreen(repository: repository),
    );
  }
}
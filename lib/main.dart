import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/medication_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MedicationRepository(),
      child: const MedApp(),
    ),
  );
}

class MedApp extends StatelessWidget {
  const MedApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.pink;
    final lightScheme = ColorScheme.fromSeed(seedColor: seedColor);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Meds',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: lightScheme.primary,
          foregroundColor: lightScheme.onPrimary,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: darkScheme.primary,
          foregroundColor: darkScheme.onPrimary,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/core/notifications/notification_service.dart';
import 'package:medication_tracker/features/doses/application/dose_providers.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();

  // Build the container by hand (rather than letting ProviderScope create
  // it) so we can wire the OS notification callback to it before any
  // widget builds. This is the one deliberate exception to "widgets never
  // touch repositories directly" — it's not a widget, it's the composition
  // root, and the OS callback has no BuildContext to work with anyway.
  final container = ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );

  notificationService.onDoseActioned = (String doseId, DoseStatus status) {
    container.read(doseRepositoryProvider).updateStatus(doseId, status);
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MedicationTrackerApp(),
    ),
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/core/notifications/notification_service.dart';
import 'package:medication_tracker/features/doses/data/dose_repository.dart';
import 'package:medication_tracker/features/doses/data/dose_repository_drift.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';
import 'package:medication_tracker/features/medications/application/medication_providers.dart';

import 'dose_scheduling_service.dart';

/// Created once in main.dart (see notes there) and overridden into the
/// ProviderScope, so both the notification OS-callback and the provider
/// tree share the exact same instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main.dart after '
    'NotificationService().init() has completed.',
  );
});

final doseRepositoryProvider = Provider<DoseRepository>((ref) {
  return DoseRepositoryDrift(ref.watch(appDatabaseProvider));
});

final doseSchedulingServiceProvider = Provider<DoseSchedulingService>((ref) {
  return DoseSchedulingService(
    ref.watch(medicationRepositoryProvider),
    ref.watch(doseRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

/// Runs the sweep + horizon top-up exactly once per app launch. The root
/// widget watches this (see app.dart) and shows a brief loading state
/// until it resolves — after that, everything else is normal reactive
/// streams.
final appStartupProvider = FutureProvider<void>((ref) {
  return ref.watch(doseSchedulingServiceProvider).ensureUpToDate();
});

final dosesForDayProvider =
    StreamProvider.family<List<Dose>, DateTime>((ref, day) {
  return ref.watch(doseRepositoryProvider).watchDosesForDay(day);
});

final doseHistoryProvider =
    StreamProvider.family<List<Dose>, String>((ref, medicationId) {
  return ref.watch(doseRepositoryProvider).watchHistory(medicationId);
});

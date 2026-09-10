import 'package:medication_tracker/core/notifications/notification_service.dart';
import 'package:medication_tracker/features/doses/data/dose_repository.dart';
import 'package:medication_tracker/features/medications/data/medication_repository.dart';
import 'package:medication_tracker/features/medications/domain/medication.dart';

const int doseGenerationHorizonDays = 14;

/// Owns the two pieces of logic that don't naturally belong to either
/// repository on its own: keeping the 14-day dose horizon topped up, and
/// sweeping stale pending doses to `missed`.
///
/// Both medication CRUD and app startup call into this via a single
/// entry point, `ensureUpToDate()`, so there's one place this behaviour
/// lives rather than it being duplicated per call site.
class DoseSchedulingService {
  final MedicationRepository _medicationRepository;
  final DoseRepository _doseRepository;
  final NotificationService _notificationService;

  DoseSchedulingService(
    this._medicationRepository,
    this._doseRepository,
    this._notificationService,
  );

  /// Call this:
  ///  - once at app startup (see app_startup_provider in dose_providers.dart)
  ///  - after creating or editing a medication
  ///
  /// It is intentionally idempotent and safe to call as often as you like.
  Future<void> ensureUpToDate() async {
    await _sweepStaleDosesToMissed();
    await _topUpHorizonForAllActiveMedications();
  }

  /// Implements the "missed" rule: a `pending` dose whose scheduled date
  /// is before today becomes `missed` the moment the user does *anything*
  /// in the app on a later day. There's no background timer — this is
  /// purely evaluated here, at the one call site above, whenever the app
  /// is actually open. That keeps the whole feature local-only and simple,
  /// at the cost of a dose not flipping to `missed` in the UI until the
  /// user next opens the app on a subsequent day (which matches the rule
  /// as specified, not a bug).
  Future<void> _sweepStaleDosesToMissed() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final stalePending = await _doseRepository.getPendingBefore(startOfToday);
    if (stalePending.isEmpty) return;

    await _doseRepository.markAsMissed(stalePending.map((d) => d.id).toList());

    // These doses will never fire a "take your dose" reminder now that
    // they're in the past, but cancel any lingering scheduled notification
    // defensively in case one wasn't cleaned up earlier.
    for (final dose in stalePending) {
      await _notificationService.cancelForDose(dose.id);
    }
  }

  Future<void> _topUpHorizonForAllActiveMedications() async {
    final medications =
        await _medicationRepository.watchAll(activeOnly: true).first;

    final from = DateTime.now();
    final to = from.add(const Duration(days: doseGenerationHorizonDays));

    for (final medication in medications) {
      await _doseRepository.generateDosesFor(medication, from, to);
    }

    // Re-sync notifications for the newly-topped-up window. Cheap enough
    // to just re-schedule everything pending in range; NotificationService
    // dedupes by dose id under the hood.
    final upcoming = await _doseRepository.getPendingBefore(to);
    for (final dose in upcoming.where((d) => d.scheduledFor.isAfter(from))) {
      Medication? medication;
      for (final m in medications) {
        if (m.id == dose.medicationId) {
          medication = m;
          break;
        }
      }
      if (medication != null) {
        await _notificationService.scheduleDoseNotification(
          dose: dose,
          medicationName: medication.name,
          dosage: medication.dosage,
        );
      }
    }
  }
}

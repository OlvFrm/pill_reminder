import 'package:medication_tracker/features/doses/domain/dose.dart';
import 'package:medication_tracker/features/medications/domain/medication.dart';

abstract class DoseRepository {
  /// All doses whose scheduledFor date falls on [day] (any time on that
  /// calendar date), for the Schedule tab.
  Stream<List<Dose>> watchDosesForDay(DateTime day);

  /// All doses for one medication over the last [days] days, for the
  /// Medications tab's history view.
  Stream<List<Dose>> watchHistory(String medicationId, {int days = 60});

  /// Every dose that is still `pending` and scheduled before [before].
  /// Used by DoseSchedulingService to find candidates for the missed-sweep.
  Future<List<Dose>> getPendingBefore(DateTime before);

  Future<void> updateStatus(String doseId, DoseStatus status);

  /// User-triggered add of a single one-off dose (isManual = true), not
  /// tied to a medication's regular schedule.
  Future<void> addManualDose(Dose dose);

  /// Deletes a dose entirely (distinct from marking it skipped — this
  /// removes the row, e.g. for a dose added by mistake).
  Future<void> deleteDose(String doseId);

  /// Idempotent: only inserts doses that don't already exist for
  /// [medication] in [from, to]. Safe to call repeatedly.
  Future<void> generateDosesFor(
    Medication medication,
    DateTime from,
    DateTime to,
  );

  /// Bulk status flip used by the missed-sweep.
  Future<void> markAsMissed(List<String> doseIds);
}

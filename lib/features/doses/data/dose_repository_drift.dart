import 'package:drift/drift.dart';
import 'package:medication_tracker/core/database/app_database.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';
import 'package:medication_tracker/features/medications/domain/medication.dart';

import 'dose_repository.dart';

class DoseRepositoryDrift implements DoseRepository {
  final AppDatabase _db;
  DoseRepositoryDrift(this._db);

  @override
  Stream<List<Dose>> watchDosesForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = _db.select(_db.doses)
      ..where((tbl) =>
          tbl.scheduledFor.isBiggerOrEqualValue(startOfDay) &
          tbl.scheduledFor.isSmallerThanValue(endOfDay))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledFor)]);
    return query.watch().map((rows) => rows.map(_rowToDomain).toList());
  }

  @override
  Stream<List<Dose>> watchHistory(String medicationId, {int days = 60}) {
    final since = DateTime.now().subtract(Duration(days: days));
    final query = _db.select(_db.doses)
      ..where((tbl) =>
          tbl.medicationId.equals(medicationId) &
          tbl.scheduledFor.isBiggerOrEqualValue(since))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.scheduledFor)]);
    return query.watch().map((rows) => rows.map(_rowToDomain).toList());
  }

  @override
  Future<List<Dose>> getPendingBefore(DateTime before) async {
    final rows = await (_db.select(_db.doses)
          ..where((tbl) =>
              tbl.status.equals('pending') &
              tbl.scheduledFor.isSmallerThanValue(before)))
        .get();
    return rows.map(_rowToDomain).toList();
  }

  @override
  Future<void> updateStatus(String doseId, DoseStatus status) {
    return (_db.update(_db.doses)..where((tbl) => tbl.id.equals(doseId)))
        .write(DosesCompanion(
      status: Value(status.name),
      actionedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> addManualDose(Dose dose) {
    return _db.into(_db.doses).insert(_domainToCompanion(dose));
  }

  @override
  Future<void> deleteDose(String doseId) {
    return (_db.delete(_db.doses)..where((tbl) => tbl.id.equals(doseId))).go();
  }

  @override
  Future<void> generateDosesFor(
    Medication medication,
    DateTime from,
    DateTime to,
  ) async {
    // Find what's already generated in range so this stays idempotent —
    // safe to call every app launch without creating duplicates.
    final existing = await (_db.select(_db.doses)
          ..where((tbl) =>
              tbl.medicationId.equals(medication.id) &
              tbl.scheduledFor.isBiggerOrEqualValue(from) &
              tbl.scheduledFor.isSmallerThanValue(to)))
        .get();
    final existingTimestamps =
        existing.map((r) => r.scheduledFor.millisecondsSinceEpoch).toSet();

    final toInsert = <DosesCompanion>[];
    for (var day = from;
        day.isBefore(to);
        day = day.add(const Duration(days: 1))) {
      for (final t in medication.scheduledTimes) {
        final scheduledFor =
            DateTime(day.year, day.month, day.day, t.hour, t.minute);
        if (existingTimestamps.contains(scheduledFor.millisecondsSinceEpoch)) {
          continue; // already generated
        }
        toInsert.add(DosesCompanion.insert(
          id: '${medication.id}_${scheduledFor.millisecondsSinceEpoch}',
          medicationId: medication.id,
          scheduledFor: scheduledFor,
        ));
      }
    }

    if (toInsert.isEmpty) return;
    await _db.batch((batch) => batch.insertAll(_db.doses, toInsert));
  }

  @override
  Future<void> markAsMissed(List<String> doseIds) async {
    if (doseIds.isEmpty) return;
    await (_db.update(_db.doses)..where((tbl) => tbl.id.isIn(doseIds)))
        .write(const DosesCompanion(status: Value('missed')));
  }

  // --- mapping helpers -------------------------------------------------

  Dose _rowToDomain(DoseRow row) {
    return Dose(
      id: row.id,
      medicationId: row.medicationId,
      scheduledFor: row.scheduledFor,
      status: DoseStatus.values.byName(row.status),
      actionedAt: row.actionedAt,
      isManual: row.isManual,
    );
  }

  DosesCompanion _domainToCompanion(Dose d) {
    return DosesCompanion.insert(
      id: d.id,
      medicationId: d.medicationId,
      scheduledFor: d.scheduledFor,
      status: Value(d.status.name),
      isManual: Value(d.isManual),
    );
  }
}

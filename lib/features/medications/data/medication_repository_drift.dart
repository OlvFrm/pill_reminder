import 'package:drift/drift.dart';
import 'package:medication_tracker/core/database/app_database.dart';
import 'package:medication_tracker/core/domain/scheduled_time.dart';
import 'package:medication_tracker/features/medications/domain/medication.dart';

import 'medication_repository.dart';

class MedicationRepositoryDrift implements MedicationRepository {
  final AppDatabase _db;
  MedicationRepositoryDrift(this._db);

  @override
  Stream<List<Medication>> watchAll({bool activeOnly = false}) {
    final query = _db.select(_db.medications);
    if (activeOnly) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    // .watch() gives a Stream that auto-emits whenever the underlying rows
    // change — this is what lets the UI update reactively with no manual
    // "refresh" calls anywhere.
    return query.watch().map(
          (rows) => rows.map(_rowToDomain).toList(),
        );
  }

  @override
  Future<Medication?> getById(String id) async {
    final row = await (_db.select(_db.medications)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToDomain(row);
  }

  @override
  Future<void> create(Medication medication) {
    return _db.into(_db.medications).insert(_domainToCompanion(medication));
  }

  @override
  Future<void> update(Medication medication) {
    return _db.update(_db.medications).replace(
          _domainToCompanion(medication),
        );
  }

  @override
  Future<void> delete(String id) {
    // Doses.medicationId has onDelete: KeyAction.cascade (see tables.dart),
    // so this also removes all of this medication's doses/history.
    return (_db.delete(_db.medications)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // --- mapping helpers: Drift row <-> domain model -------------------

  Medication _rowToDomain(MedicationRow row) {
    return Medication(
      id: row.id,
      name: row.name,
      dosage: row.dosage,
      isActive: row.isActive,
      scheduledTimes: row.scheduledTimesCsv
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) {
        final parts = s.split(':');
        return ScheduledTime(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList(),
    );
  }

  MedicationsCompanion _domainToCompanion(Medication m) {
    final csv = m.scheduledTimes.map((t) => '${t.hour}:${t.minute}').join(',');
    return MedicationsCompanion(
      id: Value(m.id),
      name: Value(m.name),
      dosage: Value(m.dosage),
      isActive: Value(m.isActive),
      scheduledTimesCsv: Value(csv),
    );
  }
}

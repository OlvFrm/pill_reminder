import 'package:drift/drift.dart';

/// One row per medication the user is tracking.
///
/// `@DataClassName('MedicationRow')` is required here: Drift's default
/// naming would generate a class simply called `Medication` (singular of
/// the table class name), which collides with our own domain model of the
/// same name. Explicitly naming it MedicationRow keeps "the Drift-generated
/// row" and "the domain model" visibly distinct at every call site.
///
/// `scheduledTimesCsv` stores something like "08:00,20:00" — simple, and
/// avoids needing a separate join table for what's really just a small,
/// rarely-queried list. If you ever need to query "medications scheduled
/// at 8am" directly in SQL, split this into its own table instead.
@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get scheduledTimesCsv => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per individual dose occurrence — whether auto-generated from a
/// medication's schedule or added manually by the user.
///
/// Same reasoning as Medications above: Drift's default generated class
/// name would be `Dose`, colliding with our domain model — hence DoseRow.
@DataClassName('DoseRow')
class Doses extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledFor => dateTime()();
  // Stored as text (enum name) rather than an int index, so the DB stays
  // human-readable and reordering the Dart enum later can't silently
  // corrupt existing data.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get actionedAt => dateTime().nullable()();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

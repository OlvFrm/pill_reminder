import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/core/database/app_database.dart';
import 'package:medication_tracker/features/medications/data/medication_repository.dart';
import 'package:medication_tracker/features/medications/data/medication_repository_drift.dart';
import 'package:medication_tracker/features/medications/domain/medication.dart';

/// A single shared AppDatabase instance for the whole app. Every
/// repository provider reads this one, so there's one open sqlite
/// connection, not one per repository.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryDrift(ref.watch(appDatabaseProvider));
});

final allMedicationsProvider = StreamProvider<List<Medication>>((ref) {
  return ref.watch(medicationRepositoryProvider).watchAll();
});

final medicationByIdProvider =
    FutureProvider.family<Medication?, String>((ref, id) {
  return ref.watch(medicationRepositoryProvider).getById(id);
});

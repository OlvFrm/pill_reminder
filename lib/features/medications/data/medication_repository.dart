import 'package:medication_tracker/features/medications/domain/medication.dart';

/// Everything above this interface (providers, widgets, business logic)
/// depends only on this abstraction — never on Drift directly. That's what
/// lets you unit-test e.g. DoseSchedulingService with a fake in-memory
/// implementation of this class, no sqlite involved.
abstract class MedicationRepository {
  Stream<List<Medication>> watchAll({bool activeOnly = false});
  Future<Medication?> getById(String id);
  Future<void> create(Medication medication);
  Future<void> update(Medication medication);
  Future<void> delete(String id);
}

import 'package:flutter/foundation.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../models/medication.dart';

class MedicationRepository extends ChangeNotifier {
  final List<Medication> _medications = [];

  List<Medication> get medications => List.unmodifiable(_medications);

  void addMedication(Medication medication) {
    _medications.add(medication);
    notifyListeners();
  }

  void updateMedication(Medication updatedMedication) {
    final index = _medications.indexWhere((m) => m.id == updatedMedication.id);
    if (index != -1) {
      _medications[index] = updatedMedication;
      notifyListeners();
    }
  }

  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void logPillTaken(
    String medicationId, {
    DateTime? timestamp,
    LogSource source = LogSource.manualEntry,
  }) {
    final index = _medications.indexWhere((m) => m.id == medicationId);
    if (index != -1) {
      final currentMed = _medications[index];
      final selectedTime = timestamp ?? DateTime.now();

      final newEntry = HistoryEntry(
        medicationId: medicationId,
        timestamp: selectedTime,
        status: LogStatus.taken,
        source: source,
      );

      final updatedHistory = List<HistoryEntry>.from(currentMed.history)..add(newEntry);
      _medications[index] = currentMed.copyWith(history: updatedHistory);
      notifyListeners();
    }
  }

  void logPillSkipped(
    String medicationId, {
    DateTime? timestamp,
    LogSource source = LogSource.manualEntry,
  }) {
    final index = _medications.indexWhere((m) => m.id == medicationId);
    if (index != -1) {
      final currentMed = _medications[index];

      final newEntry = HistoryEntry(
        medicationId: medicationId,
        timestamp: timestamp ?? DateTime.now(),
        status: LogStatus.skipped,
        source: source,
      );

      final updatedHistory = List<HistoryEntry>.from(currentMed.history)..add(newEntry);
      _medications[index] = currentMed.copyWith(history: updatedHistory);
      notifyListeners();
    }
  }
}
import 'package:flutter/foundation.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../models/medication.dart';
import '../models/reminder_rule.dart';

class MedicationRepository extends ChangeNotifier {
  final List<Medication> _medications = [];

  MedicationRepository() {
    if (kDebugMode) {
      _seedDebugData();
    }
  }

  List<Medication> get medications => List.unmodifiable(_medications);

  void addMedication(Medication medication) {
    _medications.add(medication);
    notifyListeners();
  }

  void removeMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void updateMedication(Medication updated) {
    final index = _medications.indexWhere((m) => m.id == updated.id);
    if (index == -1) return;
    _medications[index] = updated;
    notifyListeners();
  }

  Medication? getById(String id) {
    for (final m in _medications) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _seedDebugData() {
    final now = DateTime.now();

    _medications.addAll([
      Medication(
        id: 'debug-1',
        name: 'Ibuprofen',
        colorValue: 0xFFE57373, // red
        reminders: [
          ReminderRule(
            id: 'r1',
            hour: 8,
            minute: 0,
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          ),
          ReminderRule(
            id: 'r2',
            hour: 20,
            minute: 0,
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          ),
        ],
        history: [
          HistoryEntry(
            medicationId: 'debug-1',
            timestamp: now.subtract(const Duration(hours: 14)),
            status: LogStatus.taken,
            source: LogSource.fromReminder,
          ),
          HistoryEntry(
            medicationId: 'debug-1',
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
            status: LogStatus.missed,
            source: LogSource.fromReminder,
          ),
        ],
      ),
      Medication(
        id: 'debug-2',
        name: 'Vitamin D',
        colorValue: 0xFFFFB300, // amber
        reminders: [
          ReminderRule(
            id: 'r3',
            hour: 9,
            minute: 30,
            daysOfWeek: [1, 2, 3, 4, 5],
          ),
        ],
        history: const [],
      ),
      Medication(
        id: 'debug-3',
        name: 'Amoxicillin',
        colorValue: 0xFF64B5F6, // blue
        reminders: [],
        history: [
          HistoryEntry(
            medicationId: 'debug-3',
            timestamp: now.subtract(const Duration(hours: 3)),
            status: LogStatus.taken,
            source: LogSource.manualEntry,
          ),
        ],
      ),
    ]);
  }
}
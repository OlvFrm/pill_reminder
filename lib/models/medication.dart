import 'package:flutter/foundation.dart';
import 'enum_types.dart'; // add
import 'history_entry.dart';
import 'reminder_rule.dart';


@immutable
class Medication {
  final String id;
  final String name;
  final int colorValue;
  final List<ReminderRule> reminders;
  final List<HistoryEntry> history;

  Medication({
    required this.id,
    required this.name,
    required this.colorValue,
    required List<ReminderRule> reminders,
    required List<HistoryEntry> history,
  })  : reminders = List.unmodifiable(reminders),
        history = List.unmodifiable(history);

  /// Latest entry with status == taken, without copying/sorting the list.
  HistoryEntry? get lastTakenEntry {
    HistoryEntry? latest;
    for (final e in history) {
      if (e.status != LogStatus.taken) continue;
      if (latest == null || e.timestamp.isAfter(latest.timestamp)) latest = e;
    }
    return latest;
  }

  Medication copyWith({
    String? id,
    String? name,
    int? colorValue,
    List<ReminderRule>? reminders,
    List<HistoryEntry>? history,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      reminders: reminders ?? this.reminders,
      history: history ?? this.history,
    );
  }
}
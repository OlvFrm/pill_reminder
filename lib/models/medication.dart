import 'package:flutter/foundation.dart';
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

  /// Efficient lookup without creating temporary sorted array copies
  HistoryEntry? get lastTakenEntry {
    if (history.isEmpty) return null;
    return history.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
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
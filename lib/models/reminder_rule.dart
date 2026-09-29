import 'package:flutter/material.dart';

const _dayAbbrev = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

/// "Every day", "Weekdays", "Weekends", or e.g. "Mo, We, Fr".
String summarizeDays(Iterable<int> days) {
  final set = days.toSet();
  if (set.length == 7) return 'Every day';
  if (set.length == 5 && set.containsAll({1, 2, 3, 4, 5})) return 'Weekdays';
  if (set.length == 2 && set.containsAll({6, 7})) return 'Weekends';
  if (set.isEmpty) return 'No days selected';
  final sorted = set.toList()..sort();
  return sorted.map((d) => _dayAbbrev[d - 1]).join(', ');
}

@immutable
class ReminderRule {
  final String id;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final String dosage; // e.g. "1 pill", "500mg"

  ReminderRule({
    required this.id,
    required this.hour,
    required this.minute,
    required List<int> daysOfWeek,
    required this.dosage,
  }) : daysOfWeek = List.unmodifiable(daysOfWeek);

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get daysSummary => summarizeDays(daysOfWeek);

  String formatTime(BuildContext context) {
    return time.format(context);
  }
}
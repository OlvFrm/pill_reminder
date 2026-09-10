import 'package:flutter/material.dart';

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

  String formatTime(BuildContext context) {
    return time.format(context);
  }
}
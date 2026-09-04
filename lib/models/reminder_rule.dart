import 'package:flutter/material.dart';

@immutable
class ReminderRule {
  final String id;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday

  const ReminderRule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String formatTime(BuildContext context) {
    return time.format(context);
  }
}
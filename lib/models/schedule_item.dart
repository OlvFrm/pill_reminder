import 'package:flutter/material.dart';
import 'medication.dart';
import 'history_entry.dart';

enum ScheduleType { scheduled, manualLog }

class ScheduleItem {
  final Medication medication;
  final TimeOfDay time;
  final ScheduleType type;
  final HistoryEntry? historyEntry;

  const ScheduleItem({
    required this.medication,
    required this.time,
    required this.type,
    this.historyEntry,
  });

  int compareTo(ScheduleItem other) {
    final aMinutes = time.hour * 60 + time.minute;
    final bMinutes = other.time.hour * 60 + other.time.minute;
    return aMinutes.compareTo(bMinutes);
  }
}
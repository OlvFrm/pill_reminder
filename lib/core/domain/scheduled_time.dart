/// A plain (hour, minute) pair.
///
/// We deliberately avoid Flutter's `TimeOfDay` here — the domain layer
/// should not import `package:flutter/material.dart` at all. That keeps
/// domain code runnable under plain `dart test`, with no widget bindings,
/// and keeps the dependency direction one-way: presentation depends on
/// domain, never the reverse.
class ScheduledTime {
  final int hour;   // 0-23
  final int minute; // 0-59

  const ScheduledTime({required this.hour, required this.minute});

  /// Minutes since midnight, handy for sorting.
  int get minutesSinceMidnight => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is ScheduledTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

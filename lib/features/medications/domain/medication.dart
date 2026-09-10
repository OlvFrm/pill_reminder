import 'package:medication_tracker/core/domain/scheduled_time.dart';

/// Pure domain model. No Flutter, no Drift, no JSON — just data + a couple
/// of tiny derived getters. This is what the rest of the app (UI, business
/// logic) actually works with; Drift rows get converted to/from this at the
/// repository boundary and never leak past it.
class Medication {
  final String id;
  final String name;
  final String dosage; // free text, e.g. "500mg", "1 tablet"
  final List<ScheduledTime> scheduledTimes;
  final bool isActive;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduledTimes,
    this.isActive = true,
  });

  Medication copyWith({
    String? name,
    String? dosage,
    List<ScheduledTime>? scheduledTimes,
    bool? isActive,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// `missed` is never set by a background timer. Per the app's rule, a
/// `pending` dose only flips to `missed` when the day has rolled over AND
/// the user has taken some action inside the app on the new day — see
/// DoseSchedulingService.ensureUpToDate().
enum DoseStatus { pending, taken, skipped, missed }

class Dose {
  final String id;
  final String medicationId;
  final DateTime scheduledFor; // exact date + time of this dose
  final DoseStatus status;
  final DateTime? actionedAt; // when the user set taken/skipped
  final bool isManual; // true if the user added this dose by hand,
  // rather than it being auto-generated from a medication's schedule

  const Dose({
    required this.id,
    required this.medicationId,
    required this.scheduledFor,
    this.status = DoseStatus.pending,
    this.actionedAt,
    this.isManual = false,
  });

  Dose copyWith({DoseStatus? status, DateTime? actionedAt}) {
    return Dose(
      id: id,
      medicationId: medicationId,
      scheduledFor: scheduledFor,
      status: status ?? this.status,
      actionedAt: actionedAt ?? this.actionedAt,
      isManual: isManual,
    );
  }

  /// Purely a helper for grouping; NOT how "missed" is decided (see enum
  /// doc comment above) — this just answers "is this dose's time in the
  /// past", which the scheduling service uses as one input to the sweep.
  bool get scheduledTimeHasPassed => scheduledFor.isBefore(DateTime.now());
}

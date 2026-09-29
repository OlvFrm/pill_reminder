import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'enum_types.dart';

const _uuid = Uuid();

@immutable
class HistoryEntry {
  final String id;
  final String medicationId;
  final DateTime timestamp;
  final LogStatus status;
  final LogSource source;
  final String dosage; // e.g. "1 pill", "500mg"

  const HistoryEntry({
    required this.id,
    required this.medicationId,
    required this.timestamp,
    required this.status,
    required this.source,
    required this.dosage,
  });

  /// Use this everywhere a new entry is created; it generates the id.
  factory HistoryEntry.create({
    required String medicationId,
    required DateTime timestamp,
    required LogStatus status,
    required LogSource source,
    required String dosage,
  }) {
    return HistoryEntry(
      id: _uuid.v4(),
      medicationId: medicationId,
      timestamp: timestamp,
      status: status,
      source: source,
      dosage: dosage,
    );
  }

  /// id, medicationId and source are intentionally not editable.
  HistoryEntry copyWith({
    DateTime? timestamp,
    LogStatus? status,
    String? dosage,
  }) {
    return HistoryEntry(
      id: id,
      medicationId: medicationId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      source: source,
      dosage: dosage ?? this.dosage,
    );
  }
}
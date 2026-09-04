import 'package:flutter/foundation.dart';
import 'enum_types.dart';

@immutable
class HistoryEntry {
  final String medicationId;
  final DateTime timestamp;
  final LogStatus status;
  final LogSource source;

  const HistoryEntry({
    required this.medicationId,
    required this.timestamp,
    required this.status,
    required this.source,
  });
}
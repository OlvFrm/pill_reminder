import 'package:flutter/material.dart';
import '../models/enum_types.dart';

extension LogStatusStyle on LogStatus {
  String get label => switch (this) {
        LogStatus.taken => 'Taken',
        LogStatus.skipped => 'Skipped',
        LogStatus.missed => 'Missed',
      };

  Color get color => switch (this) {
        LogStatus.taken => Colors.green,
        LogStatus.skipped => Colors.orange,
        LogStatus.missed => Colors.red,
      };

  IconData get icon => switch (this) {
        LogStatus.taken => Icons.check_circle,
        LogStatus.skipped => Icons.remove_circle,
        LogStatus.missed => Icons.cancel,
      };
}
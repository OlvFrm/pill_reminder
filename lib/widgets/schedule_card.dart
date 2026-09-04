import 'package:flutter/material.dart';
import '../models/enum_types.dart';
import '../screens/home_screen.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final Function(DateTime selectedTimestamp) onTakeWithTime;
  final VoidCallback onSkip;

  const ScheduleCard({
    super.key,
    required this.item,
    required this.onTakeWithTime,
    required this.onSkip,
  });

  Future<void> _handleTakePressed(BuildContext context) async {
    final now = DateTime.now();
    final initialTime = item.type == ScheduleType.scheduled
        ? item.time
        : TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'LOG PILL TAKEN TIME',
    );

    if (pickedTime != null) {
      final selectedTimestamp = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      onTakeWithTime(selectedTimestamp);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medColor = Color(item.medication.colorValue);
    final entry = item.historyEntry;

    final bool isTaken = entry?.status == LogStatus.taken;
    final bool isSkipped = entry?.status == LogStatus.skipped;
    final bool isCompleted = isTaken || isSkipped;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isCompleted ? 0 : 1,
      color: isCompleted
          ? theme.colorScheme.surfaceContainer
          : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isTaken
              ? Colors.green.withOpacity(0.5)
              : isSkipped
                  ? Colors.redAccent.withOpacity(0.4)
                  : medColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Scheduled / Taken Time Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isTaken
                    ? Colors.green.withOpacity(0.15)
                    : isSkipped
                        ? Colors.redAccent.withOpacity(0.1)
                        : medColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.time.format(context),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isTaken
                          ? Colors.green
                          : isSkipped
                              ? Colors.redAccent
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isTaken && entry != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Taken ${_formatTimeOfDay(TimeOfDay.fromDateTime(entry.timestamp))}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Medication Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medication.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: isSkipped ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        item.type == ScheduleType.manualLog
                            ? Icons.edit_note
                            : Icons.alarm,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.type == ScheduleType.manualLog
                            ? 'Manual log'
                            : 'Scheduled',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // In-place Status Badge OR Action Buttons
            if (isTaken)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Taken',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else if (isSkipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Skipped',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Skip',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                    ),
                    onPressed: onSkip,
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    icon: const Icon(Icons.check, size: 18),
                    tooltip: 'Take',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () => _handleTakePressed(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
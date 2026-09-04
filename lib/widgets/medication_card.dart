import 'package:flutter/material.dart';
import '../models/enum_types.dart';
import '../models/medication.dart';

class MedicationCard extends StatefulWidget {
  final Medication medication;
  final VoidCallback onTookItPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTookItPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  bool _isExpanded = false;

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month/$day at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final pillColorScheme = ColorScheme.fromSeed(
      seedColor: Color(widget.medication.colorValue),
      brightness: Theme.of(context).brightness,
    );

    final lastTaken = widget.medication.lastTakenEntry;
    final lastTakenText = lastTaken != null
        ? 'Last taken: ${_formatDateTime(lastTaken.timestamp)}'
        : 'Last taken: Never';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: pillColorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: pillColorScheme.primary,
                    foregroundColor: pillColorScheme.onPrimary,
                    child: const Icon(Icons.medication),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.medication.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          lastTakenText,
                          style: TextStyle(fontSize: 12, color: pillColorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.check, size: 20),
                    tooltip: 'Mark as Taken',
                    style: IconButton.styleFrom(
                      backgroundColor: pillColorScheme.primaryContainer,
                      foregroundColor: pillColorScheme.onPrimaryContainer,
                    ),
                    onPressed: widget.onTookItPressed,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: pillColorScheme.primary),
                    tooltip: 'Edit',
                    onPressed: widget.onEditPressed,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Delete',
                    onPressed: widget.onDeletePressed,
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: pillColorScheme.surfaceContainerLowest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4.0),
                  if (widget.medication.reminders.isEmpty)
                    const Text('No fixed schedule (As needed / PRN)', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8.0,
                      children: widget.medication.reminders.map((rule) {
                        return Chip(
                          avatar: const Icon(Icons.alarm, size: 16),
                          label: Text(rule.formatTime(context)),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  const Divider(height: 20.0),
                  const Text('Recent Log Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4.0),
                  if (widget.medication.history.isEmpty)
                    const Text('No intake history recorded.', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    ...widget.medication.history.reversed.take(3).map((entry) {
                      final isTaken = entry.status == LogStatus.taken;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Icon(
                              isTaken ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: isTaken ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              _formatDateTime(entry.timestamp),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
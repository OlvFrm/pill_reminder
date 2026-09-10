import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTookItPressed;
  final VoidCallback onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTookItPressed,
    required this.onTap,
  });

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
      seedColor: Color(medication.colorValue),
      brightness: Theme.of(context).brightness,
    );

    final lastTaken = medication.lastTakenEntry;
    final lastTakenText = lastTaken != null
        ? 'Last taken: ${_formatDateTime(lastTaken.timestamp)}'
        : 'Last taken: Never';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: pillColorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 40,
                decoration: BoxDecoration(
                  color: pillColorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
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
              FilledButton.tonalIcon(
                onPressed: onTookItPressed,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Take'),
                style: FilledButton.styleFrom(
                  backgroundColor: pillColorScheme.primaryContainer,
                  foregroundColor: pillColorScheme.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
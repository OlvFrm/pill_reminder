import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/add_medication_sheet.dart';
import '../repositories/medication_repository.dart';
import '../widgets/history_calendar.dart';

class MedicationDetailScreen extends StatelessWidget {
  final String medicationId;

  const MedicationDetailScreen({super.key, required this.medicationId});

  Future<void> _confirmDelete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text('This will remove "$name" and its history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<MedicationRepository>().removeMedication(medicationId);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<MedicationRepository>();
    final medication = repository.getById(medicationId);

    if (medication == null) {
      return const Scaffold(
        body: Center(child: Text('Medication not found')),
      );
    }

    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(medication.colorValue),
      brightness: base.brightness,
    );
    final pillTheme = base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return Theme(
      data: pillTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(medication.name),
          actions: [
            Builder(
              // Builder so the sheet captures the pill theme from this context.
              builder: (context) => IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddMedicationSheet(
                      initialMedication: medication,
                      onSave: (updated) {
                        context.read<MedicationRepository>().updateMedication(updated);
                      },
                    ),
                  );
                },
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, medication.name),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Schedule',
              style: base.textTheme.titleMedium?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 8.0),
            if (medication.reminders.isEmpty)
              Text(
                'No fixed schedule (As needed / PRN)',
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              ...medication.reminders.map((rule) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  color: scheme.surfaceContainerHigh,
                  child: ListTile(
                    leading: Icon(Icons.alarm, color: scheme.primary),
                    title: Text(rule.formatTime(context)),
                    subtitle: Text('${rule.dosage} · ${rule.daysSummary}'),
                  ),
                );
              }),
            const SizedBox(height: 24.0),
            Text(
              'History',
              style: base.textTheme.titleMedium?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 8.0),
            HistoryCalendar(medication: medication),
          ],
        ),
      ),
    );
  }
}
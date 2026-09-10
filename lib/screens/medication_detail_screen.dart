import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enum_types.dart';
import '../repositories/medication_repository.dart';

class MedicationDetailScreen extends StatelessWidget {
  final String medicationId;

  const MedicationDetailScreen({super.key, required this.medicationId});

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month/$day at $hour:$minute';
  }

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

    final pillColorScheme = ColorScheme.fromSeed(
      seedColor: Color(medication.colorValue),
      brightness: Theme.of(context).brightness,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              // TODO: navigate to edit-medication form
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, medication.name),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Schedule', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8.0),
          if (medication.reminders.isEmpty)
            const Text('No fixed schedule (As needed / PRN)', style: TextStyle(color: Colors.grey))
          else
            ...medication.reminders.map((rule) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: Icon(Icons.alarm, color: pillColorScheme.primary),
                  title: Text(rule.formatTime(context)),
                  subtitle: Text(rule.dosage),
                ),
              );
            }),
          const SizedBox(height: 24.0),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8.0),
          if (medication.history.isEmpty)
            const Text('No intake history recorded.', style: TextStyle(color: Colors.grey))
          else
            ...medication.history.reversed.map((entry) {
              final isTaken = entry.status == LogStatus.taken;
              return ListTile(
                leading: Icon(
                  isTaken ? Icons.check_circle : Icons.cancel,
                  color: isTaken ? Colors.green : Colors.red,
                ),
                title: Text(_formatDateTime(entry.timestamp)),
                subtitle: Text(entry.dosage),
                trailing: Text(
                  entry.status.name,
                  style: TextStyle(color: pillColorScheme.onSurfaceVariant),
                ),
              );
            }),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../repositories/medication_repository.dart';
import '../widgets/medication_card.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  Future<void> _logManualTake(BuildContext context, String medicationId) async {
    final repository = context.read<MedicationRepository>();
    final medication = repository.getById(medicationId);
    if (medication == null) return;

    final controller = TextEditingController();

    final dosage = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log dose'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Dosage (e.g. 1 pill, 500mg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Log'),
          ),
        ],
      ),
    );

    if (dosage == null || dosage.isEmpty) return;

    final entry = HistoryEntry(
      medicationId: medicationId,
      timestamp: DateTime.now(),
      status: LogStatus.taken,
      source: LogSource.manualEntry,
      dosage: dosage,
    );

    repository.updateMedication(
      medication.copyWith(history: [...medication.history, entry]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<MedicationRepository>();
    final medications = repository.medications;

    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: medications.isEmpty
          ? const Center(child: Text('No medications yet'))
          : ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return MedicationCard(
                  medication: medication,
                  onTookItPressed: () => _logManualTake(context, medication.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicationDetailScreen(
                          medicationId: medication.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add-medication form
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
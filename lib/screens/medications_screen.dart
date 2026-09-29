import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../repositories/medication_repository.dart';
import '../widgets/medication_card.dart';
import '../widgets/log_dose_dialog.dart';
import '../widgets/add_medication_sheet.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  Future<void> _logManualTake(BuildContext context, String medicationId) async {
    final repository = context.read<MedicationRepository>();
    final medication = repository.getById(medicationId);
    if (medication == null) return;

    final result = await showLogDoseDialog(context, medication);
    if (result == null) return;

    final (dosage, timestamp) = result;

    final entry = HistoryEntry.create(
      medicationId: medicationId,
      timestamp: timestamp,
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddMedicationSheet(
              onSave: (medication) {
                context.read<MedicationRepository>().addMedication(medication);
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
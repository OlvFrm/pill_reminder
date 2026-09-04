import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_repository.dart';
import '../widgets/add_medication_sheet.dart';
import '../widgets/medication_card.dart';

class MedicationsScreen extends StatelessWidget {
  final MedicationRepository repository;

  const MedicationsScreen({super.key, required this.repository});

  void _openAddEditSheet(BuildContext context, [Medication? medication]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddMedicationSheet(
        initialMedication: medication,
        onSave: (savedMed) {
          if (medication == null) {
            repository.addMedication(savedMed);
          } else {
            repository.updateMedication(savedMed);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
      ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final medications = repository.medications;

          if (medications.isEmpty) {
            return const Center(
              child: Text('No medications listed.'),
            );
          }

          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              return MedicationCard(
                medication: med,
                onTookItPressed: () => repository.logPillTaken(med.id),
                onEditPressed: () => _openAddEditSheet(context, med),
                onDeletePressed: () => repository.deleteMedication(med.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/features/medications/application/medication_providers.dart';

import 'medication_form_screen.dart';
import 'medication_history_screen.dart';

class MedicationsListScreen extends ConsumerWidget {
  const MedicationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(allMedicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: medicationsAsync.when(
        data: (medications) {
          if (medications.isEmpty) {
            return const Center(child: Text('No medications yet'));
          }
          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, i) {
              final medication = medications[i];
              return ListTile(
                title: Text(medication.name),
                subtitle: Text(medication.dosage),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      MedicationHistoryScreen(medicationId: medication.id),
                )),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        MedicationFormScreen(existing: medication),
                  )),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const MedicationFormScreen(),
        )),
        child: const Icon(Icons.add),
      ),
    );
  }
}

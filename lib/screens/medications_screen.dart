import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/medication_repository.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

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
                return ListTile(
                  title: Text(medication.name),
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
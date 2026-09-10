import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/medication_repository.dart';

class MedicationDetailScreen extends StatelessWidget {
  final String medicationId;

  const MedicationDetailScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<MedicationRepository>();
    final medication = repository.getById(medicationId);

    if (medication == null) {
      return const Scaffold(
        body: Center(child: Text('Medication not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(medication.name)),
      body: medication.history.isEmpty
          ? const Center(child: Text('No history yet'))
          : ListView.builder(
              itemCount: medication.history.length,
              itemBuilder: (context, index) {
                final entry = medication.history[index];
                return ListTile(
                  title: Text(entry.status.name),
                  subtitle: Text(entry.timestamp.toString()),
                );
              },
            ),
    );
  }
}
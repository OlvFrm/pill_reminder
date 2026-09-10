import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/features/doses/application/dose_providers.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';
import 'package:medication_tracker/features/medications/application/medication_providers.dart';

class MedicationHistoryScreen extends ConsumerWidget {
  final String medicationId;
  const MedicationHistoryScreen({required this.medicationId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAsync = ref.watch(medicationByIdProvider(medicationId));
    final historyAsync = ref.watch(doseHistoryProvider(medicationId));

    return Scaffold(
      appBar: AppBar(
        title: medicationAsync.maybeWhen(
          data: (m) => Text(m?.name ?? 'History'),
          orElse: () => const Text('History'),
        ),
      ),
      // Adherence stat intentionally omitted for now, per your earlier
      // call — this just lists the last 60 days of doses. Drop an
      // AdherenceStatCard widget in here later, fed from the same
      // historyAsync data, once you've decided how skipped/missed should
      // weigh against each other.
      body: historyAsync.when(
        data: (doses) => ListView.builder(
          itemCount: doses.length,
          itemBuilder: (context, i) {
            final dose = doses[i];
            return ListTile(
              title: Text(_formatDate(dose.scheduledFor)),
              trailing: Text(dose.status.name),
              leading: Icon(_iconFor(dose.status)),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  IconData _iconFor(DoseStatus status) => switch (status) {
        DoseStatus.taken => Icons.check_circle,
        DoseStatus.skipped => Icons.remove_circle,
        DoseStatus.missed => Icons.cancel,
        DoseStatus.pending => Icons.schedule,
      };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/features/doses/application/dose_providers.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';

import 'widgets/dose_tile.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Normalize to midnight so the provider's `.family` cache key is
    // stable regardless of what time build() happens to run at.
    final day =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dosesAsync = ref.watch(dosesForDayProvider(day));

    return Scaffold(
      appBar: AppBar(
        title: _DayPicker(
          day: day,
          onChanged: (d) => setState(() => _selectedDay = d),
        ),
      ),
      body: dosesAsync.when(
        data: (doses) {
          if (doses.isEmpty) {
            return const Center(child: Text('No doses scheduled'));
          }
          return ListView.builder(
            itemCount: doses.length,
            itemBuilder: (context, i) {
              final dose = doses[i];
              return DoseTile(
                dose: dose,
                onTap: () => _showActionSheet(context, dose),
                onLongPress: () => _confirmDelete(context, dose),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddManualDoseDialog(context, day),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showActionSheet(BuildContext context, Dose dose) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          for (final status in DoseStatus.values)
            ListTile(
              title: Text('Mark as ${status.name}'),
              onTap: () {
                ref
                    .read(doseRepositoryProvider)
                    .updateStatus(dose.id, status);
                Navigator.of(context).pop();
              },
            ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Dose dose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete dose?'),
        content: const Text('This removes it entirely, not just marks it skipped.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(doseRepositoryProvider).deleteDose(dose.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddManualDoseDialog(BuildContext context, DateTime day) {
    // TODO: replace with a real form (medication picker + time picker).
    // Left as a stub so the wiring — creating a Dose with isManual: true
    // and pushing it through doseRepositoryProvider — is clear:
    //
    // ref.read(doseRepositoryProvider).addManualDose(Dose(
    //   id: uuid.v4(),
    //   medicationId: chosenMedicationId,
    //   scheduledFor: chosenDateTime,
    //   isManual: true,
    // ));
  }
}

class _DayPicker extends StatelessWidget {
  final DateTime day;
  final ValueChanged<DateTime> onChanged;
  const _DayPicker({required this.day, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(day.subtract(const Duration(days: 1))),
        ),
        Text('${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(day.add(const Duration(days: 1))),
        ),
      ],
    );
  }
}

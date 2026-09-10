import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/core/domain/scheduled_time.dart';
import 'package:medication_tracker/features/doses/application/dose_providers.dart';
import 'package:medication_tracker/features/medications/application/medication_providers.dart';
import 'package:medication_tracker/features/medications/domain/medication.dart';
import 'package:uuid/uuid.dart';

class MedicationFormScreen extends ConsumerStatefulWidget {
  final Medication? existing;
  const MedicationFormScreen({this.existing, super.key});

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late List<ScheduledTime> _times;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name);
    _dosageController = TextEditingController(text: widget.existing?.dosage);
    _times = List.of(widget.existing?.scheduledTimes ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add medication' : 'Edit medication'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await ref
                    .read(medicationRepositoryProvider)
                    .delete(widget.existing!.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            const SizedBox(height: 16),
            _TimesEditor(
              times: _times,
              onChanged: (times) => setState(() => _times = times),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final medication = Medication(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text,
      dosage: _dosageController.text,
      scheduledTimes: _times,
    );

    final repo = ref.read(medicationRepositoryProvider);
    if (widget.existing == null) {
      await repo.create(medication);
    } else {
      await repo.update(medication);
    }

    // New/changed schedule → make sure doses exist for the horizon and
    // notifications are (re)scheduled to match.
    await ref.read(doseSchedulingServiceProvider).ensureUpToDate();

    if (mounted) Navigator.of(context).pop();
  }
}

/// Minimal time-of-day list editor. Swap for a nicer picker UI later —
/// the important part architecturally is that it only ever produces/edits
/// a `List<ScheduledTime>`, so it plugs straight into Medication.
class _TimesEditor extends StatelessWidget {
  final List<ScheduledTime> times;
  final ValueChanged<List<ScheduledTime>> onChanged;

  const _TimesEditor({required this.times, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Scheduled times'),
        for (final t in times)
          ListTile(
            title: Text(t.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  onChanged(times.where((x) => x != t).toList()),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add time'),
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              onChanged([
                ...times,
                ScheduledTime(hour: picked.hour, minute: picked.minute),
              ]);
            }
          },
        ),
      ],
    );
  }
}

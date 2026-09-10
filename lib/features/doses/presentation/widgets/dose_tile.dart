import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';
import 'package:medication_tracker/features/medications/application/medication_providers.dart';

class DoseTile extends ConsumerWidget {
  final Dose dose;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DoseTile({
    required this.dose,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAsync =
        ref.watch(medicationByIdProvider(dose.medicationId));

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _StatusIcon(status: dose.status),
      title: medicationAsync.when(
        data: (m) => Text(m?.name ?? '(deleted medication)'),
        loading: () => const Text('…'),
        error: (_, __) => const Text('(error)'),
      ),
      subtitle: medicationAsync.maybeWhen(
        data: (m) => Text(m?.dosage ?? ''),
        orElse: () => null,
      ),
      trailing: Text(
        '${dose.scheduledFor.hour.toString().padLeft(2, '0')}:'
        '${dose.scheduledFor.minute.toString().padLeft(2, '0')}',
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final DoseStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      DoseStatus.pending => (Icons.schedule, Colors.grey),
      DoseStatus.taken => (Icons.check_circle, Colors.green),
      DoseStatus.skipped => (Icons.remove_circle, Colors.orange),
      DoseStatus.missed => (Icons.cancel, Colors.red),
    };
    return Icon(icon, color: color);
  }
}

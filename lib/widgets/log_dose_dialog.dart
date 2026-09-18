import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

/// Shows a dialog to log a manual dose: dosage text + timestamp (defaults to now).
/// Returns null if cancelled, otherwise the chosen dosage and timestamp.
Future<(String dosage, DateTime timestamp)?> showLogDoseDialog(
  BuildContext context,
  Medication medication,
) {
  return showDialog<(String, DateTime)>(
    context: context,
    builder: (_) => _LogDoseDialog(medication: medication),
  );
}

class _LogDoseDialog extends StatefulWidget {
  final Medication medication;

  const _LogDoseDialog({required this.medication});

  @override
  State<_LogDoseDialog> createState() => _LogDoseDialogState();
}

class _LogDoseDialogState extends State<_LogDoseDialog> {
  late final TextEditingController _dosageController;
  late DateTime _selectedTime;
  late List<String> _suggestedDosages;

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController();
    _selectedTime = DateTime.now();
    _suggestedDosages = _computeSuggestedDosages();

    if (_suggestedDosages.isNotEmpty) {
      _dosageController.text = _suggestedDosages.first;
    }

    _dosageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _dosageController.dispose();
    super.dispose();
  }

  List<String> _computeSuggestedDosages() {
    final history = widget.medication.history;
    if (history.isEmpty) return [];

    final sortedByRecency = [...history]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final lastUsed = sortedByRecency.first.dosage;

    final frequency = <String, int>{};
    for (final entry in history) {
      frequency[entry.dosage] = (frequency[entry.dosage] ?? 0) + 1;
    }
    final byFrequency = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

    final suggestions = <String>[lastUsed];
    for (final dosage in byFrequency) {
      if (suggestions.length >= 3) break;
      if (!suggestions.contains(dosage)) suggestions.add(dosage);
    }
    return suggestions;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    setState(() {
      _selectedTime = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    });
  }

  void _onTimeChanged(DateTime dt) {
    setState(() {
      _selectedTime = DateTime(
        _selectedTime.year,
        _selectedTime.month,
        _selectedTime.day,
        dt.hour,
        dt.minute,
      );
    });
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final dosage = _dosageController.text.trim();
    final canSubmit = dosage.isNotEmpty;
    final brightness = Theme.of(context).brightness;

    return AlertDialog(
      title: const Text('Log dose'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _dosageController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Dosage (e.g. 1 pill, 500mg)'),
            ),
            if (_suggestedDosages.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children: _suggestedDosages.map((suggestion) {
                  return ChoiceChip(
                    label: Text(suggestion),
                    selected: _dosageController.text == suggestion,
                    onSelected: (_) => _dosageController.text = suggestion,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16.0),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(_formatDate(_selectedTime)),
              ),
            ),
            const SizedBox(height: 12.0),
            Text('Time', style: Theme.of(context).textTheme.bodySmall),
            SizedBox(
              height: 150,
              child: CupertinoTheme(
                data: CupertinoThemeData(brightness: brightness),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _selectedTime,
                  use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                  onDateTimeChanged: _onTimeChanged,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () => Navigator.pop(context, (dosage, _selectedTime))
              : null,
          child: const Text('Log'),
        ),
      ],
    );
  }
}
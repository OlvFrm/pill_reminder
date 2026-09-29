import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../models/medication.dart';
import 'log_status_style.dart';

sealed class DoseDialogResult {
  const DoseDialogResult();
}

class DoseSaved extends DoseDialogResult {
  final String dosage;
  final DateTime timestamp;
  final LogStatus status;
  const DoseSaved(this.dosage, this.timestamp, this.status);
}

class DoseDeleted extends DoseDialogResult {
  const DoseDeleted();
}

/// Add mode: leave [initialEntry] null (optionally pass [initialDate]).
/// Edit mode: pass [initialEntry]; status selector and Delete are shown.
Future<DoseDialogResult?> showDoseDialog(
  BuildContext context,
  Medication medication, {
  HistoryEntry? initialEntry,
  DateTime? initialDate,
  bool chooseStatus = false,
}) {
  return showDialog<DoseDialogResult>(
    context: context,
    builder: (_) => _DoseDialog(
      medication: medication,
      initialEntry: initialEntry,
      initialDate: initialDate,
      chooseStatus: chooseStatus,
    ),
  );
}

/// Backwards-compatible wrapper for the existing "Take" flow.
Future<(String dosage, DateTime timestamp)?> showLogDoseDialog(
  BuildContext context,
  Medication medication,
) async {
  final result = await showDoseDialog(context, medication);
  return result is DoseSaved ? (result.dosage, result.timestamp) : null;
}

class _DoseDialog extends StatefulWidget {
  final Medication medication;
  final HistoryEntry? initialEntry;
  final DateTime? initialDate;
  final bool chooseStatus;

  const _DoseDialog({
    required this.medication,
    this.initialEntry,
    this.initialDate,
    this.chooseStatus = false,
  });

  @override
  State<_DoseDialog> createState() => _DoseDialogState();
}

class _DoseDialogState extends State<_DoseDialog> {
  late final TextEditingController _dosageController;
  late DateTime _selectedTime;
  late LogStatus _status;
  late List<String> _suggestedDosages;

  bool get _isEditing => widget.initialEntry != null;
  bool get _showStatus => _isEditing || widget.chooseStatus;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    final now = DateTime.now();

    if (entry != null) {
      _selectedTime = entry.timestamp;
      _status = entry.status;
    } else {
      final day = widget.initialDate ?? now;
      _selectedTime = DateTime(day.year, day.month, day.day, now.hour, now.minute);
      _status = LogStatus.taken;
    }

    _suggestedDosages = _computeSuggestedDosages();
    _dosageController = TextEditingController(
      text: entry?.dosage ??
          (_suggestedDosages.isNotEmpty ? _suggestedDosages.first : ''),
    );
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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: _selectedTime.isAfter(now) ? _selectedTime : now,
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, const DoseDeleted());
    }
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
      title: Text(_isEditing ? 'Edit dose' : 'Log dose'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showStatus) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<LogStatus>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in LogStatus.values)
                      ButtonSegment(value: s, label: Text(s.label)),
                  ],
                  selected: {_status},
                  onSelectionChanged: (s) => setState(() => _status = s.first),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            TextField(
              controller: _dosageController,
              autofocus: !_isEditing,
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
        if (_isEditing)
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () => Navigator.pop(
                    context,
                    DoseSaved(dosage, _selectedTime, _status),
                  )
              : null,
          child: Text(_isEditing ? 'Save' : 'Log'),
        ),
      ],
    );
  }
}
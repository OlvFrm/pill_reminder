import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/reminder_rule.dart';

class AddMedicationSheet extends StatefulWidget {
  final Medication? initialMedication;
  final ValueChanged<Medication> onSave;

  const AddMedicationSheet({
    super.key,
    this.initialMedication,
    required this.onSave,
  });

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

/// A reminder slot being edited: a time, its own dosage, and which days it fires.
class _ReminderDraft {
  TimeOfDay time;
  final TextEditingController dosageController;
  Set<int> selectedDays; // 1 = Monday, 7 = Sunday
  String? dosageError;
  String? daysError;

  _ReminderDraft({
    required this.time,
    String dosage = '',
    Set<int>? selectedDays,
  })  : dosageController = TextEditingController(text: dosage),
        selectedDays = selectedDays ?? {1, 2, 3, 4, 5, 6, 7};

  int get sortKey => time.hour * 60 + time.minute;

  void dispose() => dosageController.dispose();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _selectedColor;
  late List<_ReminderDraft> _reminderDrafts;

  static const List<int> _colorOptions = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
  ];

  // static const List<int> _allDays = [1, 2, 3, 4, 5, 6, 7];
  static const List<String> _dayAbbrev = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const List<String> _dayFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const Set<int> _weekdays = {1, 2, 3, 4, 5};
  static const Set<int> _weekend = {6, 7};

  @override
  void initState() {
    super.initState();
    _name = widget.initialMedication?.name ?? '';
    _selectedColor = widget.initialMedication?.colorValue ?? _colorOptions.first;
    _reminderDrafts = widget.initialMedication?.reminders
            .map((r) => _ReminderDraft(
                  time: r.time,
                  dosage: r.dosage,
                  selectedDays: r.daysOfWeek.toSet(),
                ))
            .toList() ??
        [_ReminderDraft(time: const TimeOfDay(hour: 8, minute: 0))];
    _sortDrafts();
  }

  @override
  void dispose() {
    for (final draft in _reminderDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _sortDrafts() {
    _reminderDrafts.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderDrafts[index].time,
    );
    if (picked != null) {
      setState(() {
        _reminderDrafts[index].time = picked;
        _sortDrafts();
      });
    }
  }

  Future<void> _addTimeSlot() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _reminderDrafts.add(_ReminderDraft(time: picked));
        _sortDrafts();
      });
    }
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _reminderDrafts.removeAt(index).dispose();
    });
  }

  void _toggleDay(_ReminderDraft draft, int day) {
    setState(() {
      if (draft.selectedDays.contains(day)) {
        draft.selectedDays.remove(day);
      } else {
        draft.selectedDays.add(day);
      }
      if (draft.selectedDays.isNotEmpty) draft.daysError = null;
    });
  }

  String _daySummary(Set<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.containsAll(_weekdays)) return 'Weekdays';
    if (days.length == 2 && days.containsAll(_weekend)) return 'Weekends';
    if (days.isEmpty) return 'No days selected';
    final sorted = days.toList()..sort();
    return sorted.map((d) => _dayAbbrev[d - 1]).join(', ');
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    var allValid = true;
    setState(() {
      for (final draft in _reminderDrafts) {
        final dosage = draft.dosageController.text.trim();
        draft.dosageError = dosage.isEmpty ? 'Required' : null;
        if (dosage.isEmpty) allValid = false;

        draft.daysError = draft.selectedDays.isEmpty ? 'Select at least one day' : null;
        if (draft.selectedDays.isEmpty) allValid = false;
      }
    });
    if (!allValid) return;

    _formKey.currentState!.save();

    final updatedReminders = List.generate(_reminderDrafts.length, (i) {
      final draft = _reminderDrafts[i];
      final sortedDays = draft.selectedDays.toList()..sort();
      return ReminderRule(
        id: widget.initialMedication?.reminders.elementAtOrNull(i)?.id ??
            '${DateTime.now().millisecondsSinceEpoch}_rule_$i',
        hour: draft.time.hour,
        minute: draft.time.minute,
        daysOfWeek: sortedDays,
        dosage: draft.dosageController.text.trim(),
      );
    });

    final updatedMedication = Medication(
      id: widget.initialMedication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name,
      colorValue: _selectedColor,
      reminders: updatedReminders,
      history: widget.initialMedication?.history ?? [],
    );

    widget.onSave(updatedMedication);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialMedication == null ? 'Add Medication' : 'Edit Medication',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a name' : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: 20),
              const Text('Color Label', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _colorOptions.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: Color(c),
                      radius: 18,
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: _addTimeSlot,
                    icon: const Icon(Icons.add_alarm, size: 18),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_reminderDrafts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No scheduled reminders set. This pill can be logged as needed.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: List.generate(_reminderDrafts.length, (index) {
                    final draft = _reminderDrafts[index];
                    final scheme = Theme.of(context).colorScheme;

                    return Card(
                      elevation: 0,
                      color: scheme.surfaceContainerHighest,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _pickTime(index),
                                  child: Text(
                                    draft.time.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: draft.dosageController,
                                    decoration: InputDecoration(
                                      labelText: 'Dosage',
                                      hintText: 'e.g. 1 pill',
                                      isDense: true,
                                      errorText: draft.dosageError,
                                    ),
                                    onChanged: (_) {
                                      if (draft.dosageError != null) {
                                        setState(() => draft.dosageError = null);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                  onPressed: () => _removeTimeSlot(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _daySummary(draft.selectedDays),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: draft.daysError != null
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(7, (dayIndex) {
                                final day = dayIndex + 1; // 1 = Monday
                                final selected = draft.selectedDays.contains(day);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Tooltip(
                                      message: _dayFull[dayIndex],
                                      child: InkWell(
                                        onTap: () => _toggleDay(draft, day),
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected ? scheme.primary : Colors.transparent,
                                            border: Border.all(
                                              color: selected ? scheme.primary : scheme.outlineVariant,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _dayAbbrev[dayIndex],
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Save Medication', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _selectedColor;
  late List<TimeOfDay> _reminderTimes;

  static const List<int> _colorOptions = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
  ];

  static const List<int> _allDays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _name = widget.initialMedication?.name ?? '';
    _selectedColor = widget.initialMedication?.colorValue ?? _colorOptions.first;
    _reminderTimes = widget.initialMedication?.reminders
            .map((r) => r.time)
            .toList() ??
        [const TimeOfDay(hour: 8, minute: 0)];
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() {
        _reminderTimes[index] = picked;
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
        _reminderTimes.add(picked);
      });
    }
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedReminders = List.generate(_reminderTimes.length, (i) {
        final time = _reminderTimes[i];
        return ReminderRule(
          id: '${DateTime.now().millisecondsSinceEpoch}_rule_$i',
          hour: time.hour,
          minute: time.minute,
          daysOfWeek: _allDays,
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
              if (_reminderTimes.isEmpty)
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
                  children: List.generate(_reminderTimes.length, (index) {
                    final time = _reminderTimes[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.access_time),
                        title: Text(
                          time.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeTimeSlot(index),
                        ),
                        onTap: () => _pickTime(index),
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
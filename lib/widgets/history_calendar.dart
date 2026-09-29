import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import 'log_dose_dialog.dart';
import 'log_status_style.dart';

class HistoryCalendar extends StatefulWidget {
  final Medication medication;

  const HistoryCalendar({super.key, required this.medication});

  @override
  State<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<HistoryCalendar> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  Map<DateTime, List<HistoryEntry>> _groupByDay() {
    final byDay = <DateTime, List<HistoryEntry>>{};
    for (final e in widget.medication.history) {
      final key = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      (byDay[key] ??= []).add(e);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return byDay;
  }

  Future<void> _addEntry() async {
    final result = await showDoseDialog(
      context,
      widget.medication,
      initialDate: _selected,
      chooseStatus: true,
    );
    if (result is! DoseSaved || !mounted) return;

    context.read<MedicationRepository>().addHistoryEntry(
          HistoryEntry.create(
            medicationId: widget.medication.id,
            timestamp: result.timestamp,
            status: result.status,
            source: LogSource.manualEntry,
            dosage: result.dosage,
          ),
        );
    setState(() {
      _selected = result.timestamp;
      _focused = result.timestamp;
    });
  }

  Future<void> _editEntry(HistoryEntry entry) async {
    final result = await showDoseDialog(
      context,
      widget.medication,
      initialEntry: entry,
    );
    if (result == null || !mounted) return;

    final repository = context.read<MedicationRepository>();
    switch (result) {
      case DoseSaved(:final dosage, :final timestamp, :final status):
        repository.updateHistoryEntry(
          entry.copyWith(timestamp: timestamp, status: status, dosage: dosage),
        );
        // Follow the entry if it moved to another day.
        setState(() {
          _selected = timestamp;
          _focused = timestamp;
        });
      case DoseDeleted():
        repository.removeHistoryEntry(entry.medicationId, entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _groupByDay();
    List<HistoryEntry> entriesFor(DateTime d) =>
        byDay[DateTime(d.year, d.month, d.day)] ?? const [];

    final now = DateTime.now();
    final selectedEntries = entriesFor(_selected);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar<HistoryEntry>(
          firstDay: DateTime(2020),
          lastDay: DateTime(now.year, now.month, now.day, 23, 59, 59),
          focusedDay: _focused,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          selectedDayPredicate: (d) => isSameDay(d, _selected),
          eventLoader: entriesFor,
          onDaySelected: (selected, focused) => setState(() {
            _selected = selected;
            _focused = focused;
          }),
          onPageChanged: (focused) => _focused = focused,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, entries) {
              if (entries.isEmpty) return null;
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in entries.take(4))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: e.status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Wrap(
          spacing: 16,
          children: [
            for (final s in LogStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: s.color),
                  const SizedBox(width: 4),
                  Text(s.label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                MaterialLocalizations.of(context).formatMediumDate(_selected),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add entry on this day',
              onPressed: _addEntry,
            ),
          ],
        ),
        if (selectedEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No entries this day.', style: TextStyle(color: Colors.grey)),
          )
        else
          for (final e in selectedEntries)
            ListTile(
              leading: Icon(e.status.icon, color: e.status.color),
              title: Text(TimeOfDay.fromDateTime(e.timestamp).format(context)),
              subtitle: Text(e.dosage),
              trailing: Text(
                e.status.label,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onTap: () => _editEntry(e),
            ),
      ],
    );
  }
}
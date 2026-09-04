import 'package:flutter/material.dart';
import '../models/enum_types.dart';
import '../models/history_entry.dart';
import '../models/medication.dart';
import '../services/medication_repository.dart';
import '../widgets/schedule_card.dart';

enum ScheduleType { scheduled, manualLog }

class ScheduleItem {
  final Medication medication;
  final TimeOfDay time;
  final ScheduleType type;
  final HistoryEntry? historyEntry;

  const ScheduleItem({
    required this.medication,
    required this.time,
    required this.type,
    this.historyEntry,
  });

  int compareTo(ScheduleItem other) {
    final aMinutes = time.hour * 60 + time.minute;
    final bMinutes = other.time.hour * 60 + other.time.minute;
    return aMinutes.compareTo(bMinutes);
  }
}

class HomeScreen extends StatelessWidget {
  final MedicationRepository repository;

  const HomeScreen({super.key, required this.repository});

  List<ScheduleItem> _buildDailySchedule(List<Medication> medications) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final List<ScheduleItem> schedule = [];

    for (final med in medications) {
      // 1. Get today's log history entries
      final todayEntries = med.history.where((entry) {
        return entry.timestamp.year == now.year &&
            entry.timestamp.month == now.month &&
            entry.timestamp.day == now.day;
      }).toList();

      final usedEntryIds = <HistoryEntry>{};

      // 2. Build scheduled items & bind history entries directly to them
      for (final rule in med.reminders) {
        if (rule.daysOfWeek.contains(todayWeekday)) {
          final ruleTime = TimeOfDay(hour: rule.hour, minute: rule.minute);

          // Find matching entry logged for this rule
          HistoryEntry? matchingEntry;
          for (final entry in todayEntries) {
            if (!usedEntryIds.contains(entry) &&
                entry.source == LogSource.notificationAction) {
              matchingEntry = entry;
              usedEntryIds.add(entry);
              break;
            }
          }

          schedule.add(
            ScheduleItem(
              medication: med,
              time: ruleTime,
              type: ScheduleType.scheduled,
              historyEntry: matchingEntry,
            ),
          );
        }
      }

      // 3. Add standalone manual logs (logged without a schedule rule)
      for (final entry in todayEntries) {
        if (!usedEntryIds.contains(entry) && entry.source == LogSource.manualEntry) {
          schedule.add(
            ScheduleItem(
              medication: med,
              time: TimeOfDay.fromDateTime(entry.timestamp),
              type: ScheduleType.manualLog,
              historyEntry: entry,
            ),
          );
        }
      }
    }

    schedule.sort((a, b) => a.compareTo(b));
    return schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Schedule'),
      ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final scheduleItems = _buildDailySchedule(repository.medications);

          if (scheduleItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No doses scheduled for today.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: scheduleItems.length,
            itemBuilder: (context, index) {
              final item = scheduleItems[index];
              return ScheduleCard(
                item: item,
                onTakeWithTime: (selectedTimestamp) {
                  repository.logPillTaken(
                    item.medication.id,
                    timestamp: selectedTimestamp,
                    source: item.type == ScheduleType.scheduled
                        ? LogSource.notificationAction
                        : LogSource.manualEntry,
                  );
                },
                onSkip: () {
                  final now = DateTime.now();
                  final skippedTime = item.type == ScheduleType.scheduled
                      ? DateTime(now.year, now.month, now.day, item.time.hour, item.time.minute)
                      : now;

                  repository.logPillSkipped(
                    item.medication.id,
                    timestamp: skippedTime,
                    source: item.type == ScheduleType.scheduled
                        ? LogSource.notificationAction
                        : LogSource.manualEntry,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
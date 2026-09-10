import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medication_tracker/features/doses/domain/dose.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

const _takenActionId = 'dose_taken';
const _skippedActionId = 'dose_skipped';

/// Wraps flutter_local_notifications. This is the one place in the app
/// where behaviour is triggered by the OS rather than by a widget or a
/// provider read — a notification action button is tapped while the app
/// may not even be in the foreground. Because of that, this service can't
/// simply call a repository the normal Riverpod way (`ref.read(...)`); it
/// needs a callback wired up once at startup instead (see main.dart).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set once from main.dart after the ProviderContainer exists, so the
  /// OS-triggered action callback below can still update dose status.
  void Function(String doseId, DoseStatus status)? onDoseActioned;

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    // Required whenever the app runs on Linux (e.g. `flutter run` on
    // desktop during development) — flutter_local_notifications throws at
    // init time if the platform it's running on doesn't have settings
    // provided, even if you don't otherwise care about Linux support.
    const linuxInit =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        linux: linuxInit,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
  }

  void _handleResponse(NotificationResponse response) {
    final doseId = response.payload;
    if (doseId == null) return;

    switch (response.actionId) {
      case _takenActionId:
        onDoseActioned?.call(doseId, DoseStatus.taken);
      case _skippedActionId:
        onDoseActioned?.call(doseId, DoseStatus.skipped);
      default:
        // Plain tap (no action button) — just opens the app; the Schedule
        // screen already shows the dose as pending, nothing to do here.
        break;
    }
  }

  Future<void> scheduleDoseNotification({
    required Dose dose,
    required String medicationName,
    required String dosage,
  }) async {
    // Using tz.TZDateTime (not plain DateTime) is what makes exact-time
    // scheduling survive timezone changes/DST — plain DateTime is not
    // reliable for this with flutter_local_notifications on Android.
    final scheduled = tz.TZDateTime.from(dose.scheduledFor, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id: dose.id.hashCode, // stable per-dose notification id
        title: 'Time for $medicationName',
        body: dosage,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'dose_reminders',
            'Dose reminders',
            actions: const [
              AndroidNotificationAction(_takenActionId, 'Mark taken'),
              AndroidNotificationAction(_skippedActionId, 'Mark skipped'),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'dose_reminder_category',
          ),
        ),
        payload: dose.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Note: `uiLocalNotificationDateInterpretation` and
        // `androidAllowWhileIdle` no longer exist as of v18+ — the plugin
        // dropped pre-iOS-10 support, and androidScheduleMode fully replaced
        // the old idle-mode flag.
      );
    } on UnimplementedError {
      // Some platform backends (Linux desktop, as of this plugin version)
      // don't implement scheduled notifications at all — only immediate
      // `show()`. That's a real gap for that platform, not something to
      // paper over silently in production, but it shouldn't crash the app;
      // dose data/status still works fine without the reminder firing.
    }
  }

  Future<void> cancelForDose(String doseId) async {
    try {
      await _plugin.cancel(id: doseId.hashCode);
    } on UnimplementedError {
      // See note above.
    }
  }
}

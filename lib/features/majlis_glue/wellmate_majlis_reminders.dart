import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:wellmate/core/services/notificationService.dart';
import 'package:wellmate/features/majlis/majlis.dart';

/// "Remind me" for scheduled Majlis spaces, on WellMate's own notifications.
///
/// Drop this file into WellMate unchanged (for example at
/// lib/features/majlis_glue/wellmate_majlis_reminders.dart) and pass it in
/// MajlisConfig:
///
///     reminders: WellMateMajlisReminders(notificationService),
///
/// NotificationService does the setup (time zone, notification permission);
/// this class schedules one notification 10 minutes before the space starts
/// with the same flutter_local_notifications plugin, and cancels it again.
class WellMateMajlisReminders implements MajlisReminders {
  WellMateMajlisReminders(this.notifications);

  final NotificationService notifications;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const lead = Duration(minutes: 10);

  /// One notification id per space, the same on every run, and far away from
  /// WellMate's own ids (1, 100 and the daily reminders).
  static int idFor(String spaceId) {
    var h = 0x811c9dc5;
    for (final c in spaceId.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return 700000000 + h % 100000000;
  }

  @override
  Future<void> schedule(MajlisSpace space, {required String title, required String body}) async {
    final start = space.scheduledFor;
    if (start == null) return;
    final now = DateTime.now();
    if (!start.isAfter(now)) return;
    // Less than 10 minutes left: remind in a few seconds instead.
    var at = start.subtract(lead);
    if (at.isBefore(now.add(const Duration(seconds: 10)))) at = now.add(const Duration(seconds: 10));

    await notifications.initNotification();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Exact alarms need a permission that Android 14+ does not grant by
    // default. Without it the reminder can come a few minutes late.
    final exact = await android?.canScheduleExactNotifications() ?? true;

    await _plugin.zonedSchedule(
      id: idFor(space.id),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'majlis_reminders',
          'Majlis reminders',
          channelDescription: 'A reminder 10 minutes before a Majlis space you chose',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'majlis:${space.id}',
    );
    debugPrint('Majlis reminder set for ${space.id} at $at (exact: $exact)');
  }

  @override
  Future<void> cancel(String spaceId) async {
    await notifications.initNotification();
    await _plugin.cancel(id: idFor(spaceId));
  }
}

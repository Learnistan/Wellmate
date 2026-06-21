import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kabul'));

    // ✅ ANDROID PERMISSIONS (CRITICAL for Android 12+ / 13+)
    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_channel',
      'Daily Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> scheduleInactivityReminder() async {
    print("GOOODBYE");
    final scheduledTime = tz.TZDateTime.now(tz.local)
        .add(const Duration(seconds: 30));

    await _plugin.zonedSchedule(
      id: 100,
      title: "We miss you!",
      body: "Come back and complete today's activities.",
      scheduledDate: tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel',
          'Inactivity Reminders',
          importance: Importance.max,
          priority: Priority.high
        ),
      ),
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelInactivityReminder() async {
    await _plugin.cancel(id: 100);
  }
}
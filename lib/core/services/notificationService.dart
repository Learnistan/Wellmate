import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    final TimezoneInfo timezoneInfo =
    await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _isInitialized = true;
  }

  Future<void> showInstantNotification() async {
    await initNotification();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'wellmate_channel',
        'Wellmate Notifications',
        channelDescription: 'Wellmate reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: 1,
      title: 'Instant notification',
      body: 'Instant notification works',
      notificationDetails: details,
    );
  }

  Future<void> scheduleOneDayNotification({required String message, required String title}) async {
    await initNotification();

    await _plugin.cancel(id: 100);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      const Duration(hours: 24),
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'wellmate_channel',
        'Wellmate Notifications',
        channelDescription: 'Wellmate reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: 100,
      title: title,
      body: message,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    final pending = await _plugin.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    print('Scheduled for: $scheduledDate');
  }

  Future<void> cancelAllNotifications() async {
    await initNotification();
    await _plugin.cancelAll();
  }
}
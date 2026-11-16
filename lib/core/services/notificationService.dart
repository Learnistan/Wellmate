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

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isInitialized = true;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'wellmate_channel',
      'Wellmate Notifications',
      channelDescription: 'Wellmate reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  Future<void> showInstantNotification() async {
    await initNotification();

    await _plugin.show(
      id: 1,
      title: 'Instant notification',
      body: 'Instant notification works',
      notificationDetails: _details,
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

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String message,
    required int hour,
    required int minute,
  }) async {
    await initNotification();

    await _plugin.cancel(id: id);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: message,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) async {
    await initNotification();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await initNotification();
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
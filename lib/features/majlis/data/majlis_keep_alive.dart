import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps a space playing while the screen is off or another app is open.
///
/// Without it, Android freezes the app about 10 seconds after it leaves the
/// screen and the voice connection drops. On Android this runs a small
/// foreground service with a quiet notification ("You are in Majlis" and a
/// Leave button). iOS needs nothing here: the `audio` background mode in
/// Info.plist does the same job.
abstract class MajlisKeepAlive {
  Future<void> start({required String title, required String body, String? leaveLabel});
  Future<void> stop();

  /// "Leave" was tapped in the notification. Hosts get no button: ending a
  /// space for everyone needs the app open and a confirmation.
  Stream<void> get leaveTaps;
}

class ForegroundServiceKeepAlive implements MajlisKeepAlive {
  /// The manifest `meta-data` name that points at the small notification
  /// icon (@drawable/ic_stat_majlis).
  static const notificationIconMetaData = 'com.learnistan.wellmate.majlis.NOTIFICATION_ICON';

  static final _leave = StreamController<void>.broadcast();
  static bool _ready = false;

  @override
  Stream<void> get leaveTaps => _leave.stream;

  static void _onData(Object data) {
    if (data == 'leave') _leave.add(null);
  }

  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> start({required String title, required String body, String? leaveLabel}) async {
    if (!_android) return;
    try {
      if (!_ready) {
        FlutterForegroundTask.initCommunicationPort();
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'majlis_space',
            channelName: 'Majlis',
            channelDescription: 'Shown while you are in a Majlis space',
            // Default importance keeps it out of "Silent", so the Leave button
            // shows without expanding. No sound, no vibration.
            channelImportance: NotificationChannelImportance.DEFAULT,
            priority: NotificationPriority.DEFAULT,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            // Nothing about the space on the lock screen.
            visibility: NotificationVisibility.VISIBILITY_PRIVATE,
          ),
          iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.nothing(),
            autoRunOnBoot: false,
            autoRunOnMyPackageReplaced: false,
            allowWakeLock: true,
            allowWifiLock: true,
          ),
        );
        FlutterForegroundTask.addTaskDataCallback(_onData);
        _ready = true;
      }
      // Android 13+: without this the service still runs, but the
      // notification (and its Leave button) stays hidden.
      if (await FlutterForegroundTask.checkNotificationPermission() != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      final buttons = [if (leaveLabel != null) NotificationButton(id: 'leave', text: leaveLabel)];
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: body,
          notificationButtons: buttons,
          notificationIcon: const NotificationIcon(metaDataName: notificationIconMetaData),
        );
      } else {
        await FlutterForegroundTask.startService(
          serviceId: 4417,
          serviceTypes: [ForegroundServiceTypes.mediaPlayback],
          notificationTitle: title,
          notificationText: body,
          notificationButtons: buttons,
          // White tea-glass icon from the manifest (see INTEGRATION.md).
          notificationIcon: const NotificationIcon(metaDataName: notificationIconMetaData),
          callback: majlisKeepAliveCallback,
        );
      }
    } catch (e) {
      debugPrint('Majlis keep-alive failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_android) return;
    try {
      if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('Majlis keep-alive stop failed: $e');
    }
  }
}

@pragma('vm:entry-point')
void majlisKeepAliveCallback() => FlutterForegroundTask.setTaskHandler(_MajlisTaskHandler());

class _MajlisTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) => FlutterForegroundTask.sendDataToMain(id);

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}

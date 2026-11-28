import 'package:flutter/foundation.dart';

/// Short trace lines for testing: what the room did and why (toasts, mic,
/// stage, leaving, reconnects). Off unless the app is built with
/// --dart-define=MAJLIS_TRACE=true. Read them with:
///   adb logcat -s flutter | grep MAJLIS-TRACE
const bool majlisTraceOn = bool.fromEnvironment('MAJLIS_TRACE');

void majlisTrace(String message) {
  if (majlisTraceOn) debugPrint('MAJLIS-TRACE $message');
}

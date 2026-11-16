import 'dart:math';

import '../../l10n/app_localizations.dart';

class NotificationMessages {
  static ({String body}) random(AppLocalizations loc) {
    final messages = [
      (
      body: loc.notificationMessage1,
      ),
      (
      body: loc.notificationMessage2,
      ),
      (
      body: loc.notificationMessage3,
      ),
      (
      body: loc.notificationMessage4,
      ),
      (
      body: loc.notificationMessage5,
      ),
    ];

    return messages[Random().nextInt(messages.length)];
  }
}
import 'package:flutter/widgets.dart';

import 'data/majlis_keep_alive.dart';
import 'domain/majlis_models.dart';
import 'domain/majlis_repository.dart';
import 'domain/majlis_voice.dart';

/// How WellMate plugs into Majlis. Everything is optional; Majlis works
/// with defaults (Firebase + LiveKit) and hides what isn't provided.
class MajlisConfig {
  const MajlisConfig({
    this.repository,
    this.voice,
    this.onOpenChat,
    this.onMoodAfterSpace,
    this.onSpaceVisited,
    this.reminders,
    this.keepAlive,
    this.helplines = const [],
    this.inviteLinkBase,
  });

  /// Defaults to FirebaseMajlisRepository.
  final MajlisRepository? repository;

  /// Defaults to LiveKitMajlisVoice.
  final MajlisVoice Function()? voice;

  /// Help sheet → "Talk to WellMate". Hidden when null.
  final void Function(BuildContext context)? onOpenChat;

  /// Called once the after-sheet has closed, with the feeling picked there:
  /// 0 Calm, 1 Good, 2 Tired, 3 Anxious, 4 Sad. Not called if none was picked.
  final void Function(BuildContext context, int mood)? onMoodAfterSpace;

  /// Called after each visit. Return true if it counted as today's journey
  /// step, and the after-sheet says so. Return false or leave null to hide it.
  final Future<bool> Function(MajlisLeaveResult result)? onSpaceVisited;

  /// "Remind me" on scheduled spaces. Without it, Remind me still counts
  /// you as going but no notification is scheduled.
  final MajlisReminders? reminders;

  /// Keeps listening going with the screen off. Defaults to an Android
  /// foreground service (ForegroundServiceKeepAlive); iOS uses background audio.
  final MajlisKeepAlive? keepAlive;

  /// Shown in the Help sheet. Empty hides the row.
  final List<MajlisHelpline> helplines;

  /// Adds a link to copied invites, e.g. 'https://wellmate.app/majlis/'
  /// (the code is added at the end). Leave null until the link opens the app
  /// (see INTEGRATION.md, "Invite links"); invites then carry the code only.
  final String? inviteLinkBase;

  /// The text people copy to invite someone to an invite-only space.
  String inviteMessage(String text, String code) =>
      inviteLinkBase == null ? text : '$text\n$inviteLinkBase$code';
}

/// Wire this to WellMate's NotificationService (flutter_local_notifications).
abstract class MajlisReminders {
  /// Schedule a notification 10 minutes before [space] starts.
  Future<void> schedule(MajlisSpace space, {required String title, required String body});
  Future<void> cancel(String spaceId);
}

class MajlisHelpline {
  final String name;
  final String phone;
  final String? note;
  const MajlisHelpline({required this.name, required this.phone, this.note});
}

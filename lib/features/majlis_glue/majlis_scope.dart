import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, Consumer;
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wellmate/core/utils/timeUtils.dart';
import 'package:wellmate/features/home/presentation/providers/homeProvider.dart';
import 'package:wellmate/features/majlis/data/firebase_majlis_repository.dart';
import 'package:wellmate/features/majlis/majlis.dart';
import 'package:wellmate/features/majlis/presentation/controllers/majlis_hallway_controller.dart';
import 'package:wellmate/features/shell/presentation/navigationProvider.dart';

import 'wellmate_majlis_reminders.dart';

/// Majlis inside WellMate.
///
/// One Majlis hallway lives for as long as the signed-in shell does. The
/// Majlis tab, the Home card and the nav-bar icon all read it, so the app
/// keeps a single set of Firestore listeners.
///
/// How Majlis ties into the rest of WellMate:
/// - It is the middle tab ([tabIndex]).
/// - Home shows who is talking now and opens a space in one tap.
/// - Feeling tired, anxious or sad on Home offers "Sit with others".
/// - A real visit counts as the day's journey step.
/// - A low feeling after a visit offers the matching WellMate activity.
/// - Help → "Talk to WellMate" opens the AI chat.
/// - "Remind me" uses WellMate's notifications.
class MajlisScope extends ConsumerStatefulWidget {
  const MajlisScope({super.key, required this.child});

  final Widget child;

  /// Majlis is the middle of the five tabs.
  static const tabIndex = 2;

  /// The scope, rebuilding the caller whenever the hallway changes
  /// (live spaces, counts, your profile).
  static MajlisScopeState? watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MajlisInherited>()?.state;

  /// The scope, without rebuilding the caller. Use in callbacks.
  static MajlisScopeState? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MajlisInherited>()?.state;

  @override
  ConsumerState<MajlisScope> createState() => MajlisScopeState();
}

/// Set by Majlis after a visit when the person feels tired (2), anxious (3)
/// or sad (4). Home listens and offers the same activity it would offer for
/// that feeling.
final majlisFeelingProvider = StateProvider<int?>((ref) => null);

/// Set when a Majlis visit moved the journey on. Home replays that step of
/// the journey video the next time it is shown, so the person sees it.
final majlisJourneyStepProvider = StateProvider<bool>((ref) => false);

class MajlisScopeState extends ConsumerState<MajlisScope> {
  late final MajlisConfig config;
  late final MajlisHallway hallway;

  /// A space the Home card asked to open; the Majlis tab handles it.
  final openSpace = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    config = MajlisConfig(
      onOpenChat: (ctx) => ctx.push('/chat'),
      onSpaceVisited: _countJourneyStep,
      onMoodAfterSpace: (_, mood) {
        if (mood >= 2) ref.read(majlisFeelingProvider.notifier).state = mood;
      },
      reminders: WellMateMajlisReminders(context.read<HomeProvider>().notificationService),
      // Helplines are added once the team has approved the numbers.
      helplines: const [],
      // Invite links need wellmate.app/majlis/CODE to open the app first;
      // until then invites carry the code only.
      inviteLinkBase: null,
    );
    hallway = MajlisHallway(repo: FirebaseMajlisRepository(), config: config);
  }

  @override
  void dispose() {
    hallway.dispose();
    openSpace.dispose();
    super.dispose();
  }

  /// Shows the Majlis tab.
  void openTab() => ref.read(navigationIndexProvider.notifier).state = MajlisScope.tabIndex;

  /// Shows the Majlis tab and opens [spaceId] there (live: joins it;
  /// scheduled: shows its details with Remind me).
  void open(String spaceId) {
    openTab();
    openSpace.value = spaceId;
  }

  /// A visit counts as today's journey step when the person stayed at least
  /// 5 minutes, or spoke or hosted for at least 2. Same rule as finishing an
  /// activity: one step a day.
  Future<bool> _countJourneyStep(MajlisLeaveResult r) async {
    final enough = r.sat >= const Duration(minutes: 5) ||
        ((r.spoke || r.hosted) && r.sat >= const Duration(minutes: 2));
    if (!enough || !mounted) return false;
    try {
      final home = context.read<HomeProvider>();
      await home.loadLevel();
      final before = home.level;
      final last = home.lastDate;
      final doneToday = last != null && last.isNotEmpty && TimeUtils().calculateDayDifference(last) == 0;
      if (doneToday && before != 0) return false;
      await home.increaseLevel();
      final moved = home.level > before;
      if (moved && mounted) ref.read(majlisJourneyStepProvider.notifier).state = true;
      return moved;
    } catch (e) {
      debugPrint('Majlis journey step failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => _MajlisInherited(state: this, child: widget.child);
}

class _MajlisInherited extends InheritedNotifier<MajlisHallway> {
  _MajlisInherited({required this.state, required super.child}) : super(notifier: state.hallway);

  final MajlisScopeState state;
}

/// The Majlis tab in MainShell.
class MajlisTab extends StatelessWidget {
  const MajlisTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = MajlisScope.read(context)!;
    return MajlisPage(
      config: scope.config,
      hallway: scope.hallway,
      openSpace: scope.openSpace,
    );
  }
}

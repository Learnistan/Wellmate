import 'package:flutter/material.dart';

import '../../data/firebase_majlis_repository.dart';
import '../../data/majlis_catalog.dart';
import '../../domain/majlis_models.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_config.dart';
import '../../majlis_theme.dart';
import '../../majlis_trace.dart';
import '../controllers/majlis_hallway_controller.dart';
import '../widgets/majlis_avatar.dart';
import '../widgets/majlis_bits.dart';
import '../widgets/majlis_logo.dart';
import '../widgets/space_card.dart';
import 'majlis_room_page.dart';
import 'majlis_sheets.dart';

/// The Majlis tab. Put it in WellMate's MainShell; it needs a signed-in
/// Firebase user (WellMate's router already guarantees that).
class MajlisPage extends StatefulWidget {
  const MajlisPage({
    super.key,
    this.config = const MajlisConfig(),
    this.bottomInset = 78,
    this.inviteCode,
    this.hallway,
    this.openSpace,
  });

  final MajlisConfig config;

  /// A hallway shared with the rest of the app (WellMate's Home card and nav
  /// bar read the same live list). When null, the page makes and owns one.
  final MajlisHallway? hallway;

  /// Set its value to a space id to open that space (for example from
  /// WellMate's Home card). The page sets it back to null once handled.
  final ValueNotifier<String?>? openSpace;

  /// An invite code from a link (wellmate.app/majlis/CODE). When it is set or
  /// changes, Majlis joins that space as soon as the page is on screen.
  final String? inviteCode;

  /// Space under the content for the curved nav bar.
  final double bottomInset;

  @override
  State<MajlisPage> createState() => _MajlisPageState();
}

class _MajlisPageState extends State<MajlisPage> {
  late final bool _ownsHall = widget.hallway == null;
  late final MajlisHallway hall = widget.hallway ??
      MajlisHallway(
        repo: widget.config.repository ?? FirebaseMajlisRepository(),
        config: widget.config,
      );
  String topic = 'all';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _openInvite(widget.inviteCode);
    widget.openSpace?.addListener(_openRequested);
    _openRequested();
  }

  /// Opens the space WellMate asked for, once spaces have loaded.
  void _openRequested() {
    final id = widget.openSpace?.value;
    if (id == null) return;
    void go() {
      if (!mounted || !hall.profileLoaded || !hall.spacesLoaded) return;
      hall.removeListener(go);
      if (widget.openSpace?.value != id) return;
      widget.openSpace?.value = null;
      final space = [...hall.live, ...hall.scheduled].where((s) => s.id == id).firstOrNull;
      if (space == null) return;
      space.isLive ? _enter(space.id, space: space) : _openEvent(space);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      hall.profileLoaded && hall.spacesLoaded ? go() : hall.addListener(go);
    });
  }

  @override
  void didUpdateWidget(MajlisPage old) {
    super.didUpdateWidget(old);
    if (widget.openSpace != old.openSpace) {
      old.openSpace?.removeListener(_openRequested);
      widget.openSpace?.addListener(_openRequested);
    }
    if (widget.inviteCode != old.inviteCode) _openInvite(widget.inviteCode);
  }

  /// Codes are 6 letters from the server's alphabet; anything else is ignored.
  void _openInvite(String? raw) {
    final code = raw?.trim().toUpperCase();
    if (code == null || !RegExp(r'^[A-Z2-9]{6}$').hasMatch(code)) return;
    // Wait for the profile, so a returning person is not asked for a veil.
    void go() {
      if (!mounted || !hall.profileLoaded) return;
      hall.removeListener(go);
      _joinByCode(code: code);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      hall.profileLoaded ? go() : hall.addListener(go);
    });
  }

  @override
  void dispose() {
    widget.openSpace?.removeListener(_openRequested);
    if (_ownsHall) hall.dispose();
    super.dispose();
  }

  Future<bool> _ensureVeil() async {
    if (hall.hasVeil) return true;
    final ok = await showVeilSheet(context, hall);
    return ok == true && mounted && hall.hasVeil;
  }

  Future<void> _guard(Future<void> Function() fn) async {
    if (_busy) return;
    _busy = true;
    try {
      await fn();
    } on MajlisException catch (e) {
      if (mounted) _snack(Icons.info_outline_rounded, MajlisStrings.of(context).error(e.code));
    } catch (e) {
      debugPrint('Majlis: $e');
      if (mounted) _snack(Icons.info_outline_rounded, MajlisStrings.of(context).error('generic'));
    } finally {
      _busy = false;
    }
  }

  Future<void> _enter(String spaceId, {MajlisSpace? space}) async {
    if (!await _ensureVeil() || !mounted) return;
    if (space != null &&
        space.audience == MajlisAudience.women &&
        !hall.isMine(space) &&
        hall.profile?.womenSpaces != true) {
      final yes = await showWomenSheet(context);
      if (yes != true || !mounted) return;
      await hall.confirmWomen();
    }
    if (!mounted) return;
    final result = await Navigator.of(context, rootNavigator: true).push<MajlisLeaveResult>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => MajlisRoomPage(hall: hall, spaceId: spaceId, initial: space),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(anim),
          child: child,
        ),
      ),
    );
    majlisTrace('back in hallway: result=${result != null}, mounted=$mounted, '
        'sat=${result?.sat.inSeconds}s, reason=${result?.reason}');
    if (result == null || !mounted) return;
    final l = MajlisStrings.of(context);
    if (result.reason != null && result.reason != 'women-confirm') {
      _snack(Icons.nightlight_round, l.t(result.reason!));
    }
    if (result.sat.inSeconds < 5) return;
    final journey = await widget.config.onSpaceVisited?.call(result) ?? false;
    if (!mounted) return;
    final mood = await showAfterSheet(context, result, hall.config, journeyDone: journey);
    if (mood != null && mounted) widget.config.onMoodAfterSpace?.call(context, mood);
  }

  Future<void> _start() async {
    if (!await _ensureVeil() || !mounted) return;
    final mineLive = hall.myLiveSpace;
    if (mineLive != null) return _enter(mineLive.id, space: mineLive);
    final made = await showStartSpaceSheet(context, hall);
    if (!mounted || made == null) return;
    if (made.startsAt == null) {
      await _enter(made.spaceId);
    } else {
      final l = MajlisStrings.of(context);
      _snack(Icons.event_available_rounded, l.t('scheduledToast', {'when': l.when(made.startsAt!)}));
    }
  }

  Future<void> _openEvent(MajlisSpace s) async {
    final action = await showEventSheet(context, hall, s);
    if (!mounted || action == null) return;
    final l = MajlisStrings.of(context);
    switch (action) {
      case EventAction.start:
        await _guard(() async {
          await hall.repo.host(s.id, 'start');
          _busy = false;
          await _enter(s.id);
        });
      case EventAction.cancelled:
        _snack(Icons.event_busy_rounded, l.t('spaceCancelled'));
      case EventAction.shared:
        _snack(Icons.link_rounded, l.t('inviteCopied'));
    }
  }

  Future<void> _remind(MajlisSpace s) async {
    if (hall.isMine(s)) return _openEvent(s);
    final on = !hall.going.contains(s.id);
    final l = MajlisStrings.of(context);
    await _guard(() async {
      await hall.remind(s, on, l);
      if (on && mounted) {
        _snack(Icons.notifications_active_rounded, l.t(hall.config.reminders != null ? 'reminderSet' : 'goingSet'));
      }
    });
  }

  Future<void> _joinByCode({String? code}) async {
    if (!await _ensureVeil() || !mounted) return;
    code ??= await showCodeSheet(context);
    if (code == null || !mounted) return;
    await _guard(() async {
      final j = await hall.repo.join(code: code);
      final space = await hall.repo.watchSpace(j.spaceId).first;
      _busy = false;
      if (!mounted || space == null) return;
      if (space.isScheduled) {
        await _openEvent(space);
      } else {
        await _enter(space.id, space: space);
      }
    });
  }

  void _snack(IconData icon, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: MajlisColors.ink,
          margin: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomInset + 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Row(
            children: [
              Icon(icon, color: MajlisColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: MajlisText.body(14, color: MajlisColors.cream, weight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    return ListenableBuilder(
      listenable: hall,
      builder: (context, _) {
        final spaces = hall.live.where((s) => topic == 'all' || s.topicId == topic).toList();
        final events = hall.scheduled.where((s) => topic == 'all' || s.topicId == topic).toList();
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 240,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [MajlisColors.blush, MajlisColors.cream],
                  ),
                ),
                child: CustomPaint(painter: GirihPainter(opacity: 0.16)),
              ),
            ),
            RefreshIndicator(
              color: MajlisColors.roseDeep,
              onRefresh: () async => hall.retry(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header(l)),
                  SliverToBoxAdapter(child: _topics(l)),
                  if (hall.offline) SliverToBoxAdapter(child: _offline(l)),
                  if (events.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionTitle(
                        title: l.t('startingSoon'),
                        trailing: Text(l.t('scheduledN', {'n': events.length}),
                            style: MajlisText.body(13, color: MajlisColors.muted)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        // Grows with the phone's text size (two-line titles).
                        height: 26 + (MajlisText.arabicScript ? 84 : 76) * MajlisText.grow(context),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: events.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) => EventCard(
                            space: events[i],
                            mine: hall.isMine(events[i]),
                            going: hall.going.contains(events[i].id),
                            onTap: () => _openEvent(events[i]),
                            onRemind: () => _remind(events[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: SectionTitle(
                      title: l.t('liveNow'),
                      leading: const LiveDot(),
                      trailing: Text(l.count(spaces.length, 'spaceOne', 'spaces'),
                          style: MajlisText.body(13, color: MajlisColors.muted)),
                    ),
                  ),
                  if (!hall.spacesLoaded && !hall.offline)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(color: MajlisColors.roseDeep, strokeWidth: 2.5)),
                      ),
                    )
                  else if (spaces.isEmpty)
                    SliverToBoxAdapter(child: _empty(l))
                  else
                    SliverList.builder(
                      itemCount: spaces.length,
                      itemBuilder: (context, i) => SpaceCard(
                        key: ValueKey(spaces[i].id),
                        space: spaces[i],
                        mine: hall.isMine(spaces[i]),
                        onTap: () => _enter(spaces[i].id, space: spaces[i]),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _joinByCode,
                        style: TextButton.styleFrom(foregroundColor: MajlisColors.roseDeep),
                        icon: const Icon(Icons.key_rounded, size: 18),
                        label: Text(l.t('haveCode'),
                            style: MajlisText.body(14, color: MajlisColors.roseDeep, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: widget.bottomInset + 90)),
                ],
              ),
            ),
            PositionedDirectional(
              end: 18,
              bottom: widget.bottomInset + 14,
              child: _StartButton(label: l.t('startSpace'), onTap: _start),
            ),
          ],
        );
      },
    );
  }

  Widget _header(MajlisStrings l) {
    final me = hall.me;
    final people = hall.peopleNow;
    final count = hall.live.length;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 6, bottom: 2),
                      child: MajlisLogo(size: 42),
                    ),
                    Text(l.t('majlis'), style: MajlisText.head(36, height: 1, spacing: -0.6)),
                    if (!l.rtl) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('مجلس',
                            style: MajlisText.body(19, color: MajlisColors.roseText, weight: FontWeight.w600, height: 1)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(l.t('tagline'), style: MajlisText.body(14, color: MajlisColors.muted)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 12, 2),
                  decoration: BoxDecoration(
                    color: MajlisColors.paper.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: MajlisColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0) const LiveDot(size: 7) else const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          count > 0
                              ? l.t('peopleNow', {'people': l.count(people, 'personOne', 'peopleN'), 'spaces': l.count(count, 'spaceOne', 'spacesIn')})
                              : l.t('quietNow'),
                          style: MajlisText.body(12.5, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: l.t('profileTip'),
            child: GestureDetector(
              onTap: () async {
                if (await _ensureVeil() && mounted) await showProfileSheet(context, hall);
              },
              child: me == null
                  ? Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: MajlisColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: MajlisColors.line),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: MajlisColors.roseDeep),
                    )
                  : MajlisAvatar(person: me, size: 54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topics(MajlisStrings l) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
        itemCount: MajlisCatalog.topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = MajlisCatalog.topics[i];
          final on = topic == t.id;
          return GestureDetector(
            onTap: () => setState(() => topic = t.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsetsDirectional.fromSTEB(t.id == 'all' ? 16 : 12, 0, 16, 0),
              decoration: BoxDecoration(
                color: on ? MajlisColors.ink : MajlisColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? MajlisColors.ink : MajlisColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t.id != 'all') ...[
                    Icon(t.icon, size: 17, color: on ? MajlisColors.gold : t.jewel.deep),
                    const SizedBox(width: 6),
                  ],
                  Text(l.topic(t.id),
                      style: MajlisText.body(14, color: on ? MajlisColors.cream : MajlisColors.ink, weight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _offline(MajlisStrings l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 8, 8),
        decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: MajlisColors.roseDeep, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(l.t('offline'), style: MajlisText.body(13.5, weight: FontWeight.w500))),
            TextButton(onPressed: hall.retry, child: Text(l.t('tryAgain'))),
          ],
        ),
      ),
    );
  }

  Widget _empty(MajlisStrings l) {
    final t = MajlisCatalog.topic(topic == 'all' ? 'chai' : topic);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: t.jewel.light, borderRadius: BorderRadius.circular(26)),
        child: Column(
          children: [
            TopicBadge(topic: t, size: 52),
            const SizedBox(height: 12),
            Text(l.t('emptyTitle'), textAlign: TextAlign.center, style: MajlisText.head(20, color: t.jewel.deep)),
            const SizedBox(height: 4),
            Text(l.t('emptyBody'), textAlign: TextAlign.center, style: MajlisText.body(14, color: t.jewel.deep)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(backgroundColor: MajlisColors.ink, foregroundColor: MajlisColors.cream),
              child: Text(l.t('startSpace'), style: MajlisText.body(14.5, color: MajlisColors.cream, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MajlisColors.roseDeep,
      elevation: 6,
      shadowColor: MajlisColors.plum.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 22, 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: MajlisText.body(15.5, color: Colors.white, weight: FontWeight.w700, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

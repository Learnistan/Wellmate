import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/livekit_majlis_voice.dart';
import '../../data/majlis_keep_alive.dart';
import '../../data/majlis_catalog.dart';
import '../../domain/majlis_models.dart';
import '../../domain/majlis_voice.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_theme.dart';
import '../../majlis_trace.dart';
import '../controllers/majlis_hallway_controller.dart';
import '../controllers/majlis_room_controller.dart';
import '../widgets/majlis_avatar.dart';
import '../widgets/majlis_bits.dart';
import 'majlis_sheets.dart';

class MajlisRoomPage extends StatefulWidget {
  const MajlisRoomPage({super.key, required this.hall, required this.spaceId, this.initial});
  final MajlisHallway hall;
  final String spaceId;
  final MajlisSpace? initial;

  @override
  State<MajlisRoomPage> createState() => _MajlisRoomPageState();
}

class _MajlisRoomPageState extends State<MajlisRoomPage> {
  late final MajlisRoomController c = MajlisRoomController(
    repo: widget.hall.repo,
    voice: widget.hall.config.voice?.call() ?? LiveKitMajlisVoice(),
    spaceId: widget.spaceId,
    me: widget.hall.me!,
    space: widget.initial,
    config: widget.hall.config,
    blocked: widget.hall.blocked,
  );
  bool tray = false;
  bool _left = false;
  late final MajlisKeepAlive _keepAlive = widget.hall.config.keepAlive ?? ForegroundServiceKeepAlive();
  StreamSubscription<void>? _leaveTaps;
  bool _keptAlive = false;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
    c.start();
  }

  @override
  void dispose() {
    _leaveTaps?.cancel();
    if (_keptAlive) _keepAlive.stop();
    c.removeListener(_onChange);
    c.dispose();
    super.dispose();
  }

  void _onChange() {
    if (c.phase == MajlisRoomPhase.live && !_keptAlive && mounted) {
      // Keep listening with the screen off (Android foreground service).
      _keptAlive = true;
      final l = MajlisStrings.of(context);
      _keepAlive.start(title: l.t('inMajlis'), body: l.t('inMajlisBody'), leaveLabel: c.isHost ? null : l.t('leave'));
      _leaveTaps = _keepAlive.leaveTaps.listen((_) => _leave(from: 'notification'));
    }
    if (c.phase == MajlisRoomPhase.closed && _keptAlive) {
      _keptAlive = false;
      _keepAlive.stop();
    }
    if (c.phase == MajlisRoomPhase.closed && !_left) {
      _left = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(c.leaveResult());
      });
    }
  }

  Future<void> _leave({String from = 'button'}) async {
    majlisTrace('tap: leave ($from)');
    if (_left) return;
    if (c.phase != MajlisRoomPhase.live) {
      _left = true;
      Navigator.of(context).pop(c.phase == MajlisRoomPhase.failed ? null : c.leaveResult());
      return;
    }
    if (c.isHost) {
      final l = MajlisStrings.of(context);
      final yes = await showConfirm(context, title: l.t('endQ'), body: l.t('endBody'), yes: l.t('endSpace'), no: l.t('stay'));
      if (yes) await c.endSpace();
      return;
    }
    await c.leave();
  }

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final topSafe = MediaQuery.paddingOf(context).top;
    const barHeight = 78.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave(from: 'back');
        },
        child: Scaffold(
          backgroundColor: MajlisColors.cream,
          body: ListenableBuilder(
            listenable: c,
            builder: (context, _) {
              if (c.phase == MajlisRoomPhase.failed) return _failed(l);
              final topic = MajlisCatalog.topic(c.space?.topicId ?? widget.initial?.topicId ?? 'chai');
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 260,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [topic.jewel.light, MajlisColors.cream],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: GirihPainter(opacity: 0.1))),
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _topBar(l),
                        _banner(l),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(16, 2, 16, barHeight + bottomSafe + 96),
                            children: [_header(l), _pinned(l), _stage(l), _listeners(l)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: FloatingReactions(
                      bottom: barHeight + bottomSafe + 8,
                      items: [for (final r in c.reactions) (id: r.id, kind: r.kind, x: r.x, mine: r.mine)],
                    ),
                  ),
                  Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar(l, bottomSafe)),
                  PositionedDirectional(end: 12, bottom: barHeight + bottomSafe + 10, child: _tray(l)),
                  Positioned(left: 12, right: 12, bottom: barHeight + bottomSafe + 12, child: _prompt(l)),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: topSafe + 58,
                    child: Center(child: _toast(l)),
                  ),
                  if (c.phase == MajlisRoomPhase.joining) _joining(l),
                  if (c.breathing)
                    Positioned.fill(
                      child: BreatheTogether(people: c.breathingTogether ? c.peopleCount : null, onDone: c.stopBreathing),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- States -------------------------------------------------------------

  Widget _joining(MajlisStrings l) => Positioned.fill(
    child: ColoredBox(
      color: MajlisColors.cream.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MajlisAvatar(person: c.me, size: 84, speaking: true),
            const SizedBox(height: 18),
            Text(l.t('takingSeat'), style: MajlisText.head(20)),
          ],
        ),
      ),
    ),
  );

  Widget _failed(MajlisStrings l) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: MajlisColors.blush, shape: BoxShape.circle),
              child: const Icon(Icons.nightlight_round, size: 34, color: MajlisColors.roseDeep),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.error(c.error ?? 'generic'), textAlign: TextAlign.center, style: MajlisText.head(22)),
          const SizedBox(height: 22),
          if (c.error == 'sound' || c.error == 'network') ...[
            FilledButton(
              onPressed: c.retry,
              style: FilledButton.styleFrom(backgroundColor: MajlisColors.roseDeep, shape: const StadiumBorder()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  l.t('tryAgain'),
                  style: MajlisText.body(15, color: Colors.white, weight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: _leave,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: const BorderSide(color: MajlisColors.line),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(l.t('backToHallway'), style: MajlisText.body(15, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _banner(MajlisStrings l) {
    String? text;
    IconData icon = Icons.wifi_rounded;
    VoidCallback? onTap;
    if (c.reconnecting) {
      text = l.t('reconnecting');
      icon = Icons.wifi_off_rounded;
    } else if (c.phase == MajlisRoomPhase.live && !c.canPlayAudio) {
      text = l.t('tapToHear');
      icon = Icons.volume_up_rounded;
      onTap = c.startAudio;
    } else if (c.hostAway) {
      text = l.t('hostAway');
      icon = Icons.hourglass_bottom_rounded;
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: text == null
          ? const SizedBox(width: double.infinity)
          : GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: MajlisColors.ink, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: MajlisColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: MajlisText.body(13.5, color: MajlisColors.cream, weight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---- Top ----------------------------------------------------------------

  Widget _topBar(MajlisStrings l) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 12, 2),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _leave,
            style: TextButton.styleFrom(foregroundColor: MajlisColors.ink),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            label: Text(l.t('hallway'), style: MajlisText.body(15, weight: FontWeight.w600)),
          ),
          const Spacer(),
          if (c.linkQuality == MajlisLinkQuality.weak) ...[
            Tooltip(
              message: l.t('weakLink'),
              child: Semantics(
                label: l.t('weakLink'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: MajlisColors.saffronSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.signal_cellular_alt_1_bar_rounded, size: 20, color: MajlisColors.saffron),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Material(
            color: const Color(0xFFF7E3E5),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => showHelpSheet(context, c, widget.hall.config),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 11, 14, 11),
                child: Row(
                  children: [
                    Icon(Icons.support_rounded, size: 19, color: MajlisJewels.pomegranate.deep),
                    const SizedBox(width: 6),
                    Text(
                      l.t('help'),
                      style: MajlisText.body(14, color: MajlisJewels.pomegranate.deep, weight: FontWeight.w700, height: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RoundButton(
            tooltip: c.isHost ? l.t('hostTools') : l.t('more'),
            color: MajlisColors.paper,
            onTap: () => c.isHost ? showHostToolsSheet(context, c) : showRoomMenuSheet(context, c, widget.hall),
            child: Badge(
              isLabelVisible: c.isHost && (c.hands.isNotEmpty || c.whispers.any((w) => !w.pinned)),
              backgroundColor: MajlisColors.gold,
              smallSize: 9,
              child: const Icon(Icons.more_horiz_rounded, color: MajlisColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(MajlisStrings l) {
    final s = c.space ?? widget.initial;
    if (s == null) return const SizedBox(height: 80);
    final t = MajlisCatalog.topic(s.topicId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MajlisChip(text: l.topic(t.id), icon: t.icon, bg: t.jewel.deep, fg: Colors.white),
              MajlisChip(text: l.langName(s.lang), border: MajlisColors.line),
              if (s.audience == MajlisAudience.women)
                MajlisChip(text: l.t('womenOnly'), icon: Icons.female_rounded, border: MajlisColors.line),
              if (s.audience == MajlisAudience.invite)
                MajlisChip(text: l.t('inviteOnly'), icon: Icons.lock_outline_rounded, border: MajlisColors.line),
              MajlisChip(
                text: l.t('notRecorded'),
                icon: Icons.lock_outline_rounded,
                fg: MajlisColors.muted,
                border: MajlisColors.line,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.title, style: MajlisText.head(27, height: 1.18, spacing: -0.5)),
        ],
      ),
    );
  }

  Widget _pinned(MajlisStrings l) {
    final text = c.pinned;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, a) => SizeTransition(
        sizeFactor: a,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: text == null
          ? const SizedBox.shrink(key: ValueKey('no-pin'))
          : Container(
              key: ValueKey(text),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              decoration: BoxDecoration(
                color: MajlisColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MajlisColors.gold, width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: MajlisColors.goldSoft, shape: BoxShape.circle),
                    child: Icon(
                      c.pinnedIsWhisper ? Icons.mail_lock_rounded : Icons.push_pin_rounded,
                      size: 18,
                      color: const Color(0xFF8A6420),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MajlisText.caps(c.pinnedIsWhisper ? l.t('whisperEyebrow') : l.t('onTheCarpet')),
                          style: MajlisText.eyebrow(),
                        ),
                        const SizedBox(height: 4),
                        Text(text, style: MajlisText.head(17.5, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---- Stage --------------------------------------------------------------

  Widget _stage(MajlisStrings l) {
    final speaking = c.speaking;
    final stage = c.stage;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
      decoration: BoxDecoration(
        color: MajlisColors.paper,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: MajlisColors.plum.withValues(alpha: 0.07), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Icon(Icons.mic_none_rounded, size: 19, color: MajlisColors.roseDeep),
                const SizedBox(width: 6),
                Text(l.t('onStage'), style: MajlisText.head(17)),
                if (c.turns) ...[
                  const SizedBox(width: 8),
                  MajlisChip(
                    text: l.t('turnsChip'),
                    icon: Icons.timer_outlined,
                    bg: MajlisColors.goldSoft,
                    fg: const Color(0xFF7A5418),
                    size: 11.5,
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      // Only the new label: two crossfading labels overlapped.
                      layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
                      child: speaking == null
                          ? Text(
                              c.isHost && stage.length <= 1 ? l.t('saySalaam') : l.t('quietMoment'),
                              key: const ValueKey('quiet'),
                              style: MajlisText.body(13, color: MajlisColors.muted),
                            )
                          : Row(
                              key: ValueKey(speaking.id),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SoundBars(),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    speaking.isLocal
                                        ? l.t('youreSpeaking')
                                        : l.t('isSpeaking', {'name': l.name(speaking.person)}),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: MajlisText.body(13, color: MajlisColors.muted, weight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth / 3;
              return Wrap(
                runSpacing: 18,
                children: [for (final p in stage) SizedBox(key: ValueKey('stage-${p.id}'), width: w, child: _speakerTile(l, p))],
              );
            },
          ),
          if (c.isHost && c.turns && stage.length > 1)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: c.nextTurn,
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: Text(
                  l.t('nextVoice'),
                  style: MajlisText.body(13.5, color: MajlisColors.roseDeep, weight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(foregroundColor: MajlisColors.roseDeep),
              ),
            ),
        ],
      ),
    );
  }

  Widget _speakerTile(MajlisStrings l, MajlisVoicePeer peer) {
    final p = peer.person;
    final isMe = peer.isLocal;
    final isHost = peer.id == c.hostUid;
    final mutedForMe = c.mutedForMe.contains(peer.id);
    final muted = !peer.micOn;
    final turn = c.turn;
    final myTurn = turn != null && turn.uid == peer.id;
    const size = 76.0;
    return GestureDetector(
      onTap: () => showPersonSheet(context, c, p),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: size + 14,
            height: size + 14,
            child: Center(
              child: MajlisAvatar(
                person: p,
                size: size,
                speaking: peer.speaking && !mutedForMe,
                muted: muted,
                mutedForMe: mutedForMe,
                host: isHost,
                tea: isMe ? c.teaForMe : (c.tea[p.id] ?? 0),
                popIn: true,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? l.t('you') : l.name(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: MajlisText.body(13, weight: FontWeight.w700),
          ),
          if (p.isGuide)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 13, color: MajlisColors.gold),
                const SizedBox(width: 3),
                // Shrinks a little rather than cut the badge with large text.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l.t('guide'),
                      maxLines: 1,
                      style: MajlisText.body(11, color: MajlisColors.roseText, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            )
          else if (isHost)
            Text(
              l.t('host'),
              style: MajlisText.body(11.5, color: MajlisColors.roseText, weight: FontWeight.w700),
            ),
          if (myTurn && turn.startedAt != null) ...[
            const SizedBox(height: 6),
            TurnBar(
              startedAt: turn.startedAt!,
              length: const Duration(seconds: MajlisCatalog.turnSeconds),
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l.t('yourTurn'),
                  style: MajlisText.body(11, color: const Color(0xFF7A5418), weight: FontWeight.w700),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---- Listeners ----------------------------------------------------------

  Widget _listeners(MajlisStrings l) {
    final listeners = c.listeners;
    final hands = c.space?.hands ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Icon(Icons.headphones_rounded, size: 19, color: MajlisColors.roseDeep),
                const SizedBox(width: 6),
                Text(l.t('listening'), style: MajlisText.head(17)),
                const SizedBox(width: 8),
                Text(
                  l.n(c.listeningCount),
                  style: MajlisText.body(14, color: MajlisColors.muted, weight: FontWeight.w600),
                ),
                const Spacer(),
                if (c.isHost && c.hands.isNotEmpty)
                  GestureDetector(
                    onTap: () => showHandsSheet(context, c),
                    child: MajlisChip(
                      text: l.count(c.hands.length, 'wantToSpeakOne', 'wantToSpeak'),
                      icon: Icons.front_hand_rounded,
                      bg: MajlisColors.goldSoft,
                      fg: const Color(0xFF7A5418),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth / 4;
              return Wrap(
                runSpacing: 14,
                children: [
                  for (final p in listeners)
                    SizedBox(
                      key: ValueKey('near-${p.id}'),
                      width: w,
                      child: _listenerTile(
                        l,
                        p.person,
                        label: p.isLocal ? l.t('you') : null,
                        hand: p.isLocal ? c.handRaised : hands.contains(p.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _listenerTile(MajlisStrings l, MajlisPerson p, {String? label, bool hand = false}) {
    return GestureDetector(
      onTap: () => showPersonSheet(context, c, p),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          MajlisAvatar(person: p, size: 56, hand: hand, popIn: true),
          const SizedBox(height: 6),
          Text(
            label ?? l.name(p),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: MajlisText.body(12, weight: label != null ? FontWeight.w700 : FontWeight.w500, height: 1.15),
          ),
        ],
      ),
    );
  }

  // ---- Bottom bar ---------------------------------------------------------

  Widget _bottomBar(MajlisStrings l, double bottomSafe) {
    final live = c.phase == MajlisRoomPhase.live;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomSafe),
      decoration: BoxDecoration(
        color: MajlisColors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: MajlisColors.plum.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Material(
                color: MajlisColors.sand,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _leave,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    child: Text(
                      c.isHost ? l.t('endSpace') : l.t('leaveQuietly'),
                      style: MajlisText.body(14.5, weight: FontWeight.w700, height: 1.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IgnorePointer(
            ignoring: !live,
            child: Opacity(
              opacity: live ? 1 : 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!c.isHost) ...[
                    _CircleAction(
                      icon: Icons.local_cafe_rounded,
                      tooltip: l.t('teaTip'),
                      tint: MajlisColors.saffron,
                      onTap: c.pourTeaForSpeaker,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _CircleAction(
                    icon: Icons.add_reaction_outlined,
                    tooltip: l.t('reactTip'),
                    active: tray,
                    onTap: () => setState(() => tray = !tray),
                  ),
                  const SizedBox(width: 8),
                  if (c.onStage)
                    _CircleAction(
                      icon: c.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      tooltip: c.micOn ? l.t('mute') : l.t('unmute'),
                      active: c.micOn,
                      onTap: c.toggleMic,
                    )
                  else
                    _CircleAction(
                      icon: Icons.edit_note_rounded,
                      tooltip: l.t('writeInstead'),
                      onTap: () => showWhisperSheet(context, c),
                    ),
                  const SizedBox(width: 10),
                  _primary(l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primary(MajlisStrings l) {
    if (c.isHost) {
      return _BigAction(
        tooltip: l.t('raisedHands'),
        color: MajlisColors.roseDeep,
        onTap: () => showHandsSheet(context, c),
        badge: c.hands.isEmpty ? null : l.n(c.hands.length),
        icon: Icons.front_hand_rounded,
      );
    }
    if (c.onStage) {
      return _BigAction(
        tooltip: l.t('backToListening'),
        color: MajlisColors.roseDeep,
        onTap: c.leaveStage,
        icon: Icons.headphones_rounded,
      );
    }
    return _BigAction(
      tooltip: c.handRaised ? l.t('lowerHand') : l.t('raiseHand'),
      color: c.handRaised ? MajlisColors.gold : MajlisColors.roseDeep,
      iconColor: c.handRaised ? MajlisColors.ink : Colors.white,
      glow: c.handRaised,
      onTap: c.raiseHand,
      icon: Icons.front_hand_rounded,
    );
  }

  Widget _tray(MajlisStrings l) {
    // Closed: hidden from TalkBack too, not just shrunk to nothing.
    return ExcludeSemantics(
      excluding: !tray,
      child: IgnorePointer(
        ignoring: !tray,
        child: _trayBody(l),
      ),
    );
  }

  Widget _trayBody(MajlisStrings l) {
    return AnimatedScale(
      scale: tray ? 1 : 0,
      alignment: AlignmentDirectional.bottomEnd.resolve(Directionality.of(context)),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        decoration: BoxDecoration(
          color: MajlisColors.paper,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: MajlisColors.plum.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in MajlisCatalog.reactions)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => c.react(r.id),
                child: SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: r.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(r.icon, color: r.color, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.reaction(r.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MajlisText.body(10.5, color: MajlisColors.muted, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _prompt(MajlisStrings l) {
    Widget? card;
    if (c.invited) {
      card = _PromptCard(
        key: const ValueKey('invite'),
        host: c.host,
        title: l.t('invitedYou', {'name': l.name(c.host)}),
        subtitle: l.t('invitedSub'),
        yes: l.t('joinStage'),
        no: l.t('notNow'),
        onYes: c.acceptInvite,
        onNo: c.declineInvite,
      );
    } else if (c.breathePrompt) {
      card = _PromptCard(
        key: const ValueKey('breathe'),
        host: c.host,
        title: l.t('breatheInvite', {'name': l.name(c.host)}),
        subtitle: l.t('breatheSub'),
        yes: l.t('breathe'),
        no: l.t('notNow'),
        onYes: () => c.startBreathing(together: true),
        onNo: c.dismissBreathe,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, a) => SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: card ?? const SizedBox.shrink(key: ValueKey('none')),
    );
  }

  Widget _toast(MajlisStrings l) {
    final t = c.toast;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: child),
      ),
      child: t == null
          ? const SizedBox.shrink(key: ValueKey('no-toast'))
          : Container(
              key: ValueKey(t.id),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 16, 10),
              decoration: BoxDecoration(
                color: MajlisColors.ink,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 17, color: MajlisColors.gold),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t.text(l),
                      style: MajlisText.body(13.5, color: MajlisColors.cream, weight: FontWeight.w500),
                    ),
                  ),
                  if (t.action != null && t.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: t.action,
                      child: Text(
                        t.actionLabel!(l),
                        style: MajlisText.body(13.5, color: MajlisColors.gold, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ---- Small pieces ---------------------------------------------------------

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.child, required this.color, required this.onTap, required this.tooltip});
  final Widget child;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(side: BorderSide(color: MajlisColors.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.tooltip, required this.onTap, this.active = false, this.tint});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? MajlisColors.rosewater : MajlisColors.sand,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, size: 22, color: active ? MajlisColors.roseDeep : (tint ?? MajlisColors.ink)),
          ),
        ),
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.iconColor = Colors.white,
    this.badge,
    this.glow = false,
  });
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (glow ? MajlisColors.gold : MajlisColors.plum).withValues(alpha: glow ? 0.7 : 0.25),
                  blurRadius: glow ? 22 : 12,
                  spreadRadius: glow ? 3 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: color,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(width: 58, height: 58, child: Icon(icon, color: iconColor, size: 26)),
              ),
            ),
          ),
          if (badge != null)
            PositionedDirectional(
              end: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: MajlisColors.gold,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: MajlisColors.paper, width: 2),
                ),
                child: Text(badge!, style: MajlisText.body(12, weight: FontWeight.w800, height: 1)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    super.key,
    required this.host,
    required this.title,
    required this.subtitle,
    required this.yes,
    required this.no,
    required this.onYes,
    required this.onNo,
  });
  final MajlisPerson host;
  final String title;
  final String subtitle;
  final String yes;
  final String no;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: MajlisColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MajlisColors.gold, width: 1.2),
        boxShadow: [BoxShadow(color: MajlisColors.plum.withValues(alpha: 0.2), blurRadius: 26, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MajlisAvatar(person: host, size: 46, speaking: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MajlisText.body(15, weight: FontWeight.w700, height: 1.25)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: MajlisText.body(12.5, color: MajlisColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onNo,
                  style: TextButton.styleFrom(
                    foregroundColor: MajlisColors.ink,
                    minimumSize: const Size.fromHeight(46),
                    shape: const StadiumBorder(side: BorderSide(color: MajlisColors.line)),
                  ),
                  child: Text(no, style: MajlisText.body(14.5, weight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onYes,
                  style: FilledButton.styleFrom(backgroundColor: MajlisColors.roseDeep, minimumSize: const Size.fromHeight(46)),
                  child: Text(
                    yes,
                    style: MajlisText.body(14.5, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A shared (or private) breathing minute.
class BreatheTogether extends StatefulWidget {
  const BreatheTogether({super.key, required this.onDone, this.people});
  final VoidCallback onDone;

  /// How many people are in the room; null when breathing alone.
  final int? people;

  @override
  State<BreatheTogether> createState() => _BreatheTogetherState();
}

class _BreatheTogetherState extends State<BreatheTogether> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: Material(
          color: MajlisColors.night,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: GirihPainter(opacity: 0.1))),
              Center(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final v = _c.value;
                    final half = v < 0.5 ? v * 2 : (1 - v) * 2;
                    final scale = 0.55 + 0.45 * Curves.easeInOut.transform(half);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          MajlisText.caps(widget.people != null ? l.t('breathingTogether') : l.t('breathingAlone')),
                          style: MajlisText.eyebrow(color: MajlisColors.gold),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: scale,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [Color(0xF2C17A82), Color(0x73C17A82), Color(0x00C17A82)],
                                      stops: [0, 0.6, 1],
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: v * pi / 2,
                                child: Transform.scale(
                                  scale: scale,
                                  child: CustomPaint(size: const Size(200, 200), painter: _StarOutline()),
                                ),
                              ),
                              Text(
                                v < 0.5 ? l.t('breatheIn') : l.t('breatheOut'),
                                style: MajlisText.head(30, color: MajlisColors.cream),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (widget.people != null && widget.people! > 1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_2_rounded, size: 18, color: MajlisColors.cream.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              Text(
                                l.count(widget.people! - 1, 'breathingWithYouOne', 'breathingWithYou'),
                                style: MajlisText.body(15, color: MajlisColors.cream.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        const SizedBox(height: 30),
                        OutlinedButton(
                          onPressed: widget.onDone,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MajlisColors.cream,
                            side: BorderSide(color: MajlisColors.cream.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l.t('imBack'),
                            style: MajlisText.body(15, color: MajlisColors.cream, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarOutline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = MajlisColors.gold.withValues(alpha: 0.7);
    final c = size.center(Offset.zero);
    final r = Rect.fromCenter(center: c, width: size.width * 0.62, height: size.height * 0.62);
    canvas.drawRect(r, paint);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(pi / 4);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

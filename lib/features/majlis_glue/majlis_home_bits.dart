import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:wellmate/features/majlis/domain/majlis_models.dart';
import 'package:wellmate/features/majlis/l10n/majlis_strings.dart';
import 'package:wellmate/features/majlis/majlis_theme.dart';
import 'package:wellmate/features/majlis/presentation/controllers/majlis_hallway_controller.dart';
import 'package:wellmate/features/majlis/presentation/widgets/majlis_avatar.dart';
import 'package:wellmate/features/majlis/presentation/widgets/majlis_bits.dart';
import 'package:wellmate/features/majlis/presentation/widgets/majlis_logo.dart';

import 'majlis_scope.dart';

const _room = Color(0xFF3E2731);
const _creamSoft = Color(0xFFF3E6DC);

/// The open, busiest space a person can walk into from Home: open spaces
/// before women-only ones (those ask first), then the hallway's own order
/// (yours, guide-led, busiest).
MajlisSpace? _bestLive(MajlisHallway hall) {
  final live = hall.live;
  return live.where((s) => s.audience == MajlisAudience.open).firstOrNull ?? live.firstOrNull;
}

/// Home: a warm door into Majlis, between "How do you feel" and the journey.
///
/// - Someone is talking: the space, who is on the carpet, and Join.
/// - Nothing live, something scheduled: the next space and when.
/// - Quiet: the Majlis promise, and a way in.
class MajlisHomeCard extends StatelessWidget {
  const MajlisHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = MajlisScope.watch(context);
    if (scope == null) return const SizedBox.shrink();
    final hall = scope.hallway;
    final l = MajlisStrings.of(context);
    final live = _bestLive(hall);
    final next = live == null ? hall.scheduled.firstOrNull : null;
    final spaces = hall.live.length;

    final String eyebrow;
    final String title;
    String? sub;
    VoidCallback onTap;
    if (live != null) {
      eyebrow = l.t('liveNow');
      title = live.title;
      // Words, not a dot: in Dari and Pashto a dot reads as the digit zero (۰).
      sub = l.t('peopleIn', {
        'people': l.count(hall.peopleNow, 'personOne', 'peopleN'),
        'spaces': l.count(spaces, 'spaceOne', 'spacesIn'),
      });
      onTap = scope.openTab;
    } else if (next != null) {
      eyebrow = l.t('majlis');
      title = next.title;
      sub = next.scheduledFor == null ? null : l.when(next.scheduledFor!);
      onTap = () => scope.open(next.id);
    } else {
      eyebrow = l.t('majlis');
      title = l.t('tagline');
      onTap = scope.openTab;
    }

    return Semantics(
      button: true,
      label: [eyebrow, title, ?sub].join('. '),
      excludeSemantics: true,
      // The shadow sits outside the Material, so the rounded corners stay clean.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: _room.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [MajlisColors.plum, _room],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(color: MajlisColors.cream, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const MajlisLogo(size: 42),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (live != null) ...[const LiveDot(size: 7, color: MajlisColors.gold), const SizedBox(width: 6)],
                            Flexible(
                              child: Text(
                                MajlisText.caps(eyebrow),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MajlisText.eyebrow(color: MajlisColors.gold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MajlisText.head(live == null && next == null ? 15.5 : 17, color: MajlisColors.cream),
                        ),
                        if (sub != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MajlisText.body(12.5, color: _creamSoft.withValues(alpha: 0.85)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (live != null)
                    _JoinPill(space: live, label: l.t('join'), onTap: () => scope.open(live.id))
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: MajlisColors.cream.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                        color: MajlisColors.cream,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to three people on the carpet, over a Join button.
class _JoinPill extends StatelessWidget {
  const _JoinPill({required this.space, required this.label, required this.onTap});

  final MajlisSpace space;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final faces = space.stage.take(3).toList();
    const size = 26.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (faces.isNotEmpty)
          SizedBox(
            width: size + (faces.length - 1) * size * 0.62,
            height: size,
            child: Stack(
              children: [
                for (var i = 0; i < faces.length; i++)
                  PositionedDirectional(
                    start: i * size * 0.62,
                    child: MajlisAvatar(person: faces[i], size: size),
                  ),
              ],
            ),
          ),
        if (faces.isNotEmpty) const SizedBox(height: 6),
        Material(
          color: MajlisColors.cream,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Text(
                label,
                style: MajlisText.body(13.5, color: MajlisColors.plum, weight: FontWeight.w700, height: 1.1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The middle nav-bar icon: the tea-glass microphone, with a gold dot when
/// someone is talking and the tab is not open.
class MajlisNavIcon extends StatelessWidget {
  const MajlisNavIcon({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scope = MajlisScope.watch(context);
    final someoneLive = !selected && (scope?.hallway.live.isNotEmpty ?? false);
    return Semantics(
      label: MajlisStrings.of(context).t('majlis'),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              selected ? 'assets/icons/ic_majlis_active.svg' : 'assets/icons/ic_majlis_inactive.svg',
              width: 26,
              height: 26,
            ),
            if (someoneLive) const PositionedDirectional(top: -1, end: -1, child: LiveDot(size: 7, color: MajlisColors.gold)),
          ],
        ),
      ),
    );
  }
}

/// In Home's feeling sheet (tired, anxious, sad): a quiet second way to
/// feel better, by sitting with others.
class MajlisFeelingLink extends StatelessWidget {
  const MajlisFeelingLink({super.key, required this.hallway, required this.onTap});

  final MajlisHallway? hallway;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    final hall = hallway;
    Widget row(int people) => Material(
      color: MajlisColors.blush,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: MajlisColors.paper, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const MajlisLogo(size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.t('sitWithOthers'),
                      style: MajlisText.body(14.5, color: MajlisColors.plum, weight: FontWeight.w700),
                    ),
                    if (people > 0)
                      Row(
                        children: [
                          const LiveDot(size: 6),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              l.t('hereNow', {'people': l.count(people, 'personOne', 'peopleN')}),
                              style: MajlisText.body(12.5, color: MajlisColors.muted),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(l.t('tagline'), style: MajlisText.body(12.5, color: MajlisColors.muted)),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: MajlisColors.roseDeep,
              ),
            ],
          ),
        ),
      ),
    );
    if (hall == null) return row(0);
    return ListenableBuilder(listenable: hall, builder: (_, _) => row(hall.peopleNow));
  }
}

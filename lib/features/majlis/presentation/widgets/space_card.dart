import 'package:flutter/material.dart';

import '../../data/majlis_catalog.dart';
import '../../domain/majlis_models.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_theme.dart';
import 'majlis_bits.dart';

/// One live space in the hallway, tinted by its topic.
class SpaceCard extends StatelessWidget {
  const SpaceCard({super.key, required this.space, required this.mine, required this.onTap});
  final MajlisSpace space;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    final s = space;
    final topic = MajlisCatalog.topic(s.topicId);
    final j = topic.jewel;
    final stage = s.stage.isEmpty ? [s.host] : s.stage;
    final names = stage.take(2).map(l.name).join(l.rtl ? '، ' : ', ');
    final more = stage.length - 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: j.deep.withValues(alpha: 0.08), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: MajlisColors.paper,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: j.light,
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        end: -20,
                        top: -20,
                        width: 150,
                        height: 110,
                        child: CustomPaint(painter: GirihPainter(color: j.deep, opacity: 0.12, cell: 30)),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TopicBadge(topic: topic, size: 26),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(l.topic(topic.id),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MajlisText.body(13, color: j.deep, weight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                                const Spacer(),
                                MajlisChip(text: l.langShort(s.lang), fg: j.deep, size: 11.5),
                                const SizedBox(width: 4),
                                const LiveTag(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(s.title,
                                maxLines: 2, overflow: TextOverflow.ellipsis, style: MajlisText.head(21, height: 1.25)),
                            if (s.host.isGuide || mine || s.audience != MajlisAudience.open) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  if (s.host.isGuide) _meta(Icons.verified_rounded, l.t('ledByGuide'), MajlisColors.gold),
                                  if (mine) _meta(Icons.star_rounded, l.t('youreHosting'), MajlisColors.gold),
                                  if (s.audience == MajlisAudience.women) _meta(Icons.female_rounded, l.t('womenOnly'), j.deep),
                                  if (s.audience == MajlisAudience.invite)
                                    _meta(Icons.lock_outline_rounded, l.t('inviteOnly'), j.deep),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      AvatarStack(people: stage, size: 40, speakingIndex: 0),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SoundBars(color: j.deep, height: 12),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    more > 0 ? '$names +${l.n(more)}' : names,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: MajlisText.body(13.5, weight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.headphones_rounded, size: 14, color: MajlisColors.muted),
                                const SizedBox(width: 3),
                                Text(l.n(s.listenerCount),
                                    style: MajlisText.body(12.5, color: MajlisColors.muted, weight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                const Icon(Icons.mic_none_rounded, size: 14, color: MajlisColors.muted),
                                const SizedBox(width: 2),
                                Text(l.n(stage.length),
                                    style: MajlisText.body(12.5, color: MajlisColors.muted, weight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: MajlisColors.ink, borderRadius: BorderRadius.circular(999)),
                        child: Text(l.t('join'),
                            style: MajlisText.body(13.5, color: MajlisColors.cream, weight: FontWeight.w700, height: 1.1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(text, style: MajlisText.body(12.5, color: MajlisColors.muted, weight: FontWeight.w500)),
        ],
      );
}

/// A scheduled space in the "Starting soon" row.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.space,
    required this.mine,
    required this.going,
    required this.onTap,
    required this.onRemind,
  });
  final MajlisSpace space;
  final bool mine;
  final bool going;
  final VoidCallback onTap;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    final e = space;
    final j = MajlisCatalog.topic(e.topicId).jewel;
    final when = e.scheduledFor ?? DateTime.now();
    final time = l.time(when).split(' ');
    return Material(
      color: MajlisColors.paper,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 256,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: mine ? MajlisColors.gold : MajlisColors.line, width: mine ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 76,
                decoration: BoxDecoration(color: j.light, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(MajlisText.caps(l.day(when)),
                            style: MajlisText.eyebrow(color: j.deep).copyWith(fontSize: 9.5)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(time.first, style: MajlisText.head(18, color: j.deep))),
                    if (time.length > 1)
                      Text(time.last, style: MajlisText.body(10, color: j.deep, weight: FontWeight.w700, height: 1.1)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: MajlisText.body(14.5, weight: FontWeight.w700, height: 1.25)),
                    const SizedBox(height: 3),
                    Text(
                      mine ? l.t('youreHosting') : l.name(e.host),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MajlisText.body(12,
                          color: mine ? MajlisColors.roseText : MajlisColors.muted,
                          weight: mine ? FontWeight.w700 : FontWeight.w400),
                    ),
                    const SizedBox(height: 2),
                    Text(l.count(e.goingCount, 'goingOne', 'goingN'), style: MajlisText.body(11.5, color: MajlisColors.muted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemind,
                tooltip: going ? l.t('reminderOn') : l.t('remindMe'),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(
                    mine ? Icons.star_rounded : (going ? Icons.notifications_active_rounded : Icons.notifications_none_rounded),
                    key: ValueKey('$going$mine'),
                    color: mine || going ? MajlisColors.roseDeep : MajlisColors.faint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

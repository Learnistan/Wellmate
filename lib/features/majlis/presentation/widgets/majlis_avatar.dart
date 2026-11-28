import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/majlis_models.dart';
import '../../majlis_theme.dart';
import 'majlis_portraits.dart';

/// A veil avatar: an illustrated portrait (never a photo) in a jewel tone.
/// Speaking people get golden sound rings.
class MajlisAvatar extends StatefulWidget {
  const MajlisAvatar({
    super.key,
    required this.person,
    this.size = 64,
    this.speaking = false,
    this.muted = false,
    this.mutedForMe = false,
    this.host = false,
    this.hand = false,
    this.tea = 0,
    this.popIn = false,
    this.ring = MajlisColors.gold,
  });

  final MajlisPerson person;
  final double size;
  final bool speaking;
  final bool muted;

  /// You turned this person's sound off for yourself ("Mute for me").
  final bool mutedForMe;
  final bool host;
  final bool hand;
  final int tea;
  final bool popIn;
  final Color ring;

  @override
  State<MajlisAvatar> createState() => _MajlisAvatarState();
}

class _MajlisAvatarState extends State<MajlisAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.speaking) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant MajlisAvatar old) {
    super.didUpdateWidget(old);
    if (widget.speaking && !_c.isAnimating) _c.repeat();
    if (!widget.speaking && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final badge = max(20.0, s * 0.3);

    Widget avatar = AnimatedBuilder(
      animation: _c,
      builder: (context, child) => SizedBox(
        width: s,
        height: s,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (widget.speaking) CustomPaint(size: Size(s, s), painter: _RingsPainter(_c.value, widget.ring)),
            Transform.scale(scale: widget.speaking ? 1 + 0.035 * sin(_c.value * pi * 2) : 1.0, child: child),
          ],
        ),
      ),
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.speaking ? widget.ring : MajlisColors.paper, width: s > 50 ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: widget.person.jewel.deep.withValues(alpha: 0.22),
              blurRadius: s * 0.22,
              offset: Offset(0, s * 0.08),
            ),
          ],
        ),
        child: ClipOval(child: VeilPattern(person: widget.person)),
      ),
    );

    avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (widget.person.isGuide)
          PositionedDirectional(
            end: -3,
            top: -3,
            child: _Badge(size: badge, color: MajlisColors.gold, icon: Icons.verified_rounded, iconColor: Colors.white),
          )
        else if (widget.host)
          PositionedDirectional(
            end: -3,
            top: -3,
            child: _Badge(size: badge, color: MajlisColors.gold, icon: Icons.star_rounded, iconColor: Colors.white),
          ),
        if (widget.hand)
          PositionedDirectional(
            end: -4,
            top: -6,
            child: _Badge(size: badge, color: MajlisColors.gold, icon: Icons.front_hand_rounded, iconColor: MajlisColors.ink),
          ),
        if (widget.muted || widget.mutedForMe)
          PositionedDirectional(
            end: -3,
            bottom: -3,
            child: _Badge(
              size: badge,
              color: MajlisColors.paper,
              icon: widget.mutedForMe ? Icons.volume_off_rounded : Icons.mic_off_rounded,
              iconColor: MajlisColors.plum,
            ),
          ),
        if (widget.tea > 0)
          PositionedDirectional(
            start: -6,
            bottom: -4,
            child: Container(
              height: badge,
              padding: EdgeInsets.symmetric(horizontal: badge * 0.22),
              decoration: BoxDecoration(
                color: MajlisColors.saffron,
                borderRadius: BorderRadius.circular(badge),
                border: Border.all(color: MajlisColors.paper, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_cafe_rounded, size: badge * 0.55, color: Colors.white),
                  if (widget.tea > 1) ...[
                    const SizedBox(width: 2),
                    Text('${widget.tea}', style: MajlisText.body(badge * 0.5, color: Colors.white, weight: FontWeight.w700, height: 1)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );

    if (!widget.popIn) return avatar;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: avatar,
    );
  }
}

/// The picture inside an avatar: an illustration (MajlisPortraitArt) in the
/// person's colour tone. Never a photo.
class VeilPattern extends StatelessWidget {
  const VeilPattern({super.key, required this.person});
  final MajlisPerson person;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      MajlisPortraitArt.svg(person.motif, person.jewelIndex),
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.size, required this.color, required this.icon, required this.iconColor});
  final double size;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: MajlisColors.paper, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.58, color: iconColor),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    for (var i = 0; i < 2; i++) {
      final p = (t + i * 0.5) % 1.0;
      canvas.drawCircle(
        c,
        r + 2 + p * r * 0.4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - p) + 0.4
          ..color = color.withValues(alpha: (1 - p) * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t || old.color != color;
}

/// A small bar that fills while a speaker's turn runs (Take turns mode).
class TurnBar extends StatelessWidget {
  const TurnBar({super.key, required this.startedAt, required this.length, this.width = 64});
  final DateTime startedAt;
  final Duration length;
  final double width;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(startedAt);
    final start = (elapsed.inMilliseconds / length.inMilliseconds).clamp(0.0, 1.0);
    final remaining = length - elapsed;
    return TweenAnimationBuilder<double>(
      key: ValueKey(startedAt),
      tween: Tween(begin: start, end: 1.0),
      duration: remaining.isNegative ? Duration.zero : remaining,
      builder: (context, v, _) => Container(
        width: width,
        height: 5,
        decoration: BoxDecoration(color: MajlisColors.goldSoft, borderRadius: BorderRadius.circular(9)),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(decoration: BoxDecoration(color: MajlisColors.gold, borderRadius: BorderRadius.circular(9))),
        ),
      ),
    );
  }
}

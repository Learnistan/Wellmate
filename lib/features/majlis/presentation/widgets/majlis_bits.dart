import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/majlis_catalog.dart';
import '../../domain/majlis_models.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_theme.dart';
import 'majlis_avatar.dart';

/// Faint 8-point star pattern from wellmate.app.
class GirihPainter extends CustomPainter {
  GirihPainter({this.color = MajlisColors.goldLine, this.opacity = 0.16, this.cell = 40});
  final Color color;
  final double opacity;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: opacity);
    final half = cell * 0.2;
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        final c = Offset(x + cell / 2, y + cell / 2);
        canvas.drawRect(Rect.fromCenter(center: c, width: half * 2, height: half * 2), paint);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(pi / 4);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(GirihPainter old) => old.opacity != opacity || old.color != color;
}

/// Pulsing "live" dot.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.size = 8, this.color = MajlisColors.live});
  final double size;
  final Color color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s + s * 1.4 * _c.value,
              height: s + s * 1.4 * _c.value,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.4 * (1 - _c.value))),
            ),
            Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
          ],
        ),
      ),
    );
  }
}

/// "LIVE" tag with a pulsing dot.
class LiveTag extends StatelessWidget {
  const LiveTag({super.key, this.color = MajlisColors.live});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveDot(size: 7, color: color),
        Text(MajlisStrings.of(context).t('live'), style: MajlisText.eyebrow(color: color)),
      ],
    );
  }
}

/// Three little bars that bounce while someone talks.
class SoundBars extends StatefulWidget {
  const SoundBars({super.key, this.color = MajlisColors.roseDeep, this.height = 14});
  final Color color;
  final double height;

  @override
  State<SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<SoundBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final v = 0.3 + 0.7 * (0.5 + 0.5 * sin((_c.value + i * 0.21) * pi * 2));
          return Container(
            width: 2.6,
            height: widget.height * v,
            margin: const EdgeInsets.symmetric(horizontal: 0.9),
            decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }
}

/// Small rounded label with an optional icon.
class MajlisChip extends StatelessWidget {
  const MajlisChip({
    super.key,
    required this.text,
    this.icon,
    this.bg = MajlisColors.paper,
    this.fg = MajlisColors.ink,
    this.size = 12.5,
    this.border,
  });
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final double size;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon != null ? 8 : 10, 5, 10, 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: MajlisText.body(size, color: fg, weight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }
}

/// Round icon in a soft circle, tinted by a topic.
class TopicBadge extends StatelessWidget {
  const TopicBadge({super.key, required this.topic, this.size = 36});
  final MajlisTopic topic;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: topic.jewel.deep, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(topic.icon, size: size * 0.52, color: Colors.white),
    );
  }
}

/// Overlapping avatars for a space card.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.people, this.size = 40, this.speakingIndex, this.border = MajlisColors.paper});
  final List<MajlisPerson> people;
  final double size;
  final int? speakingIndex;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(4).toList();
    final step = size * 0.66;
    return SizedBox(
      width: size + step * (shown.length - 1) + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = shown.length - 1; i >= 0; i--)
            PositionedDirectional(
              start: i * step,
              top: 3,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: i == speakingIndex ? MajlisColors.gold : border, width: 2.5),
                ),
                child: ClipOval(child: VeilPattern(person: shown[i])),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reactions that float up the screen, like in a live stream.
class FloatingReactions extends StatelessWidget {
  const FloatingReactions({super.key, required this.items, this.bottom = 120});
  final List<({int id, String kind, double x, bool mine})> items;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            for (final r in items)
              _Floater(
                key: ValueKey(r.id),
                kind: MajlisCatalog.reaction(r.kind),
                // x counts from the start edge, so "mine" floats up near the tray in both directions.
                x: (rtl ? 1 - r.x - 0.1 : r.x) * box.maxWidth,
                bottom: bottom,
                rise: box.maxHeight * 0.42,
                big: r.mine,
                seed: r.id,
              ),
          ],
        ),
      ),
    );
  }
}

class _Floater extends StatelessWidget {
  const _Floater({super.key, required this.kind, required this.x, required this.bottom, required this.rise, required this.big, required this.seed});
  final MajlisReactionKind kind;
  final double x;
  final double bottom;
  final double rise;
  final bool big;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final size = big ? 44.0 : 36.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2700),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final opacity = t < 0.12 ? t / 0.12 : (1 - (t - 0.12) / 0.88).clamp(0.0, 1.0);
        final scale = t < 0.15 ? 0.4 + t / 0.15 * 0.7 : 1.1 - t * 0.2;
        return Positioned(
          left: x + sin(t * pi * 2.4 + seed) * 14,
          bottom: bottom + t * rise,
          child: Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: child)),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: MajlisColors.paper,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: kind.color.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Icon(kind.icon, color: kind.color, size: size * 0.55),
      ),
    );
  }
}

/// Line-drawn mood faces (Calm, Good, Tired, Anxious, Sad).
class MoodFace extends StatelessWidget {
  const MoodFace({super.key, required this.mood, this.size = 40, this.active = false});
  final int mood;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _MoodPainter(mood, active));
  }
}

class _MoodPainter extends CustomPainter {
  _MoodPainter(this.mood, this.active);
  final int mood;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.scale(s);
    canvas.drawCircle(const Offset(20, 20), 18.5, Paint()..color = active ? MajlisColors.rosewater : MajlisColors.sand);
    final ink = active ? MajlisColors.roseDeep : MajlisColors.muted;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..color = ink;
    final dot = Paint()..color = ink;
    void eyesDots() {
      canvas.drawCircle(const Offset(15, 17.5), 1.7, dot);
      canvas.drawCircle(const Offset(25, 17.5), 1.7, dot);
    }

    switch (mood) {
      case 0: // calm
        canvas.drawPath(Path()..moveTo(12, 17)..quadraticBezierTo(15, 19.4, 18, 17), stroke);
        canvas.drawPath(Path()..moveTo(22, 17)..quadraticBezierTo(25, 19.4, 28, 17), stroke);
        canvas.drawPath(Path()..moveTo(14.5, 25)..quadraticBezierTo(20, 28.5, 25.5, 25), stroke);
        break;
      case 1: // good
        eyesDots();
        canvas.drawPath(Path()..moveTo(12.5, 23)..quadraticBezierTo(20, 31, 27.5, 23), stroke);
        break;
      case 2: // tired
        canvas.drawLine(const Offset(12.5, 18), const Offset(17.5, 18), stroke);
        canvas.drawLine(const Offset(22.5, 18), const Offset(27.5, 18), stroke);
        canvas.drawLine(const Offset(15.5, 27), const Offset(24.5, 27), stroke);
        break;
      case 3: // anxious
        eyesDots();
        canvas.drawLine(const Offset(11.5, 12.5), const Offset(16.5, 14), stroke);
        canvas.drawLine(const Offset(28.5, 12.5), const Offset(23.5, 14), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(13, 27)
            ..quadraticBezierTo(15.3, 24.5, 17.6, 27)
            ..quadraticBezierTo(20, 29.5, 22.4, 27)
            ..quadraticBezierTo(24.7, 24.5, 27, 27),
          stroke,
        );
        break;
      default: // sad
        eyesDots();
        canvas.drawPath(Path()..moveTo(14, 29)..quadraticBezierTo(20, 23.5, 26, 29), stroke);
    }
  }

  @override
  bool shouldRepaint(_MoodPainter old) => old.mood != mood || old.active != active;
}

/// Section title used across the hallway.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing, this.leading});
  final String title;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        children: [
          Text(title, style: MajlisText.head(21)),
          if (leading != null) ...[const SizedBox(width: 6), leading!],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

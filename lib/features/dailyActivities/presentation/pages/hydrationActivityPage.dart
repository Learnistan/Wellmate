import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/activityProvider.dart';

class HydrationActivityPage extends StatefulWidget {
  final int cups;

  const HydrationActivityPage({super.key, required this.cups});

  @override
  State<HydrationActivityPage> createState() => _HydrationActivityPageState();
}

class _HydrationActivityPageState extends State<HydrationActivityPage>
    with TickerProviderStateMixin {
  static const int maxGlasses = 8;

  int currentGlasses = 0;

  late AnimationController _waterController;
  late final loc = AppLocalizations.of(context)!;

  String get motivationText {
    if (currentGlasses == 0) {
      return loc.drinkWaterMessage1;
    } else if (currentGlasses < 4) {
      return loc.drinkWaterMessage2;
    } else if (currentGlasses < 8) {
      return loc.drinkWaterMessage3;
    } else {
      return loc.drinkWaterMessage4;
    }
  }

  @override
  void initState() {
    super.initState();

    _waterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    Future.microtask(() async {
      final provider = context.read<ActivityProvider>();
      await provider.loadTodayHydrationGlasses();
      print(provider.hydrationGlasses);
      setState(() {
        currentGlasses = provider.hydrationGlasses;
      });
    });
  }

  @override
  void dispose() {
    _waterController.dispose();
    super.dispose();
  }

  void drinkWater() {
    if (currentGlasses >= maxGlasses) return;

    setState(() {
      currentGlasses++;
      context.read<ActivityProvider>().saveActivityLog(
        activityId: 3,
        value: '{"glasses":$currentGlasses}',
      );
    });

    _waterController.forward(from: 0);

    if (currentGlasses == maxGlasses) {
      Future.delayed(const Duration(milliseconds: 800), () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(loc.hydrationPopupTitle),
            content: Text(loc.hydrationPopupMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop("activity completed");
                },
                child: Text(loc.hydrationPopupBtn),
              ),
            ],
          ),
        );
      });
    }
  }

  void resetProgress() {
    setState(() {
      currentGlasses = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final waterLevel = currentGlasses / maxGlasses;
    final locale = Localizations.localeOf(context);
    final mq = MediaQuery.of(context);
    final scale = (mq.size.width / 390).clamp(0.85, 1.2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(currentGlasses);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(currentGlasses),
          ),
          title: Text(
            loc.activity_hydration,
            style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20 * scale),
          ),
          centerTitle: true,
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Column(
                  children: [
                    SizedBox(height: mq.size.height * 0.02),

                    // Motivation text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        motivationText,
                        key: ValueKey(motivationText),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.semiBold(locale).copyWith(
                          fontSize: 15 * scale,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    SizedBox(height: mq.size.height * 0.01),

                    // Counter badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * scale,
                        vertical: 6 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        "$currentGlasses / $maxGlasses ${loc.glassesTxt}",
                        style: AppTextStyles.semiBold(locale).copyWith(
                          fontSize: 15 * scale,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: mq.size.height * 0.025),

                    // Glass
                    Expanded(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: waterLevel),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            final glassH = mq.size.height * 0.32;
                            final glassW = glassH * 0.58;
                            return _BeautifulGlass(
                              fillLevel: value,
                              width: glassW,
                              height: glassH,
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: mq.size.height * 0.025),

                    // Progress dots/pills
                    Row(
                      children: List.generate(maxGlasses, (index) {
                        final filled = index < currentGlasses;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: filled
                                  ? AppColors.primary
                                  : AppColors.secondary,
                              boxShadow: filled
                                  ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: mq.size.height * 0.03),

                    // Drink button
                    SizedBox(
                      width: double.infinity,
                      height: 56 * scale,
                      child: ElevatedButton(
                        onPressed: drinkWater,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          currentGlasses == maxGlasses
                              ? loc.hydrationBtn3
                              : loc.hydrationBtn1,
                          style: AppTextStyles.semiBold(locale).copyWith(
                            fontSize: 17 * scale,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: resetProgress,
                      child: Text(
                        loc.hydrationBtn2,
                        style: AppTextStyles.semiBold(locale).copyWith(
                          color: AppColors.darkerGray,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),

                    SizedBox(height: mq.size.height * 0.015),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Beautiful Glass Widget ───────────────────────────────────────────────────

class _BeautifulGlass extends StatelessWidget {
  final double fillLevel; // 0.0 → 1.0
  final double width;
  final double height;

  const _BeautifulGlass({
    required this.fillLevel,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + 20,
      height: height + 20,
      child: CustomPaint(
        painter: _GlassPainter(fillLevel: fillLevel),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double fillLevel;

  const _GlassPainter({required this.fillLevel});

  // Geometry helpers — same trapezoid used for clip, border & fill
  Path _glassOutlinePath(Size size) {
    final w = size.width;
    final h = size.height;

    // Four corners of the trapezoid (wider at top, narrower at bottom)
    final tl = Offset(w * 0.05, h * 0.04);
    final tr = Offset(w * 0.95, h * 0.04);
    final br = Offset(w * 0.83, h * 0.96);
    final bl = Offset(w * 0.17, h * 0.96);

    const r = 12.0;

    final path = Path();

    // Top edge — left to right
    path.moveTo(tl.dx + r, tl.dy);
    path.lineTo(tr.dx - r, tr.dy);
    // Top-right corner
    path.quadraticBezierTo(tr.dx, tr.dy, tr.dx, tr.dy + r);
    // Right side — top to bottom
    path.lineTo(br.dx, br.dy - r);
    // Bottom-right corner
    path.quadraticBezierTo(br.dx, br.dy, br.dx - r, br.dy);
    // Bottom edge — right to left
    path.lineTo(bl.dx + r, bl.dy);
    // Bottom-left corner
    path.quadraticBezierTo(bl.dx, bl.dy, bl.dx, bl.dy - r);
    // Left side — bottom to top
    path.lineTo(tl.dx, tl.dy + r);
    // Top-left corner
    path.quadraticBezierTo(tl.dx, tl.dy, tl.dx + r, tl.dy);

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePath = _glassOutlinePath(size);

    // ── 1. Glass body background (frosted look) ───────────────────────────
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          AppColors.secondary.withOpacity(0.10),
          Colors.white.withOpacity(0.06),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(outlinePath, bgPaint);

    // ── 2. Water fill ─────────────────────────────────────────────────────
    if (fillLevel > 0) {
      canvas.save();
      canvas.clipPath(outlinePath);

      final fillTop = size.height * (1 - fillLevel * 0.93 - 0.04);

      // Gentle wave path at the surface
      final wavePath = Path();
      wavePath.moveTo(0, fillTop);

      const waveCount = 3;
      final segW = size.width / waveCount;
      for (int i = 0; i < waveCount; i++) {
        final x0 = i * segW;
        wavePath.cubicTo(
          x0 + segW * 0.25, fillTop - 5,
          x0 + segW * 0.75, fillTop + 5,
          x0 + segW, fillTop,
        );
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.lineTo(0, size.height);
      wavePath.close();

      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.lightBlueAccent.withOpacity(0.60),
            Colors.blue.withOpacity(0.75),
            Colors.blue.shade700.withOpacity(0.80),
          ],
        ).createShader(Rect.fromLTWH(0, fillTop, size.width, size.height - fillTop))
        ..style = PaintingStyle.fill;

      canvas.drawPath(wavePath, waterPaint);

      // Subtle shimmer line on water surface
      final shimmerPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(wavePath, shimmerPaint);

      canvas.restore();
    }

    // ── 3. Inner highlight (left shine strip) ─────────────────────────────
    final shinePath = Path();
    shinePath.moveTo(size.width * 0.12, size.height * 0.07);
    shinePath.quadraticBezierTo(
      size.width * 0.18, size.height * 0.40,
      size.width * 0.14, size.height * 0.72,
    );
    shinePath.lineTo(size.width * 0.20, size.height * 0.72);
    shinePath.quadraticBezierTo(
      size.width * 0.23, size.height * 0.40,
      size.width * 0.20, size.height * 0.07,
    );
    shinePath.close();

    canvas.save();
    canvas.clipPath(outlinePath);
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(shinePath, shinePaint);
    canvas.restore();

    // ── 4. Glass border ───────────────────────────────────────────────────
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(0.55),
          AppColors.secondary.withOpacity(0.80),
          AppColors.primary.withOpacity(0.30),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(outlinePath, borderPaint);
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.fillLevel != fillLevel;
}
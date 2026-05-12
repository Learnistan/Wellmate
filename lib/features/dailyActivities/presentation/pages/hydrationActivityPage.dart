import 'dart:math';
import 'package:confetti/confetti.dart';
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
  late ConfettiController _confettiController;
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

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
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
    _confettiController.dispose();
    super.dispose();
  }

  void drinkWater() {
    if (currentGlasses >= maxGlasses) return;

    setState(() {
      currentGlasses++;

      context.read<ActivityProvider>().saveHydrationLog(
        activityId: 3,
        value: '{"glasses":$currentGlasses}',
      );
    });

    _waterController.forward(from: 0);

    if (currentGlasses == maxGlasses) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _confettiController.play();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(loc.hydrationPopupTitle),
            content: Text(
              loc.hydrationPopupMessage,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop(currentGlasses);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return ;

        context.pop(currentGlasses);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            loc.activity_hydration,
            style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 25,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                        motivationText,
                        key: ValueKey(motivationText),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.semiBold(locale)
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "$currentGlasses / $maxGlasses ${loc.glassesTxt}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: waterLevel),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 220,
                            height: 340,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipPath(
                                  clipper: GlassClipper(),
                                  child: Container(
                                    width: 180,
                                    height: 300,
                                    color: Colors.white.withOpacity(0.15),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: 300 * value,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.lightBlueAccent.withOpacity(0.8),
                                              Colors.blue.withOpacity(0.9),
                                            ],
                                          ),
                                        ),
                                        // child: const WaterSurface(),
                                      ),
                                    ),
                                  ),
                                ),

                                ClipPath(
                                  clipper: GlassClipper(),
                                  child: Container(
                                    width: 180,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.25),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                CustomPaint(
                                  size: const Size(180, 300),
                                  painter: GlassBorderPainter(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: List.generate(
                      maxGlasses,
                          (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: index < currentGlasses
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: drinkWater,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        currentGlasses == maxGlasses
                            ? loc.hydrationBtn3
                            : loc.hydrationBtn1,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: resetProgress,
                    child: Text(
                        loc.hydrationBtn2,
                        style: AppTextStyles.semiBold(locale)
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}

class GlassClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const bottomRadius = 28.0;

    final path = Path();

    // top-left (sharp)
    path.moveTo(size.width * 0.12, 0);

    // top edge (sharp)
    path.lineTo(size.width * 0.88, 0);

    // right side going down (fat glass)
    path.lineTo(size.width * 0.78, size.height - bottomRadius);

    // bottom-right round corner
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height,
      size.width * 0.62,
      size.height,
    );

    // bottom line
    path.lineTo(size.width * 0.38, size.height);

    // bottom-left round corner
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height,
      size.width * 0.22,
      size.height - bottomRadius,
    );

    // left side up
    path.lineTo(size.width * 0.12, 0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class GlassBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const bottomRadius = 28.0;

    final paint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();

    // top-left sharp
    path.moveTo(size.width * 0.12, 0);

    // top edge
    path.lineTo(size.width * 0.88, 0);

    // right side
    path.lineTo(size.width * 0.78, size.height - bottomRadius);

    // rounded bottom-right
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height,
      size.width * 0.62,
      size.height,
    );

    // bottom edge
    path.lineTo(size.width * 0.38, size.height);

    // rounded bottom-left
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height,
      size.width * 0.22,
      size.height - bottomRadius,
    );

    // left side back to top
    path.lineTo(size.width * 0.12, 0);

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/core/theme/colors.dart';

import '../../../../core/theme/textStyles.dart';
import '../../../../l10n/app_localizations.dart';

class VisualizingGamePage extends StatefulWidget {
  const VisualizingGamePage({super.key});

  @override
  State<VisualizingGamePage> createState() => _VisualizingGamePageState();
}

class _VisualizingGamePageState extends State<VisualizingGamePage>
    with SingleTickerProviderStateMixin {
  static const int totalSeconds = 10;
  static const int totalVisualizationsToWin = 5;

  late final loc = AppLocalizations.of(context)!;

  late final List<String> words = [
    loc.apple,
    loc.mountain,
    loc.river,
    loc.house,
    loc.flower,
    loc.bird,
    loc.moon,
    loc.tree,
    loc.book,
    loc.sun,
  ];

  late AnimationController _animationController;

  Timer? _timer;
  int secondsLeft = totalSeconds;
  int currentWordIndex = 0;
  int visualizedCount = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: totalSeconds),
    );

    startRound();
  }

  void startRound() {
    _timer?.cancel();

    setState(() {
      secondsLeft = totalSeconds;
    });

    _animationController
      ..reset()
      ..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 1) {
        setState(() {
          secondsLeft--;
        });
      } else {
        goToNextWord();
      }
    });
  }

  void goToNextWord() {
    setState(() {
      currentWordIndex = (currentWordIndex + 1) % words.length;
      secondsLeft = totalSeconds;
    });

    _animationController
      ..reset()
      ..forward();
  }

  void onVisualizedPressed() {
    if (visualizedCount >= totalVisualizationsToWin) return;

    setState(() {
      visualizedCount++;
    });

    if (visualizedCount == totalVisualizationsToWin) {
      _timer?.cancel();
      _animationController.stop();
      showWinDialog();
    } else {
      goToNextWord();
    }
  }

  void showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            loc.gameDialogTitle,
            textAlign: TextAlign.center,
          ),
          content: Text(
            loc.visualizingPopUpMessage,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: Text(loc.playAgain),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(loc.goHome),
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      visualizedCount = 0;
      currentWordIndex = 0;
      secondsLeft = totalSeconds;
    });

    startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentWord = words[currentWordIndex];

    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          loc.visualizingGameTitle,
          style: AppTextStyles.semiBold(
            locale,
          ).copyWith(
            fontSize: 24,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      loc.visualizingGameSubTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.grayText(locale).copyWith(color: AppColors.darkerGray, fontSize: 16)
                    ),

                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        currentWord,
                        key: ValueKey(currentWord),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.semiBold(locale).copyWith(fontSize: 42, color: Colors.black)
                      ),
                    ),

                    const SizedBox(height: 40),

                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 190,
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 190,
                                height: 190,
                                child: CircularProgressIndicator(
                                  value: 1 - _animationController.value,
                                  strokeWidth: 14,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: const Color(0xFFE3E8EF),
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              Container(
                                width: 135,
                                height: 135,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF4F7FB),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "$secondsLeft",
                                    style: AppTextStyles.semiBold(locale).copyWith(fontSize: 48, color: Colors.black)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onVisualizedPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          loc.visualizedBtn,
                          style: AppTextStyles.introDesc(locale).copyWith(color: Colors.white, fontSize: 18)
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalVisualizationsToWin, (index) {
                        final bool isOn = index < visualizedCount;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: isOn ? 18 : 14,
                          height: isOn ? 18 : 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOn
                                ? AppColors.primary
                                : const Color(0xFFD6DDE6),
                            boxShadow: isOn
                                ? [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                                : [],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                "$visualizedCount / $totalVisualizationsToWin ${loc.completed}",
                style: AppTextStyles.introDesc(locale).copyWith(fontSize: 15, color: AppColors.darkLabel),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
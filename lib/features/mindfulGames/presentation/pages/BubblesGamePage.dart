import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/core/theme/colors.dart';

import '../../../../core/theme/textStyles.dart';
import '../../../../l10n/app_localizations.dart';

class BubblesGamePage extends StatefulWidget {
  const BubblesGamePage({super.key});

  @override
  State<BubblesGamePage> createState() => _BubblesGamePageState();
}

class _BubblesGamePageState extends State<BubblesGamePage>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late final locale =
  Localizations.localeOf(context);
  late final loc = AppLocalizations.of(context)!;

  late final List<String> _positiveWords = [
    loc.moodCalibrationHappy,
    loc.feeling_good,
    loc.kind,
    loc.brave,
    loc.peace,
    loc.love,
    loc.hope,
    loc.smart,
    loc.strong,
    loc.smile
  ];

  late final List<String> _negativeWords = [
    loc.feeling_sad,
    loc.bad,
    loc.angry,
    loc.fear,
    loc.hate,
    loc.cry,
    loc.weak,
    loc.lazy,
    loc.rude,
    loc.pain,
  ];

  final List<Color> _bubbleColors = [
    Color(0xFFBDEBFF),
    Color(0xFFC9F7E5),
    Color(0xFFFFE1F0),
    Color(0xFFFFF0B8),
    Color(0xFFE4D7FF),
    Color(0xFFFFD6C2),
    Color(0xFFD7F7FF),
    Color(0xFFE8FFD6),
  ];

  final List<_BubbleData> _bubbles = [];

  Timer? _spawnTimer;
  Timer? _gameTimer;

  int _score = 0;
  int _secondsLeft = 60;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_finished) _createBubble();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _finishGame();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _createBubble() {
    final bool isPositive = _random.nextBool();

    final String word = isPositive
        ? _positiveWords[_random.nextInt(_positiveWords.length)]
        : _negativeWords[_random.nextInt(_negativeWords.length)];

    final double size = 74 + _random.nextInt(28).toDouble();
    final Color color = _bubbleColors[_random.nextInt(_bubbleColors.length)];

    final controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 7 + _random.nextInt(4)),
    );

    final bubble = _BubbleData(
      id: UniqueKey().toString(),
      word: word,
      isPositive: isPositive,
      size: size,
      leftFactor: _random.nextDouble(),
      color: color,
      controller: controller,
    );

    controller.forward();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeBubble(bubble);
      }
    });

    setState(() => _bubbles.add(bubble));
  }

  void _tapBubble(_BubbleData bubble) {
    if (_finished) return;

    if (bubble.isPositive) {
      setState(() => _score++);
    }

    _removeBubble(bubble);
  }

  void _removeBubble(_BubbleData bubble) {
    bubble.controller.dispose();

    if (!mounted) return;

    setState(() {
      _bubbles.removeWhere((b) => b.id == bubble.id);
    });
  }

  void _finishGame() {
    _spawnTimer?.cancel();
    _gameTimer?.cancel();

    for (final bubble in List<_BubbleData>.from(_bubbles)) {
      bubble.controller.dispose();
    }

    setState(() {
      _finished = true;
      _secondsLeft = 0;
      _bubbles.clear();
    });
  }

  void _restartGame() {
    for (final bubble in List<_BubbleData>.from(_bubbles)) {
      bubble.controller.dispose();
    }

    _spawnTimer?.cancel();
    _gameTimer?.cancel();

    setState(() {
      _bubbles.clear();
      _score = 0;
      _secondsLeft = 60;
      _finished = false;
    });

    _startGame();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _gameTimer?.cancel();

    for (final bubble in _bubbles) {
      bubble.controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          loc.bubblesGameTitle,
          style: AppTextStyles.semiBold(
            locale,
          ).copyWith(
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopSection(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        _buildBackgroundDecorations(),

                        for (final bubble in _bubbles)
                          _buildBubble(bubble, constraints),

                        if (_finished) _buildScoreResult(),
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

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Text(
            loc.bubblesGameSubTitle,
            style: AppTextStyles.grayText(locale).copyWith(color: AppColors.darkerGray, fontSize: 16)
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  title: loc.score,
                  value: "$_score",
                  icon: Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  title: loc.time,
                  value: "$_secondsLeft s",
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFFEF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.introDesc(locale).copyWith(color: AppColors.appGreen, fontSize: 13)
              ),
              Text(
                value,
                style: AppTextStyles.semiBold(locale).copyWith(color: AppColors.darkLabel, fontSize: 22)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 24,
            child: _smallGlowCircle(42),
          ),
          Positioned(
            top: 120,
            right: 30,
            child: _smallGlowCircle(58),
          ),
          Positioned(
            bottom: 80,
            left: 38,
            child: _smallGlowCircle(70),
          ),
          Positioned(
            bottom: 170,
            right: 46,
            child: _smallGlowCircle(44),
          ),
        ],
      ),
    );
  }

  Widget _smallGlowCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.25),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildBubble(_BubbleData bubble, BoxConstraints constraints) {
    final double maxLeft = constraints.maxWidth - bubble.size;
    final double left = bubble.leftFactor * maxLeft;

    return AnimatedBuilder(
      animation: bubble.controller,
      builder: (context, child) {
        final double bottom =
            -bubble.size +
                bubble.controller.value * (constraints.maxHeight + bubble.size);

        final double wave = sin(bubble.controller.value * pi * 4) * 18;

        return Positioned(
          left: left + wave,
          bottom: bottom,
          child: GestureDetector(
            onTap: () => _tapBubble(bubble),
            child: Container(
              width: bubble.size,
              height: bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.45, -0.55),
                  radius: 0.95,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    bubble.color.withOpacity(0.52),
                    bubble.color.withOpacity(0.20),
                    Colors.white.withOpacity(0.18),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: bubble.color.withOpacity(0.38),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.45),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: bubble.size * 0.16,
                    left: bubble.size * 0.20,
                    child: Container(
                      width: bubble.size * 0.20,
                      height: bubble.size * 0.20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                  ),
                  Positioned(
                    top: bubble.size * 0.13,
                    right: bubble.size * 0.20,
                    child: Container(
                      width: bubble.size * 0.10,
                      height: bubble.size * 0.10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.50),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        bubble.word,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.semiBold(locale).copyWith(fontSize: 15, color: Colors.black)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreResult() {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 58,
              color: Color(0xFFFFB84D),
            ),
            const SizedBox(height: 12),
            Text(
              loc.endGameMessage,
              style: AppTextStyles.semiBold(locale).copyWith(color: Color(0xFF16425B), fontSize: 28)
            ),
            const SizedBox(height: 10),
            Text(
              loc.yourScore,
              style: AppTextStyles.grayText(locale).copyWith(fontSize: 16, color: AppColors.appGreen)
            ),
            const SizedBox(height: 6),
            Text(
              "$_score",
              style: AppTextStyles.semiBold(locale).copyWith(fontSize: 52, color: AppColors.primary)
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  loc.playAgain,
                  style: AppTextStyles.semiBold(locale).copyWith(fontSize: 17, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleData {
  final String id;
  final String word;
  final bool isPositive;
  final double size;
  final double leftFactor;
  final Color color;
  final AnimationController controller;

  _BubbleData({
    required this.id,
    required this.word,
    required this.isPositive,
    required this.size,
    required this.leftFactor,
    required this.color,
    required this.controller,
  });
}
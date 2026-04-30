import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../l10n/app_localizations.dart';

class BreathingActivityPage extends StatefulWidget {
  const BreathingActivityPage({super.key});

  @override
  State<BreathingActivityPage> createState() =>
      _BreathingActivityPageState();
}

class _BreathingActivityPageState extends State<BreathingActivityPage>
    with TickerProviderStateMixin {

  static const int _breathInSeconds = 5;
  static const int _holdSeconds = 3;
  static const int _breathOutSeconds = 5;

  static const int _totalCycleDuration =
      _breathInSeconds + _holdSeconds + _breathOutSeconds;

  static const int _totalActivitySeconds = 120;

  late AnimationController _circleController;
  late AnimationController _sessionController;

  late Animation<double> _sizeAnimation;

  Timer? _timer;
  int _remainingSeconds = _totalActivitySeconds;

  String _phaseLabel = "";
  bool _activityStarted = false;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalCycleDuration),
    );

    _sessionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalActivitySeconds),
    );

    _sizeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: _breathInSeconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _holdSeconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: _breathOutSeconds.toDouble(),
      ),
    ]).animate(_circleController);

    _circleController.addListener(() {
      final t = _circleController.value;

      final breathInEnd = _breathInSeconds / _totalCycleDuration;
      final holdEnd =
          (_breathInSeconds + _holdSeconds) / _totalCycleDuration;

      final loc = AppLocalizations.of(context)!;

      String next;
      if (t < breathInEnd) {
        next = loc.breatheIn;
      } else if (t < holdEnd) {
        next = loc.hold;
      } else {
        next = loc.breatheOut;
      }

      if (next != _phaseLabel) {
        setState(() => _phaseLabel = next);
      }
    });
  }

  void _startActivity() {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _activityStarted = true;
      _phaseLabel = loc.breatheIn;
    });

    _circleController.repeat();
    _sessionController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _circleController.dispose();
    _sessionController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool get _isSessionComplete =>
      _sessionController.status == AnimationStatus.completed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
          title: Text(
            loc.breathingActivity,
            style: AppTextStyles.semiBold(locale).copyWith(
              color: AppColors.primary,
              fontSize: 24,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;

            final base = width * 0.45;
            final spacingSmall = height * 0.02;
            final spacingMedium = height * 0.04;

            final loc = AppLocalizations.of(context)!;
            final locale = Localizations.localeOf(context);

            final displayText = _isSessionComplete
                ? loc.wellDone
                : (_activityStarted ? _phaseLabel : loc.letsBegin);

            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        SizedBox(height: spacingSmall),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.6),
                              end: Offset.zero,
                            ).animate(animation);

                            return ClipRect(
                              child: SlideTransition(
                                position: slide,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: _activityStarted
                              ? Text(
                            _formatTime(_remainingSeconds),
                            key: const ValueKey("timer"),
                            style: AppTextStyles.semiBold(locale).copyWith(
                              fontSize: width * 0.08,
                              color: AppColors.primary,
                            ),
                          )
                              : const SizedBox(key: ValueKey("no_timer")),
                        ),

                        SizedBox(height: spacingSmall),

                        _isSessionComplete
                            ? _buildDoneCircle(base)
                            : _buildBreathingCircle(base),

                        SizedBox(height: spacingMedium),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.6),
                              end: Offset.zero,
                            ).animate(animation);

                            return ClipRect(
                              child: SlideTransition(
                                position: slide,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            displayText,
                            key: ValueKey(displayText),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.semiBold(locale).copyWith(
                              fontSize: width * 0.055,
                              color: _isSessionComplete
                                  ? Colors.black54
                                  : AppColors.primary,
                            ),
                          ),
                        ),

                        SizedBox(height: spacingMedium),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.6),
                              end: Offset.zero,
                            ).animate(animation);

                            return ClipRect(
                              child: SlideTransition(
                                position: slide,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: !_activityStarted
                              ? Padding(
                            key: const ValueKey("button"),
                            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                            child: AppButton(
                              text: loc.start,
                              onPressed: _startActivity,
                            ),
                          )
                              : const SizedBox(key: ValueKey("no_button")),
                        ),

                        SizedBox(height: spacingSmall),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBreathingCircle(double base) {
    return AnimatedBuilder(
      animation: _circleController,
      builder: (context, child) {
        final scale =
        _activityStarted ? _sizeAnimation.value : 0.5;

        final coreSize = base * scale;

        return SizedBox(
          width: base * 2,
          height: base * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildRipple(coreSize, base, 3),
              _buildRipple(coreSize, base, 2),
              _buildRipple(coreSize, base, 1),
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRipple(double coreSize, double base, int index) {
    final rippleSize = coreSize + (base * 0.18 * index);
    final opacity = 0.18 - (index * 0.04);

    return Container(
      width: rippleSize,
      height: rippleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildDoneCircle(double base) {
    final coreSize = base * 0.5;

    return SizedBox(
      width: base * 2,
      height: base * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRipple(coreSize, base, 3),
          _buildRipple(coreSize, base, 2),
          _buildRipple(coreSize, base, 1),
          Container(
            width: coreSize,
            height: coreSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
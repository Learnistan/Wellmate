
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';

import '../../../../core/theme/textStyles.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/activityProvider.dart';

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

  static const String _backgroundImage =
      'assets/images/Breathing Activity bakground-01.png';

  static const String _breathingAudio =
      'audios/Breathing_english.mpeg';

  // Audio player.
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;

  late AnimationController _circleController;
  late AnimationController _sessionController;
  late Animation<double> _sizeAnimation;

  Timer? _timer;

  int _remainingSeconds = _totalActivitySeconds;

  String _phaseLabel = '';
  bool _activityStarted = false;
  bool _dialogShown = false;

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
        tween: Tween<double>(begin: 0.5, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: _breathInSeconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: _holdSeconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: _breathOutSeconds.toDouble(),
      ),
    ]).animate(_circleController);

    _circleController.addListener(() {
      if (!mounted || !_activityStarted) return;

      final t = _circleController.value;

      final breathInEnd =
          _breathInSeconds / _totalCycleDuration;

      final holdEnd =
          (_breathInSeconds + _holdSeconds) /
              _totalCycleDuration;

      final loc = AppLocalizations.of(context)!;

      final String next;

      if (t < breathInEnd) {
        next = loc.breatheIn;
      } else if (t < holdEnd) {
        next = loc.hold;
      } else {
        next = loc.breatheOut;
      }

      if (next != _phaseLabel) {
        setState(() {
          _phaseLabel = next;
        });
      }
    });

    _sessionController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          !_dialogShown) {
        _dialogShown = true;

        _timer?.cancel();
        _circleController.stop();

        // Stop the audio when the session finishes.
        unawaited(_audioPlayer.stop());

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showCompletionDialog();
          }
        });
      }
    });
  }

  // Toggle audio mute/unmute.
  Future<void> _toggleMute() async {
    if (!mounted) return;

    setState(() {
      _isMuted = !_isMuted;
    });

    try {
      await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (error) {
      debugPrint('Audio volume error: $error');
    }
  }

  // Start the English breathing audio.

  Future<void> _playBreathingAudio() async {
    try {
      // Get the language currently selected in the app
      final languageCode =
          Localizations.localeOf(context).languageCode;

      String audioPath;

      switch (languageCode) {
        case 'ps':
          audioPath = 'audios/Breathing_pashto.mp3';
          break;

        case 'fa':
          audioPath = 'audios/Breathing_dari.mp3';
          break;

        case 'en':
        default:
          audioPath = 'audios/Breathing_english.mp3';
          break;
      }

      debugPrint('Selected language: $languageCode');
      debugPrint('Playing audio: $audioPath');

      await _audioPlayer.stop();

      await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);

      await _audioPlayer.play(AssetSource(audioPath));

    } catch (error, stackTrace) {
      debugPrint('BREATHING AUDIO ERROR: $error');
      debugPrint('$stackTrace');
    }
  }


  Future<void> _showCompletionDialog() async {
    if (!mounted) return;

    final loc = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.hydrationPopupTitle),
          content: Text(loc.breathingDialogMessage),
          actions: [
            TextButton(
              onPressed: () {
                context.read<ActivityProvider>().saveActivityLog(
                  activityId: 1,
                  value: '',
                );

                Navigator.of(dialogContext).pop();

                if (mounted) {
                  context.pop('activity completed');
                }
              },
              child: Text(loc.dialogActionButtonTitle),
            ),
          ],
        );
      },
    );
  }

  // Start the breathing activity and audio.
  Future<void> _startActivity() async {
    final loc = AppLocalizations.of(context)!;

    _timer?.cancel();

    _remainingSeconds = _totalActivitySeconds;
    _dialogShown = false;

    setState(() {
      _activityStarted = true;
      _phaseLabel = loc.breatheIn;
    });

    // Start the breathing animation.
    _circleController.repeat();
    _sessionController.forward(from: 0);

    // Start the 2-minute countdown.
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          setState(() {
            _remainingSeconds = 0;
          });

          timer.cancel();
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      },
    );

    // Play the audio when Start is pressed.
    await _playBreathingAudio();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();

    _circleController.dispose();
    _sessionController.dispose();

    // Stop and release the audio player.
    unawaited(_audioPlayer.dispose());

    super.dispose();
  }

  bool get _isSessionComplete =>
      _sessionController.isCompleted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE3),
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6E4A55),
          ),
          onPressed: () => context.pop(),
        ),

        title: Text(
          loc.breathingActivity,
          style: AppTextStyles.semiBold(locale).copyWith(
            fontSize: 20,
            color: const Color(0xFF6E4A55),
          ),
        ),

        actions: [
          IconButton(
            tooltip: _isMuted ? 'Unmute audio' : 'Mute audio',
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: const Color(0xFF6E4A55),
              size: 25,
            ),
          ),
        ],
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image.
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                  'Could not load breathing background: $error',
                );

                return Container(
                  color: const Color(0xFFF5EFE3),
                );
              },
            ),
          ),

          // Breathing activity content.
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final width = constraints.maxWidth;

                final base = (width * 0.45).clamp(
                  100.0,
                  180.0,
                );

                final spacingSmall = height * 0.02;
                final spacingMedium = height * 0.035;

                final displayText = _isSessionComplete
                    ? loc.wellDone
                    : (_activityStarted
                    ? _phaseLabel
                    : loc.letsBegin);

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: spacingSmall,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: height -
                            MediaQuery.of(context).padding.top,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: spacingSmall),

                            // Timer.
                            AnimatedSwitcher(
                              duration: const Duration(
                                milliseconds: 400,
                              ),
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(animation);

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                              child: _activityStarted
                                  ? Text(
                                _formatTime(_remainingSeconds),
                                key: const ValueKey('timer'),
                                style: AppTextStyles
                                    .semiBold(locale)
                                    .copyWith(
                                  fontSize: (width * 0.08)
                                      .clamp(28.0, 48.0),
                                  color: const Color(0xFF98586B),
                                ),
                              )
                                  : const SizedBox(
                                key: ValueKey('no_timer'),
                              ),
                            ),

                            SizedBox(height: spacingSmall),

                            // Animated breathing circle.
                            _isSessionComplete
                                ? _buildDoneCircle(base)
                                : _buildBreathingCircle(base),

                            SizedBox(height: spacingMedium),

                            // Breathing instructions.
                            AnimatedSwitcher(
                              duration: const Duration(
                                milliseconds: 400,
                              ),
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(animation);

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                displayText,
                                key: ValueKey(displayText),
                                textAlign: TextAlign.center,
                                style: AppTextStyles
                                    .semiBold(locale)
                                    .copyWith(
                                  fontSize: (width * 0.055)
                                      .clamp(20.0, 30.0),
                                  color: const Color(0xFF6E4A55),
                                ),
                              ),
                            ),

                            SizedBox(height: spacingMedium),

                            // Start button.
                            AnimatedSwitcher(
                              duration: const Duration(
                                milliseconds: 400,
                              ),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: !_activityStarted
                                  ? Padding(
                                key: const ValueKey('button'),
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.04,
                                ),
                                child: AppButton(
                                  text: loc.start,
                                  onPressed: _startActivity,
                                ),
                              )
                                  : const SizedBox(
                                key: ValueKey('no_button'),
                              ),
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
        ],
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
                decoration: const BoxDecoration(
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

  Widget _buildRipple(
      double coreSize,
      double base,
      int index,
      ) {
    final rippleSize =
        coreSize + (base * 0.18 * index);

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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wellmate/core/theme/colors.dart';

import '../../../../core/theme/textStyles.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/activityProvider.dart';

class StretchActivityPage extends StatefulWidget {
  const StretchActivityPage({super.key});

  @override
  State<StretchActivityPage> createState() => _StretchActivityPageState();
}

class _StretchActivityPageState extends State<StretchActivityPage>
    with WidgetsBindingObserver {
  static const int _secondsPerStep = 60;

  final List<_StretchStep> _steps = [
    _StretchStep(
      videoAsset: 'assets/videos/stretch-1.mp4',
      guideText: (loc) => loc.stretchGuid1,
    ),
    _StretchStep(
      videoAsset: 'assets/videos/stretch-2.mp4',
      guideText: (loc) => loc.stretchGuid2,
    ),
    _StretchStep(
      videoAsset: 'assets/videos/stretch-3.mp4',
      guideText: (loc) => loc.stretchGuid3,
    ),
    _StretchStep(
      videoAsset: 'assets/videos/stretch-4.mp4',
      guideText: (loc) => loc.stretchGuid4,
    ),
  ];

  VideoPlayerController? _videoController;
  Timer? _timer;

  int _currentStepIndex = 0;
  int _remainingSeconds = _secondsPerStep;

  bool _isPaused = false;
  bool _isLoadingVideo = true;
  bool _isChangingStep = false;
  bool _completionDialogIsOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadCurrentStep();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseActivity();
    }
  }

  Future<void> _loadCurrentStep() async {
    if (_isChangingStep) return;

    _isChangingStep = true;
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _remainingSeconds = _secondsPerStep;
        _isPaused = false;
        _isLoadingVideo = true;
      });
    }

    final oldController = _videoController;
    _videoController = null;

    if (oldController != null) {
      await oldController.pause();
      await oldController.dispose();
    }

    final controller = VideoPlayerController.asset(
      _steps[_currentStepIndex].videoAsset,
    );

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _videoController = controller;

      setState(() {
        _isLoadingVideo = false;
      });

      await controller.play();

      if (mounted) {
        _startTimer();
      }
    } catch (error) {
      await controller.dispose();

      if (!mounted) return;

      final loc = AppLocalizations.of(context)!;

      setState(() {
        _isLoadingVideo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.stretchVideoCantLoad),
        ),
      );
    } finally {
      _isChangingStep = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (_isPaused || _remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;

      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
        });

        _handleStepFinished();
      }
    });
  }

  Future<void> _handleStepFinished() async {
    await _videoController?.pause();

    final isLastStep = _currentStepIndex == _steps.length - 1;

    if (isLastStep) {
      await _showCompletionDialog();
    } else {
      await _goToStep(_currentStepIndex + 1);
    }
  }

  Future<void> _goToStep(int index) async {
    if (index < 0 || index >= _steps.length || _isChangingStep) {
      return;
    }

    _timer?.cancel();

    if (mounted) {
      setState(() {
        _currentStepIndex = index;
      });
    }

    await _loadCurrentStep();
  }

  Future<void> _togglePause() async {
    if (_isLoadingVideo || _videoController == null) return;

    if (_isPaused) {
      setState(() {
        _isPaused = false;
      });

      await _videoController?.play();

      if (mounted) {
        _startTimer();
      }
    } else {
      _pauseActivity();
    }
  }

  void _pauseActivity() {
    if (_isPaused || !mounted) return;

    _timer?.cancel();
    _videoController?.pause();

    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _showCompletionDialog() async {
    if (!mounted || _completionDialogIsOpen) return;

    final loc = AppLocalizations.of(context)!;

    _completionDialogIsOpen = true;
    _timer?.cancel();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            loc.stretchDialogTitle,
            textAlign: TextAlign.center,
          ),
          content: Text(
            loc.stretchDialogMessage,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _restartActivity();
              },
              child: Text(
                loc.repeat,
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                context.read<ActivityProvider>().saveActivityLog(
                  activityId: 8,
                  value: '',
                );

                Navigator.of(dialogContext).pop();

                if (mounted) {
                  context.pop('activity completed');
                }
              },
              child: Text(loc.finish),
            ),
          ],
        );
      },
    );

    _completionDialogIsOpen = false;
  }

  Future<void> _restartActivity() async {
    if (!mounted) return;

    setState(() {
      _currentStepIndex = 0;
    });

    await _loadCurrentStep();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  double get _stepProgress {
    return (_secondsPerStep - _remainingSeconds) / _secondsPerStep;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _timer?.cancel();
    _videoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final currentStep = _steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          loc.stretchActivity,
          style: AppTextStyles.semiBold(locale).copyWith(
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopSection(
              locale: locale,
              loc: loc,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    _buildVideo(loc),
                    const SizedBox(height: 24),
                    _buildGuideCard(
                      currentStep: currentStep,
                      loc: loc,
                    ),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(
              locale: locale,
              loc: loc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection({
    required Locale locale,
    required AppLocalizations loc,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${loc.step} ${_currentStepIndex + 1} '
                      '${loc.appOf} ${_steps.length}',
                  style: AppTextStyles.semiBold(locale).copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _formattedTime,
                      style: AppTextStyles.semiBold(locale).copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: _isPaused ? loc.resume : loc.pause,
                onPressed: _isLoadingVideo ? null : _togglePause,
                icon: Icon(
                  _isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(_steps.length, (index) {
              final isCompleted = index < _currentStepIndex;
              final isCurrent = index == _currentStepIndex;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == _steps.length - 1 ? 0 : 7,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 7,
                      child: LinearProgressIndicator(
                        value: isCompleted
                            ? 1
                            : isCurrent
                            ? _stepProgress
                            : 0,
                        backgroundColor:
                        Colors.black.withValues(alpha: 0.08),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_isPaused) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pause_circle_outline,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.activityPaused,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideo(AppLocalizations loc) {
    return AspectRatio(
      aspectRatio: 4.8 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: Colors.black,
          child: _isLoadingVideo
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : _videoController == null ||
              !_videoController!.value.isInitialized
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                loc.videoUnavailable,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          )
              : FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required _StretchStep currentStep,
    required AppLocalizations loc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        currentStep.guideText(loc),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          height: 1.55,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons({
    required Locale locale,
    required AppLocalizations loc,
  }) {
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirstStep || _isChangingStep
                  ? null
                  : () {
                _goToStep(_currentStepIndex - 1);
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color:
                isFirstStep ? AppColors.appGray : AppColors.primary,
              ),
              label: Text(
                loc.previous,
                style: TextStyle(
                  color:
                  isFirstStep ? AppColors.appGray : AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isChangingStep
                  ? null
                  : () {
                if (isLastStep) {
                  _timer?.cancel();
                  _videoController?.pause();
                  _showCompletionDialog();
                } else {
                  _goToStep(_currentStepIndex + 1);
                }
              },
              icon: Icon(
                isLastStep
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                isLastStep ? loc.finish : loc.next,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StretchStep {
  final String videoAsset;
  final String Function(AppLocalizations loc) guideText;

  const _StretchStep({
    required this.videoAsset,
    required this.guideText,
  });
}
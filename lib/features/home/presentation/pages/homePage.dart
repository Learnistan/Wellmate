// HOME PAGE

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wellmate/core/seed/defaultActivities.dart';
import 'package:wellmate/core/utils/getIcon.dart';
import 'package:wellmate/core/utils/getProperText.dart';

import '../../../../core/constants/feelings.dart';
import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/providers/journeyProvider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/utils/notificationMessages.dart';
import '../../../../core/utils/timeUtils.dart';
import '../../../../core/widgets/floatingBubbleButton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dailyActivities/presentation/providers/activityProvider.dart';
import '../../../shell/presentation/navigationProvider.dart';
import '../providers/homeProvider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialized = false;
  int selectedIndex = -1;

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _listenerAdded = false;
  int _previousLevel = -1;
  bool _initialVideoPositioned = false;
  Journeys? _previousJourney;

  late ConfettiController _confettiController;
  bool _confettiPlayed = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    ref.listenManual<int>(
      navigationIndexProvider,
          (previous, next) {
        if (next == 0) {
          _listenerAdded = false;
          context.read<HomeProvider>().loadLevel();
        }
      },
    );

    Future.microtask(() async {
      final homeProvider = context.read<HomeProvider>();
      final activityProvider = context.read<ActivityProvider>();

      await homeProvider.loadLevel();

      final shouldReload = await homeProvider.getLastCompletedDifference();

      if (shouldReload) {
        await activityProvider.loadActivities();
      }

      if ((homeProvider.dayDifference ?? 0) >= 2 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOneDayMissedDialog(homeProvider.dayDifference ?? 0);
        });
      }
    });
  }

  String _activityTitle(String key, AppLocalizations loc) {
    switch (key) {
      case 'activity_breathing':
        return loc.activity_breathing;
      case 'activity_movement':
        return loc.activity_movement;
      case 'activity_hydration':
        return loc.activity_hydration;
      case 'activity_body_scan':
        return loc.activity_body_scan;
      case 'activity_mood_calibration':
        return loc.activity_mood_calibration;
      default:
        return key;
    }
  }

  Map<String, String> _moodRecommendation(int index, AppLocalizations loc) {
    switch (index) {
      case 0:
        return {
          'activityKey': 'activity_hydration',
          'message': loc.feeling_calm_exp,
        };

      case 1:
        return {
          'activityKey': 'activity_movement',
          'message': loc.feeling_good_exp,
        };

      case 2:
        return {
          'activityKey': 'activity_mood_calibration',
          'message': loc.feeling_tired,
        };

      case 3:
        return {
          'activityKey': 'activity_breathing',
          'message': loc.feeling_anxious_exp,
        };

      case 4:
        return {
          'activityKey': 'activity_body_scan',
          'message': loc.feeling_sad_exp,
        };

      default:
        return {
          'activityKey': 'activity_movement',
          'message': loc.feeling_default_exp,
        };
    }
  }

  void _showMoodActivityModal({
    required int index,
    required Locale locale,
    required AppLocalizations loc
  }) {
    final data = _moodRecommendation(index, loc);
    final activity = defaultActivities.firstWhere(
          (activity) => activity.title == data['activityKey'],
    );


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      feelings[index]['emoji']!,
                      style: const TextStyle(fontSize: 46),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  getFeelingsLabel(feelings[index]['emoji']!, loc),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.introTitle(locale).copyWith(
                    fontSize: 24,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  data['message']!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.introDesc(locale).copyWith(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.darkerGray
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getIcon(activity.iconPath),
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getActivityTitle(activity.title, loc),
                              style: AppTextStyles.semiBold(locale).copyWith(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activity.duration} ${loc.minute}',
                              style: AppTextStyles.grayText(locale).copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    final activityProvider = context.read<ActivityProvider>();

                    final selectedActivity = activityProvider.activities.firstWhere(
                          (act) => act.title == activity.title,
                    );

                    if (selectedActivity.isActive) {
                      final result =
                      await context
                          .push<String>(
                        activity.route,
                      );

                      if (result == "activity completed") {
                        // COMPLETE ACTIVITY
                        await activityProvider
                            .toggleComplete(
                          activity,
                        );

                        final homeProvider = context.read<HomeProvider>();
                        await homeProvider.loadLevel();

                        final diff = TimeUtils().calculateDayDifference(homeProvider.lastDate ?? "");

                        if (diff != 0) {
                          // INCREASE LEVEL
                          await homeProvider.increaseLevel();

                        } else if (diff == 0 && homeProvider.level == 0){
                          await homeProvider.increaseLevel();
                        }
                      }
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(loc.doneActivityPopUpTitle),
                            content: Text(
                              loc.doneActivityPopUpMessage
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(loc.moodCalibrationOkay),
                              ),
                            ],
                          );
                        },
                      );
                    }

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    loc.start,
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    loc.journeyCompletionDialogButton2,
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> reinitializeVideo(String path) async {
    _videoReady = false;

    if (mounted) {
      setState(() {});
    }

    if (_videoController != null) {
      await _videoController!.dispose();
    }

    _videoController = VideoPlayerController.asset(path);

    await _videoController!.initialize();
    await _videoController!.setLooping(false);

    if (!_listenerAdded) {
      _listenerAdded = true;

      _videoController!.addListener(() {
        final videoValue = _videoController!.value;
        final loc = AppLocalizations.of(context)!;

        if (videoValue.isInitialized &&
            !videoValue.isPlaying &&
            !_confettiPlayed &&
            videoValue.position >= videoValue.duration &&
            videoValue.duration != Duration.zero) {
          _confettiPlayed = true;

          _confettiController.play();

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(loc.hydrationPopupTitle),
              content: Text(loc.journeyCompletionMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(loc.journeyCompletionDialogButton2),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);

                    ref.read(navigationIndexProvider.notifier).state = 3;

                    Future.delayed(const Duration(milliseconds: 300), () {
                      ref.read(scrollProfileToBottomProvider.notifier).state =
                      true;
                    });
                  },
                  child: Text(loc.journeyCompletionDialogButton1),
                ),
              ],
            ),
          );
        }

        final level = context.read<HomeProvider>().level;

        if (level < 0 || level >= pauseSeconds.length) {
          return;
        }

        final endSecond = pauseSeconds[level];
        final currentSecond = _videoController!.value.position.inSeconds;
        final isLastLevel = level == pauseSeconds.length - 1;

        if (!isLastLevel &&
            currentSecond >= endSecond &&
            _videoController!.value.isPlaying) {
          _videoController!.pause();
          _videoController!.seekTo(Duration(seconds: endSecond));
        }
      });
    }

    final currentLevel = context.read<HomeProvider>().level;

    await updateVideoForLevel(
      currentLevel,
      animate: false,
    );

    if (mounted) {
      setState(() {
        _videoReady = true;
      });
    }
  }

  Future<void> updateVideoForLevel(
      int level, {
        bool animate = true,
      }) async {
    if (_videoController == null) return;
    if (!_videoController!.value.isInitialized) return;
    if (level < 0 || level >= pauseSeconds.length) return;

    final targetSecond = pauseSeconds[level];

    if (!animate) {
      await _videoController!.pause();
      await _videoController!.seekTo(Duration(seconds: targetSecond));

      if (mounted) {
        setState(() {});
      }

      return;
    }

    int startSecond = 0;

    if (level > 0) {
      startSecond = pauseSeconds[level - 1];
    }

    await _videoController!.pause();
    await _videoController!.seekTo(Duration(seconds: startSecond));

    await Future.delayed(const Duration(milliseconds: 100));

    _confettiPlayed = false;

    await _videoController!.play();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _confettiController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final loc = AppLocalizations.of(context)!;
    final message = NotificationMessages.random(loc);

    context.read<HomeProvider>().refreshInactivityReminder(
      title: loc.notificationTitle,
      body: message.body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;

    final currentLevel = context.watch<HomeProvider>().level;

    final selectedJourney = context.watch<JourneyProvider>().selectedJourney;

    if (selectedJourney == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentJourney = journeysData[selectedJourney]!;

    if (_previousJourney != selectedJourney) {
      _previousJourney = selectedJourney;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await reinitializeVideo(currentJourney.animationPath);
      });
    }

    if (_previousLevel != currentLevel && _videoReady) {
      if (!_initialVideoPositioned) {
        _initialVideoPositioned = true;
        _previousLevel = currentLevel;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateVideoForLevel(
            currentLevel,
            animate: false,
          );
        });
      } else {
        _previousLevel = currentLevel;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateVideoForLevel(
            currentLevel,
            animate: true,
          );
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        TimeUtils.getDayTime(
                          morning: loc.morning_message,
                          noon: loc.noon_message,
                          afternoon: loc.afternoon_message,
                          evening: loc.evening_message,
                          night: loc.night_message,
                          midnight: loc.midnight_message,
                        ),
                        textAlign: TextAlign.start,
                        style: AppTextStyles.semiBold(locale).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/ic_notification.svg',
                        height: 33,
                        width: 33,
                      ),
                    ],
                  ),

                  Text(
                    TimeUtils.getFormattedDate(
                      DateTime.now(),
                      loc.localeName,
                    ),
                    style: AppTextStyles.grayText(locale).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Text(
                    loc.home_ask_feeling,
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.appGray.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        feelings.length,
                            (index) {
                          final isSelected = selectedIndex == index;

                          return Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });

                                _showMoodActivityModal(
                                  index: index,
                                  locale: locale,
                                  loc: loc,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 100,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.selectedCard
                                      : AppColors.lightCard,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      feelings[index]['emoji']!,
                                      style: const TextStyle(fontSize: 30),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      getFeelingsLabel(feelings[index]['emoji']!, loc),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.grayText(locale)
                                          .copyWith(
                                        fontSize: isSelected ? 11 : 10,
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.appGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getJourneyName(selectedJourney, loc),
                        style: AppTextStyles.semiBold(locale).copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            loc.read_about(
                              getJourneyName(selectedJourney, loc),
                            ),
                            style: AppTextStyles.grayText(locale).copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward,
                            color: AppColors.textPrimary,
                            size: 15,
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (_videoReady && _videoController != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: Directionality.of(context) == TextDirection.rtl ? 20 : null,
            right: Directionality.of(context) == TextDirection.ltr ? 20 : null,
            child: const FloatingBubbleButton(),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  List<int> get pauseSeconds {
    final selectedJourney = context.read<JourneyProvider>().selectedJourney;

    if (selectedJourney == null) {
      return [];
    }

    return journeysData[selectedJourney]?.pauseSeconds ?? [];
  }

  void _showOneDayMissedDialog(int dayDifference) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: dayDifference == 2
            ? Text(loc.oneDayMissedDialogTitle)
            : Text(loc.journeyResetDialogTitle),
        content: dayDifference == 2
            ? Text(loc.oneDayMissedDialogMessage)
            : Text(loc.journeyResetDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.moodCalibrationOkay),
          ),
        ],
      ),
    );
  }
}
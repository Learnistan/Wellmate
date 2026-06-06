// HOME PAGE

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/providers/journeyProvider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/utils/timeUtils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dailyActivities/presentation/providers/activityProvider.dart';
import '../providers/homeProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int selectedIndex = -1;

  VideoPlayerController? _videoController;

  bool _videoReady = false;

  bool _listenerAdded = false;

  int _previousLevel = -1;

  bool _initialVideoPositioned = false;

  Journeys? _previousJourney;

  @override
  void initState() {

    super.initState();

    Future.microtask(() async {

      final homeProvider =
      context.read<HomeProvider>();

      final activityProvider =
      context.read<ActivityProvider>();

      await homeProvider.initProgress();

      final shouldReload =
      await homeProvider
          .getLastCompletedDifference();

      if (shouldReload) {
        await activityProvider.loadActivities();
      }
    });
  }

  Future<void> reinitializeVideo(
      String path,
      ) async {

    _videoReady = false;

    if (mounted) {
      setState(() {});
    }

    if (_videoController != null) {
      await _videoController!.dispose();
    }

    _videoController =
        VideoPlayerController.asset(path);

    await _videoController!.initialize();

    await _videoController!.setLooping(false);

    if (!_listenerAdded) {

      _listenerAdded = true;

      _videoController!.addListener(() {

        final level =
            context.read<HomeProvider>().level;

        if (level < 0 ||
            level >= pauseSeconds.length) {
          return;
        }

        final endSecond =
        pauseSeconds[level];

        final currentSecond =
            _videoController!
                .value.position.inSeconds;

        if (currentSecond >= endSecond &&
            _videoController!
                .value.isPlaying) {

          _videoController!.pause();

          _videoController!.seekTo(
            Duration(seconds: endSecond),
          );
        }
      });
    }

    final currentLevel =
        context.read<HomeProvider>().level;

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

    if (_videoController == null) {
      return;
    }

    if (!_videoController!.value.isInitialized) {
      return;
    }

    if (level < 0 ||
        level >= pauseSeconds.length) {
      return;
    }

    final targetSecond =
    pauseSeconds[level];

    // INITIAL POSITION ONLY
    if (!animate) {

      await _videoController!.pause();

      await _videoController!.seekTo(
        Duration(seconds: targetSecond),
      );

      if (mounted) {
        setState(() {});
      }

      return;
    }

    // ANIMATION
    int startSecond = 0;

    if (level > 0) {
      startSecond =
      pauseSeconds[level - 1];
    }

    await _videoController!.pause();

    await _videoController!.seekTo(
      Duration(seconds: startSecond),
    );

    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    await _videoController!.play();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {

    _videoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final locale =
    Localizations.localeOf(context);

    final loc =
    AppLocalizations.of(context)!;

    final currentLevel =
        context.watch<HomeProvider>().level;

    final selectedJourney =
        context.watch<JourneyProvider>()
            .selectedJourney;

    if (selectedJourney == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentJourney =
    journeysData[selectedJourney]!;

    // JOURNEY CHANGED
    if (_previousJourney != selectedJourney) {

      _previousJourney = selectedJourney;

      WidgetsBinding.instance
          .addPostFrameCallback((_) async {

        await reinitializeVideo(
          currentJourney.animationPath,
        );
      });
    }

    // LEVEL CHANGED
    if (_previousLevel != currentLevel &&
        _videoReady) {

      // FIRST TIME -> ONLY POSITION VIDEO
      if (!_initialVideoPositioned) {

        _initialVideoPositioned = true;

        _previousLevel = currentLevel;

        WidgetsBinding.instance
            .addPostFrameCallback((_) {

          updateVideoForLevel(
            currentLevel,
            animate: false,
          );
        });

      } else {

        // REAL LEVEL CHANGE
        _previousLevel = currentLevel;

        WidgetsBinding.instance
            .addPostFrameCallback((_) {

          updateVideoForLevel(
            currentLevel,
            animate: true,
          );
        });
      }
    }

    final List<Map<String, String>>
    feelings = [
      {
        "emoji": "😌",
        "text": loc.feeling_calm
      },
      {
        "emoji": "😊",
        "text": loc.feeling_good
      },
      {
        "emoji": "😞",
        "text": loc.feeling_tired
      },
      {
        "emoji": "😣",
        "text": loc.feeling_anxious
      },
      {
        "emoji": "😔",
        "text": loc.feeling_sad
      },
    ];

    return Scaffold(

      backgroundColor:
      AppColors.background,

      body: SingleChildScrollView(

        child: Padding(

          padding:
          const EdgeInsets.all(20.0),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: [
                  Text(
                    TimeUtils.getDayTime(
                      morning: loc.morning_message,
                      noon: loc.noon_message,
                      afternoon:
                      loc.afternoon_message,
                      evening: loc.evening_message,
                      night: loc.night_message,
                      midnight:
                      loc.midnight_message,
                    ),
                    textAlign: TextAlign.start,
                    style:
                    AppTextStyles.semiBold(
                      locale,
                    ).copyWith(
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
                style:
                AppTextStyles.grayText(
                  locale,
                ).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              Text(
                loc.home_ask_feeling,
                style:
                AppTextStyles.semiBold(
                  locale,
                ).copyWith(
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 15),

              Container(

                padding:
                const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 0,
                ),

                decoration: BoxDecoration(

                  border: Border.all(
                    color: AppColors.appGray
                        .withOpacity(0.3),
                    width: 1,
                  ),

                  borderRadius:
                  const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),

                child: Row(

                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

                  children: List.generate(
                    feelings.length,

                        (index) {

                      final isSelected =
                          selectedIndex ==
                              index;

                      return Expanded(

                        child: InkWell(

                          onTap: () {

                            setState(() {
                              selectedIndex =
                                  index;
                            });
                          },

                          child:
                          AnimatedContainer(

                            duration:
                            const Duration(
                              milliseconds:
                              500,
                            ),

                            height: 100,

                            margin:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 5,
                            ),

                            decoration:
                            BoxDecoration(

                              color:
                              isSelected
                                  ? AppColors
                                  .selectedCard
                                  : AppColors
                                  .lightCard,

                              borderRadius:
                              const BorderRadius
                                  .all(
                                Radius.circular(
                                  50,
                                ),
                              ),
                            ),

                            child: Column(

                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                              children: [

                                Text(
                                  feelings[index]
                                  ['emoji']!,

                                  style:
                                  const TextStyle(
                                    fontSize: 30,
                                  ),
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                Text(

                                  feelings[index]
                                  ['text']!,

                                  style:
                                  AppTextStyles
                                      .grayText(
                                    locale,
                                  )
                                      .copyWith(

                                    fontSize:
                                    isSelected
                                        ? 11
                                        : 10,

                                    color:
                                    isSelected
                                        ? AppColors
                                        .textPrimary
                                        : AppColors
                                        .appGray,
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.carpet_title,
                    style:
                    AppTextStyles.semiBold(
                      locale,
                    ).copyWith(
                      color:
                      AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      Text(
                        loc.read_about,
                        style:
                        AppTextStyles.grayText(
                          locale,
                        ).copyWith(
                          color: AppColors
                              .textPrimary,
                          fontSize: 10,
                          decoration:
                          TextDecoration
                              .underline,
                          decorationColor:
                          AppColors
                              .textPrimary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward,
                        color:
                        AppColors.textPrimary,
                        size: 15,
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              // VIDEO
              if (_videoReady &&
                  _videoController != null)

                ClipRRect(

                  borderRadius:
                  BorderRadius.circular(20),

                  child: AspectRatio(

                    aspectRatio:
                    _videoController!
                        .value.aspectRatio,

                    child: VideoPlayer(
                      _videoController!,
                    ),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<int> get pauseSeconds {

    final selectedJourney =
        context.read<JourneyProvider>()
            .selectedJourney;

    if (selectedJourney == null) {
      return [];
    }

    return journeysData[selectedJourney]
        ?.pauseSeconds ?? [];
  }
}
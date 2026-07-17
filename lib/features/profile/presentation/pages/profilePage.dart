import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/providers/journeyProvider.dart';

import '../../../../core/enums/journeys.dart';
import '../../../../core/localization/localeProvider.dart';
import '../../../../core/services/notificationService.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/getProperText.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/provider/authProvider.dart';
import '../../../shell/presentation/navigationProvider.dart';
import '../providers/profileProvider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final NotificationService _notificationService = NotificationService();

  static const int _sleepId = 201;
  static const int _foodId = 202;
  static const int _postureId = 203;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final profileProvider = context.read<ProfileProvider>();

      await profileProvider.loadProfileData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }

      ref.read(scrollProfileToBottomProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      scrollProfileToBottomProvider,
          (previous, next) {
        if (next) {
          _scrollToBottom();
        }
      },
    );

    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = context.watch<ProfileProvider>();
    final selectedJourney =
        context.watch<JourneyProvider>().selectedJourney;

    final unlockedJourneys = profileProvider.unlockedJourneys;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.selectedCard,
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                loc.profile,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                loc.profileSubTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.appGray,
                ),
              ),

              const SizedBox(height: 30),

              _SectionCard(
                title: loc.chooseLanguage,
                icon: Icons.language,
                children: [
                  _OptionTile(
                    title: loc.english,
                    subtitle: 'Use the app in English',
                    onTap: () {
                      context.read<LocaleProvider>().changeLocale('en');
                    },
                  ),
                  _OptionTile(
                    title: loc.dari,
                    subtitle: 'استفاده از برنامه به زبان دری',
                    onTap: () {
                      context.read<LocaleProvider>().changeLocale('fa');
                    },
                  ),
                  _OptionTile(
                    title: loc.pashto,
                    subtitle: 'اپلیکیشن په پښتو ژبه وکاروئ',
                    onTap: () {
                      context.read<LocaleProvider>().changeLocale('ps');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _SectionCard(
                title: loc.remindersTitle,
                icon: Icons.notifications_active_rounded,
                children: [
                  _ReminderTile(
                    title: loc.sleepReminderTitle,
                    subtitle: loc.reminderSubtitle,
                    icon: Icons.bedtime_rounded,
                    value: profileProvider.sleepReminder,
                    time: profileProvider.sleepReminderTime,
                    onTimePressed: () {
                      _selectReminderTime(
                        initialTime: profileProvider.sleepReminderTime,
                        notificationId: _sleepId,
                        reminderEnabled:
                        profileProvider.sleepReminder,
                        notificationTitle:
                        loc.sleepReminderDialogTitle,
                        notificationMessage:
                        loc.sleepReminderMessage,
                        saveTime:
                        profileProvider.setSleepReminderTime,
                        loc: loc
                      );
                    },
                    onChanged: (value) {
                      _handleReminderToggle(
                        preferenceKey: 'sleepReminder',
                        popupKey: 'sleepReminderPopupShown',
                        value: value,
                        notificationId: _sleepId,
                        notificationTitle:
                        loc.sleepReminderDialogTitle,
                        notificationMessage:
                        loc.sleepReminderMessage,
                        time: profileProvider.sleepReminderTime,
                        popupTitle: loc.sleepReminderTitle,
                        popupMessage:
                        loc.sleepReminderPopUpMessage,
                        updateState:
                        profileProvider.setSleepReminder,
                        loc: loc,
                      );
                    },
                  ),

                  _ReminderTile(
                    title: loc.foodReminderTitle,
                    subtitle: loc.reminderSubtitle,
                    icon: Icons.restaurant_rounded,
                    value: profileProvider.foodReminder,
                    time: profileProvider.foodReminderTime,
                    onTimePressed: () {
                      _selectReminderTime(
                        initialTime: profileProvider.foodReminderTime,
                        notificationId: _foodId,
                        reminderEnabled:
                        profileProvider.foodReminder,
                        notificationTitle:
                        loc.foodReminderDialogTitle,
                        notificationMessage:
                        loc.foodReminderMessage,
                        saveTime:
                        profileProvider.setFoodReminderTime,
                        loc: loc
                      );
                    },
                    onChanged: (value) {
                      _handleReminderToggle(
                        preferenceKey: 'foodReminder',
                        popupKey: 'foodReminderPopupShown',
                        value: value,
                        notificationId: _foodId,
                        notificationTitle:
                        loc.foodReminderDialogTitle,
                        notificationMessage:
                        loc.foodReminderMessage,
                        time: profileProvider.foodReminderTime,
                        popupTitle: loc.foodReminderTitle,
                        popupMessage:
                        loc.foodReminderPopUpMessage,
                        updateState:
                        profileProvider.setFoodReminder,
                        loc: loc,
                      );
                    },
                  ),

                  _ReminderTile(
                    title: loc.postureReminderTitle,
                    subtitle: loc.reminderSubtitle,
                    icon: Icons.accessibility_new_rounded,
                    value: profileProvider.postureReminder,
                    time: profileProvider.postureReminderTime,
                    onTimePressed: () {
                      _selectReminderTime(
                        initialTime:
                        profileProvider.postureReminderTime,
                        notificationId: _postureId,
                        reminderEnabled:
                        profileProvider.postureReminder,
                        notificationTitle:
                        loc.postureReminderDialogTitle,
                        notificationMessage:
                        loc.postureReminderMessage,
                        saveTime:
                        profileProvider.setPostureReminderTime,
                        loc: loc
                      );
                    },
                    onChanged: (value) {
                      _handleReminderToggle(
                        preferenceKey: 'postureReminder',
                        popupKey: 'postureReminderPopupShown',
                        value: value,
                        notificationId: _postureId,
                        notificationTitle:
                        loc.postureReminderDialogTitle,
                        notificationMessage:
                        loc.postureReminderMessage,
                        time: profileProvider.postureReminderTime,
                        popupTitle: loc.postureReminderTitle,
                        popupMessage:
                        loc.postureReminderPopUpMessage,
                        updateState:
                        profileProvider.setPostureReminder,
                        loc: loc,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _SectionCard(
                title: loc.chooseJourney,
                icon: Icons.route_rounded,
                children: [
                  ...unlockedJourneys.map((entry) {
                    final journeyEnum = entry.key;
                    final journey = entry.value;

                    return _JourneyTile(
                      title: getJourneyName(entry.key, loc),
                      imagePath: journey.thumbnailImage,
                      isSelected: selectedJourney == journeyEnum,
                      onTap: () => _changeJourney(journeyEnum),
                    );
                  }),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/journeys');
                      },
                      icon: const Icon(Icons.add),
                      label: Text(loc.chooseJourney),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.selectedCard,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (authProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                ElevatedButton.icon(
                  onPressed: authProvider.logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(loc.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectReminderTime({
    required TimeOfDay initialTime,
    required int notificationId,
    required bool reminderEnabled,
    required String notificationTitle,
    required String notificationMessage,
    required Future<void> Function(TimeOfDay time) saveTime,
    required AppLocalizations loc,
  }) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: loc.chooseReminderTime,
      cancelText: loc.cancel,
      confirmText: loc.save,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.lightCard,
              hourMinuteTextColor: AppColors.textPrimary,
              dialHandColor: AppColors.textPrimary,
              dialBackgroundColor: AppColors.background,
              dayPeriodTextColor: AppColors.textPrimary,
              entryModeIconColor: AppColors.textPrimary,
            ),
            colorScheme: ColorScheme.light(
              primary: AppColors.textPrimary,
              surface: AppColors.lightCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) {
      return;
    }

    await saveTime(selectedTime);

    /*
     * When a reminder is already active, cancel its previous schedule
     * and create a new schedule using the newly selected time.
     */
    if (reminderEnabled) {
      await _notificationService.cancelReminder(notificationId);

      await _notificationService.scheduleDailyReminder(
        id: notificationId,
        title: notificationTitle,
        message: notificationMessage,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reminderEnabled
              ? '${loc.reminderChangeTo} ${selectedTime.format(context)}'
              : loc.timeSavedAs(selectedTime.format(context))
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleReminderToggle({
    required String preferenceKey,
    required String popupKey,
    required bool value,
    required int notificationId,
    required String notificationTitle,
    required String notificationMessage,
    required TimeOfDay time,
    required String popupTitle,
    required String popupMessage,
    required Future<void> Function(bool value) updateState,
    required AppLocalizations loc,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!value) {
      await updateState(false);
      await _notificationService.cancelReminder(notificationId);
      return;
    }

    final popupShown = prefs.getBool(popupKey) ?? false;

    if (!popupShown) {
      final shouldActivate = await _showReminderPopup(
        title: popupTitle,
        message: popupMessage,
        loc: loc,
      );

      /*
       * This keeps your previous behavior:
       * the information popup is shown only once.
       */
      await prefs.setBool(popupKey, true);

      if (shouldActivate != true) {
        await updateState(false);
        return;
      }
    }

    await updateState(true);

    await _notificationService.scheduleDailyReminder(
      id: notificationId,
      title: notificationTitle,
      message: notificationMessage,
      hour: time.hour,
      minute: time.minute,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${loc.reminderActivatedTo} ${time.format(context)}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showReminderPopup({
    required String title,
    required String message,
    required AppLocalizations loc,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.selectedCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.appGray,
              height: 1.5,
            ),
          ),
          actionsPadding:
          const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                loc.journeyCompletionDialogButton2,
                style: TextStyle(
                  color: AppColors.appGray,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.selectedCard,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(loc.activate),
            ),
          ],
        );
      },
    );
  }

  void _changeJourney(Journeys journey) {
    context.read<JourneyProvider>().changeJourney(journey);
    ref.read(navigationIndexProvider.notifier).state = 0;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.appGray.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.selectedCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final TimeOfDay time;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTimePressed;

  const _ReminderTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.time,
    required this.onChanged,
    required this.onTimePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: value
                ? AppColors.textPrimary.withOpacity(0.22)
                : AppColors.appGray.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.lightCard.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.appGray,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time.format(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Change time',
              onPressed: onTimePressed,
              icon: const Icon(
                Icons.schedule_rounded,
                color: AppColors.textPrimary,
              ),
            ),

            Switch(
              value: value,
              activeColor: AppColors.textPrimary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.appGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.appGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _JourneyTile({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.selectedCard
              : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary.withOpacity(0.35)
                : AppColors.appGray.withOpacity(0.12),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Image.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.appGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/providers/journeyProvider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/utils/getProperText.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/homeProvider.dart';
import '../../../shell/presentation/navigationProvider.dart';

class SelectJourneyPage extends ConsumerStatefulWidget {
  const SelectJourneyPage({super.key});

  @override
  ConsumerState<SelectJourneyPage> createState() => _SelectJourneyPageState();
}

class _SelectJourneyPageState extends ConsumerState<SelectJourneyPage> {
  bool _isSaving = false;

  Future<void> _selectJourney(Journeys journeyKey) async {
    setState(() {
      _isSaving = true;
    });

    await context.read<JourneyProvider>().saveSelectedJourney(journeyKey);

    final homeProvider = context.read<HomeProvider>();
    await homeProvider.initProgress();

    if (!context.mounted) return;

    ref.read(navigationIndexProvider.notifier).state = 0;
    context.go('/shell');
  }

  void _openJourneyDetails({
    required BuildContext context,
    required Journeys journeyKey,
    required AppLocalizations loc,
    required Locale locale,
  }) {
    final journey = journeysData[journeyKey]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(20),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  Container(
                    height: 190,
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Image.asset(
                      journey.thumbnailImage,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getJourneyCity(journeyKey, loc),
                          style: AppTextStyles.semiBold(locale).copyWith(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.appGray,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '14 ${loc.days}',
                        style: AppTextStyles.introDesc(locale).copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    getJourneyName(journeyKey, loc),
                    style: AppTextStyles.introTitle(locale).copyWith(
                      fontSize: 24,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    getJourneyDescription(journeyKey, loc),
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                   getJourneyExplanation(journeyKey, loc),
                    style: AppTextStyles.introDesc(locale).copyWith(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.darkerGray
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                      Navigator.pop(context);
                      _selectJourney(journeyKey);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      loc.selectJourney,
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
                      loc.chooseAnotherJourney,
                      style: AppTextStyles.semiBold(locale).copyWith(
                        fontSize: 14,
                        color: Colors.grey.shade700,
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

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;
    final journeys = Journeys.values;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),

                Text(
                  loc.selectJourneyPageTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.introTitle(locale),
                ),

                const SizedBox(height: 10),

                Text(
                  loc.selectJourneyPageSubTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.introDesc(locale).copyWith(
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView.builder(
                    itemCount: journeys.length,
                    itemBuilder: (context, index) {
                      final journeyKey = journeys[index];
                      final journey = journeysData[journeyKey]!;

                      return GestureDetector(
                        onTap: _isSaving
                            ? null
                            : () {
                          _openJourneyDetails(
                            context: context,
                            journeyKey: journeyKey,
                            loc: loc,
                            locale: locale,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  journey.thumbnailImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        getJourneyCity(journeyKey, loc),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.introDesc(locale)
                                            .copyWith(fontSize: 12),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        getJourneyName(journeyKey, loc),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.semiBold(locale)
                                            .copyWith(fontSize: 16),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        getJourneyDescription(journeyKey, loc),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.introDesc(locale)
                                            .copyWith(fontSize: 10),
                                      ),

                                      const SizedBox(height: 7),

                                      Text(
                                        '14 ${loc.days}',
                                        style: AppTextStyles.introDesc(locale)
                                            .copyWith(fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
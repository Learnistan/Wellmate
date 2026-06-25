import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/utils/getProperText.dart';

import '../../../../core/appController.dart';
import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';

class SelectJourneyPage extends StatefulWidget {
  final AppController appController;

  const SelectJourneyPage({super.key, required this.appController});

  @override
  State<SelectJourneyPage> createState() => _SelectJourneyPage();
}

class _SelectJourneyPage extends State<SelectJourneyPage> {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;
    final journeys = Journeys.values;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
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
              style: AppTextStyles.introDesc(locale).copyWith(fontSize: 14),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: ListView.builder(
                itemCount: journeys.length,
                itemBuilder: (context, index) {
                  final journeyKey = journeys[index];
                  final journey = journeysData[journeyKey]!;

                  return GestureDetector(
                    onTap: () async {
                      await saveSelectedJourney(journeyKey);

                      widget.appController.completeOnboarding();
                      context.go('/home');
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
                            borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
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
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Future<void> saveSelectedJourney(Journeys journey) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_journey',
      journey.name,
    );
  }
}
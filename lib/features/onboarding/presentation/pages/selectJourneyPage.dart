import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/theme/textStyles.dart';

import '../../../../core/appController.dart';
import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/theme/colors.dart';

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
              "Your Journey Awaits",
              textAlign: TextAlign.center,
              style: AppTextStyles.introTitle(locale),
            ),

            const SizedBox(height: 10),

            Text(
              "Choose a cultural journey that will grow over 14 days",
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
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                            child: Image.asset(
                              journey.thumbnailImage,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    journey.city,
                                    style: AppTextStyles.introDesc(locale).copyWith(
                                      fontSize: 12
                                    )
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    journey.name,
                                    style: AppTextStyles.semiBold(locale).copyWith(
                                      fontSize: 16
                                    )
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    journey.description,
                                    style: AppTextStyles.introDesc(locale).copyWith(
                                      fontSize: 10
                                    )
                                  ),

                                  SizedBox(height: 7,),

                                  Text(
                                      '14 days',
                                      style: AppTextStyles.introDesc(locale).copyWith(
                                          fontSize: 9
                                      )
                                  ),
                                ],
                              ),
                            ),
                          ),

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

                          const SizedBox(width: 10),
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
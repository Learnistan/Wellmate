import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/providers/journeyProvider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/utils/getProperText.dart';
import '../../../../l10n/app_localizations.dart';

class SelectJourneyPage extends StatefulWidget {
  const SelectJourneyPage({super.key});

  @override
  State<SelectJourneyPage> createState() => _SelectJourneyPageState();
}

class _SelectJourneyPageState extends State<SelectJourneyPage> {
  bool _isSaving = false;

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
                            : () async {
                          setState(() {
                            _isSaving = true;
                          });

                          await context
                              .read<JourneyProvider>()
                              .saveSelectedJourney(journeyKey);

                          if (!context.mounted) return;

                          context.go('/shell');
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
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(16),
                                ),
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
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/utils/getIcon.dart';
import 'package:wellmate/core/utils/getProperText.dart';

import '../../../../core/localization/localeProvider.dart';
import '../../../../core/seed/defaultGames.dart';
import '../../../../l10n/app_localizations.dart';

class MindfulGamesPage extends StatelessWidget {
  const MindfulGamesPage({super.key});

  Color _getColor(int index) {
    const colors = [
      Colors.purple,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.indigo,
      Colors.blue,
      Colors.pink,
    ];

    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale =
    Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsetsGeometry.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.gamesTabTitle,
              style: AppTextStyles.semiBold(
                locale,
              ).copyWith(
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 20),

            // Header section
            Text(
              loc.gamesTabSubTitle,
              style: AppTextStyles.semiBold(locale).copyWith(color: Colors.black)
            ),
            const SizedBox(height: 6),
            Text(
              loc.gamesTabGuid,
              style: AppTextStyles.grayText(locale).copyWith(color: AppColors.darkerGray)
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  // Game cards
                  ...defaultGames.map((game) {
                    final color = _getColor(game.id ?? 0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          context.push(game.route);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOP ROW
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      getIcon(game.iconPath),
                                      color: color,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Title + benefit
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getGameTexts(game.title, loc)[0],
                                          style: AppTextStyles.semiBold(locale).copyWith(color: Colors.black)
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            getGameTexts(game.title, loc)[1],
                                            style: AppTextStyles.semiBold(locale).copyWith(fontSize: 11, color: color)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Duration badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${game.duration} ${loc.minute}",
                                      style: AppTextStyles.grayText(locale).copyWith(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Description
                              Text(
                                getGameTexts(game.title, loc)[2],
                                  style: AppTextStyles.grayText(locale).copyWith(color: AppColors.darkerGray, fontSize: 12)
                              ),

                              const SizedBox(height: 12),

                              // CTA row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    loc.start,
                                    style: AppTextStyles.semiBold(locale).copyWith(color: color, fontSize: 14)
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: color,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            SizedBox(height: 40,)
          ],
        ),
      )
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/utils/getIcon.dart';
import 'package:wellmate/core/utils/getProperText.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/activity.dart';
import '../providers/activityProvider.dart';

class DailyActivitiesPage extends StatefulWidget {
  const DailyActivitiesPage({super.key});

  @override
  State<DailyActivitiesPage> createState() => _DailyActivitiesPageState();
}

class _DailyActivitiesPageState extends State<DailyActivitiesPage> {

  final List activityColors = [
    {"dark": Colors.pink[200], "light": Colors.pink[50]},
    {"dark": Colors.blue[200], "light": Colors.blue[50]},
    {"dark": Colors.green[200], "light": Colors.green[50]},
    {"dark": Colors.purple[200], "light": Colors.purple[50]},
    {"dark": Colors.orange[200], "light": Colors.orange[50]},
    {"dark": Colors.teal[200], "light": Colors.teal[50]}
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.microtask(() {
      Provider.of<ActivityProvider>(context, listen: false)
          .seedIfEmpty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    final activityProvider = Provider.of<ActivityProvider>(context);
    final dbActivities = activityProvider.activities;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            Text(
              loc.daily_activity_title,
              style: AppTextStyles.semiBold(locale).copyWith(
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              loc.daily_activity_subtitle,
              style: AppTextStyles.semiBold(locale),
            ),

            const SizedBox(height: 20,),

            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: AppColors.appGray,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.add_activity_title,
                    style: AppTextStyles.grayText(locale).copyWith(color: Colors.grey[800]),
                  ),

                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        print("hi");
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: dbActivities.length,
                itemBuilder: (context, index) {
                  final item = dbActivities[index];
                  final color =
                  activityColors[index % activityColors.length];

                  return GestureDetector(
                    onTap: () async {
                      final result = await context.push<bool>(item.route);

                      if (result == true) {
                        await activityProvider.toggleComplete(item);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white,
                            color["light"],
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            width: 6,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color["dark"],
                              borderRadius: const BorderRadius.all(Radius.circular(10))
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    getIcon(item.iconPath),
                                    color: color["dark"],
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getActivityTitle(item.title, loc),
                                          style:
                                          AppTextStyles.semiBold(locale)
                                              .copyWith(
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          "${item.time} ${loc.minute}",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    item.isCompleted
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ],
                              ),
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
}
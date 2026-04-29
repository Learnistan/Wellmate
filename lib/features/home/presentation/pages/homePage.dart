import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellmate/core/constants/assets.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/utils/timeUtils.dart';

import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;

    final List<Map<String, String>> feelings = [
      {"emoji": "😌", "text": loc.feeling_calm},
      {"emoji": "😊", "text": loc.feeling_good},
      {"emoji": "😞", "text": loc.feeling_tired},
      {"emoji": "😣", "text": loc.feeling_anxious},
      {"emoji": "😔", "text": loc.feeling_sad},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

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
                        midnight: loc.midnight_message),
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
                style: AppTextStyles.grayText(locale).copyWith(fontWeight: FontWeight.bold),
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
                            onTap: (){
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                  color: isSelected ? AppColors.selectedCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(50)
                                  )
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    feelings[index]['emoji']!,
                                    style: TextStyle(fontSize: 30),
                                  ),
                                  SizedBox(height: 10,),
                                  Text(
                                    feelings[index]['text']!,
                                    style: AppTextStyles.grayText(locale).copyWith(
                                        fontSize: isSelected ? 11 : 10,
                                        color: isSelected ? AppColors.textPrimary : AppColors.appGray
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                height: 430,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.appGreen,
                      AppColors.primary,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.carpet_title,
                      style: AppTextStyles.semiBold(locale).copyWith(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 5,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          loc.read_about,
                          style: AppTextStyles.grayText(locale).copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            decoration:
                            TextDecoration.underline,
                            decorationColor: Colors.white
                          ),
                        ),
                        SizedBox(width: 5,),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 15,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Image.asset(
                          AppAssets.carpet,
                        height: 100,
                      )
                    )
                  ],
                ),
              ),

              SizedBox(height: 80,)
            ],
          ),
        ),
      )
    );
  }
}
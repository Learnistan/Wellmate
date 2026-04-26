import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/constants/assets.dart';
import 'package:wellmate/core/theme/textStyles.dart';

import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/provider/authProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> feelings = [
    {"emoji": "😌", "text": "Calm"},
    {"emoji": "😊", "text": "Good"},
    {"emoji": "😞", "text": "Tired"},
    {"emoji": "😣", "text": "Anxious"},
    {"emoji": "😔", "text": "Sad"},
  ];

  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final String text1 = "Good morning Ahmad";
    final String text2 = "Saturday, 25 April";
    final String text3 = "How are you feeling today?";
    final String text4 = "Herat Carpet Weaving";
    final String text5 = "Read about Herat's carpet";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    text1,
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
                text2,
                style: AppTextStyles.grayText(locale).copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 35),

              Text(
                text3,
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
                      text4,
                      style: AppTextStyles.semiBold(locale).copyWith(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 5,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          text5,
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

              if (authProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    authProvider.logout();
                  },
                  child: const Text("logout"),
                ),

              SizedBox(height: 80,)
            ],
          ),
        ),
      )
    );
  }
}
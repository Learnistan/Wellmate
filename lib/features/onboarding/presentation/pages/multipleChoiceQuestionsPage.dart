import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/appController.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';
import '../../../../l10n/app_localizations.dart';

class MultipleChoiceQuestionsPage extends StatefulWidget {
  final AppController appController;

  const MultipleChoiceQuestionsPage({super.key, required this.appController});

  @override
  State<MultipleChoiceQuestionsPage> createState() =>
      _MultipleChoiceQuestionsPageState();
}

class _MultipleChoiceQuestionsPageState
    extends State<MultipleChoiceQuestionsPage> {
  int currentIndex = 0;
  int? selectedIndex;

  final List<Map<String, dynamic>> questions = [
    {
      "question": "how is your heart feeling right now?",
      "answers": [
        "Calm and at peace",
        "A little heavy",
        "Restless"
      ]
    },
    {
      "question": "How is your body feeling today?",
      "answers": [
        "Relaxed and light",
        "Tightness in my chest or shoulders",
        "Very tired and heavy"
      ]
    },
    {
      "question":
      "or are you feeling pulled away by difficult memories or worries?",
      "answers": [
        "My mind is clear",
        "Pulled by a few worries",
        "Caught in an emotional storm"
      ]
    },
    {
      "question": "how much energy do you feel you have to give?",
      "answers": [
        "I have energy for the day",
        "Just enough for the basics",
        "I need quiet rest today"
      ]
    },
    {
      "question":
      "How connected are you feeling to your family or friends today?",
      "answers": [
        "Strongly connected",
        "A bit lonely today",
        "I prefer to be alone right now"
      ]
    },
    {
      "question": "what feels like the best way to find comfort?",
      "answers": [
        "Prayer or quiet reflection",
        "Talking with someone I trust",
        "A calming distraction"
      ]
    },
  ];

  void nextQuestion() {
    if (selectedIndex == null) return;

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
      });
    } else {
      widget.appController.completeOnboarding();
      context.go('/home');
    }
  }

  void goBack(BuildContext context) {
    if (currentIndex == 0) {
      context.pop();
    } else {
      setState(() {
        currentIndex--;
        selectedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;

    final isRTL =
        locale.languageCode == 'fa' || locale.languageCode == 'ps';

    final question = questions[currentIndex];

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => goBack(context),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / questions.length,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Text(
                        question["question"],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.semiBold(locale).copyWith(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 30),

                      ...List.generate(question["answers"].length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerTile(
                            title: question["answers"][index],
                            isSelected: selectedIndex == index,
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                AppButton(
                  text: currentIndex == questions.length - 1
                      ? loc.continueText
                      : loc.next,
                  onPressed:
                  selectedIndex != null ? nextQuestion : () {},
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final size = MediaQuery.of(context).size;

    final tileHeight = size.height * 0.075;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: double.infinity,
        height: tileHeight < 56 ? 56 : tileHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color:
            isSelected ? AppColors.primary : AppColors.secondary,
            width: 2,
          ),
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.semiBold(locale).copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),

            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                  isSelected ? AppColors.primary : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
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
      "question": "q1",
      "answers": ["q1_a1", "q1_a2", "q1_a3"]
    },
    {
      "question": "q2",
      "answers": ["q2_a1", "q2_a2", "q2_a3"]
    },
    {
      "question": "q3",
      "answers": ["q3_a1", "q3_a2", "q3_a3"]
    },
    {
      "question": "q4",
      "answers": ["q4_a1", "q4_a2", "q4_a3"]
    },
    {
      "question": "q5",
      "answers": ["q5_a1", "q5_a2", "q5_a3"]
    },
    {
      "question": "q6",
      "answers": ["q6_a1", "q6_a2", "q6_a3"]
    },
  ];

  /// 🔥 MAP QUESTION KEYS
  String getQuestion(AppLocalizations loc, String key) {
    switch (key) {
      case 'q1': return loc.q1;
      case 'q2': return loc.q2;
      case 'q3': return loc.q3;
      case 'q4': return loc.q4;
      case 'q5': return loc.q5;
      case 'q6': return loc.q6;
      default: return key;
    }
  }

  /// 🔥 MAP ANSWER KEYS
  String getAnswer(AppLocalizations loc, String key) {
    switch (key) {
      case 'q1_a1': return loc.q1_a1;
      case 'q1_a2': return loc.q1_a2;
      case 'q1_a3': return loc.q1_a3;

      case 'q2_a1': return loc.q2_a1;
      case 'q2_a2': return loc.q2_a2;
      case 'q2_a3': return loc.q2_a3;

      case 'q3_a1': return loc.q3_a1;
      case 'q3_a2': return loc.q3_a2;
      case 'q3_a3': return loc.q3_a3;

      case 'q4_a1': return loc.q4_a1;
      case 'q4_a2': return loc.q4_a2;
      case 'q4_a3': return loc.q4_a3;

      case 'q5_a1': return loc.q5_a1;
      case 'q5_a2': return loc.q5_a2;
      case 'q5_a3': return loc.q5_a3;

      case 'q6_a1': return loc.q6_a1;
      case 'q6_a2': return loc.q6_a2;
      case 'q6_a3': return loc.q6_a3;

      default: return key;
    }
  }

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

                /// TOP ROW
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

                /// CENTER CONTENT
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// ✅ QUESTION
                      Text(
                        getQuestion(loc, question["question"] as String),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.semiBold(locale).copyWith(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// ✅ ANSWERS
                      ...List.generate(question["answers"].length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerTile(
                            title: getAnswer(
                                loc, question["answers"][index] as String),
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

                /// BUTTON
                AppButton(
                  text: currentIndex == questions.length - 1
                      ? loc.continueText
                      : loc.next,
                  onPressed:
                  selectedIndex != null ? nextQuestion : null,
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
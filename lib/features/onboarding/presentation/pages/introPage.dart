import 'package:flutter/material.dart';
import '../../../../core/appController.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';

class IntroPage extends StatefulWidget {
  final AppController appController;

  const IntroPage({super.key, required this.appController});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      widget.appController.completeOnboarding();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _skip() {
    widget.appController.completeOnboarding();
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  l10n.skip,
                  style: AppTextStyles.title,
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  IntroContent(
                    title: l10n.introTitle1,
                    description: l10n.introDesc1,
                    imagePath: "assets/images/onboarding-01.webp",
                    locale: locale,
                  ),
                  IntroContent(
                    title: l10n.introTitle2,
                    description: l10n.introDesc2,
                    imagePath: "assets/images/onboarding-02.webp",
                    locale: locale,
                  ),
                  IntroContent(
                    title: l10n.introTitle3,
                    description: l10n.introDesc3,
                    imagePath: "assets/images/onboarding-03.webp",
                    locale: locale,
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  width: _currentPage == index ? 33 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: 326,
                height: 48,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? l10n.start : l10n.next,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class IntroContent extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final Locale locale;

  const IntroContent({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 330,
            width: 374,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 30),

          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.introTitle(locale),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.semiBold(locale).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
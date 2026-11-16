import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/appController.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';

class IntroPage extends StatefulWidget {

  const IntroPage({super.key});

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
      context.go('/questions');
    }
  }

  void _skip() {
    context.go('/questions');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    l10n.skip,
                    style: AppTextStyles.semiBold(locale),
                  ),
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
                child: AppButton(
                  text: _currentPage == 2 ? l10n.start : l10n.next,
                  onPressed: _nextPage,
                ),

            ),

            const SizedBox(height: 20),
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
    final size = MediaQuery.of(context).size;
    final width = MediaQuery.of(context).size.width;
    final fontSize = (width * 0.075).clamp(24, 32).toDouble();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: size.height * 0.3,
              width: size.width * 0.8,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.introTitle(locale).copyWith(
              fontSize: fontSize,
            ),
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
      ),
    );
  }
}
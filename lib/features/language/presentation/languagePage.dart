import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/theme/colors.dart';
import '../../../core/localization/localeProvider.dart';
import '../../../l10n/app_localizations.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final provider = context.watch<LocaleProvider>();

    String currentLang = provider.locale.languageCode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(),

              Text(
                loc.chooseLanguage,
                textAlign: TextAlign.center,
                style: AppTextStyles.semiBold(locale).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary
                ),
              ),

              const SizedBox(height: 40),

              _LanguageTile(
                title: "English",
                isSelected: currentLang == 'en',
                onTap: () => context.read<LocaleProvider>().changeLocale('en'),
              ),
              const SizedBox(height: 12),

              _LanguageTile(
                title: "(Dari) دری",
                isSelected: currentLang == 'fa',
                onTap: () => context.read<LocaleProvider>().changeLocale('fa'),
              ),
              const SizedBox(height: 12),

              _LanguageTile(
                title: "(Pashto) پښتو",
                isSelected: currentLang == 'ps',
                onTap: () => context.read<LocaleProvider>().changeLocale('ps'),
              ),

              const SizedBox(height: 20),

              Text(
                loc.changeLater,
                textAlign: TextAlign.center,
                style: AppTextStyles.semiBold(locale).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              AppButton(
                text: loc.continueText,
                onPressed: () {
                  context.go('/intro');
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
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
            color: isSelected ? AppColors.primary : AppColors.secondary,
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
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary
                ),
              ),
            ),

            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey,
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
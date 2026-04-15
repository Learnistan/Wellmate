import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/textStyles.dart';

import '../../../core/localization/localeProvider.dart';
import '../../../l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.welcome,
              style: AppTextStyles.semiBold(locale)
            ),

            const SizedBox(height: 30),

            Text(
              loc.login,
              textAlign: TextAlign.end,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                context.read<LocaleProvider>().changeLocale('en');
              },
              child: const Text('English'),
            ),

            ElevatedButton(
              onPressed: () {
                context.read<LocaleProvider>().changeLocale('fa');
              },
              child: const Text('Dari'),
            ),

            ElevatedButton(
              onPressed: () {
                context.read<LocaleProvider>().changeLocale('ps');
              },
              child: const Text('Pashto'),
            ),

            ElevatedButton(
              onPressed: () => {
                context.go('/intro')
              },
              child: Text("Go to Intro")
            )
          ],
        ),
      ),
    );
  }
}
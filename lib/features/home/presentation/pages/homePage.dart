import 'package:flutter/material.dart';
import 'package:wellmate/core/theme/textStyles.dart';

import '../../../../l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home',
              textAlign: TextAlign.start,
              style: AppTextStyles.semiBold(locale)
            ),
          ],
        ),
      ),
    );
  }
}
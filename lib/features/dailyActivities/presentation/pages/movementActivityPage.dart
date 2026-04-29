import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/localeProvider.dart';
import '../../../../l10n/app_localizations.dart';

class MovementActivityPage extends StatelessWidget {
  const MovementActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Movement Activity",
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
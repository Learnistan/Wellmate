import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:wellmate/core/constants/journeysData.dart';
import 'package:wellmate/core/providers/journeyProvider.dart';
import '../../../../core/localization/localeProvider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/provider/authProvider.dart';
import '../../../shell/presentation/navigationProvider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => context.read<LocaleProvider>().changeLocale('en'),
                child: Text("English")
            ),
            ElevatedButton(
                onPressed: () => context.read<LocaleProvider>().changeLocale('fa'),
                child: Text("Dari")
            ),
            ElevatedButton(
                onPressed: () => context.read<LocaleProvider>().changeLocale('ps'),
                child: Text("Pashto")
            ),
            ElevatedButton(
                onPressed: () {
                  context.read<JourneyProvider>().changeJourney(Journeys.carpet);
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
                child: Text("Carpet Journey")
            ),
            ElevatedButton(
                onPressed: () {
                  context.read<JourneyProvider>().changeJourney(Journeys.minarets);
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
                child: Text("Minarets Journey")
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
          ],
        ),
      ),
    );
  }
}
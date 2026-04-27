import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/localeProvider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/provider/authProvider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
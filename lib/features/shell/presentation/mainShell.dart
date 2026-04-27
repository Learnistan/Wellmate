import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wellmate/core/widgets/curvedNavBar.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/dailyActivities.dart';
import 'package:wellmate/features/journal/presentation/pages/journalPage.dart';
import 'package:wellmate/features/mindfulGames/presentation/pages/mindfulGamesPage.dart';
import 'package:wellmate/features/profile/presentation/pages/profilePage.dart';

import '../../home/presentation/pages/homePage.dart';
import 'navigationProvider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);

    final pages = const [
      HomePage(),
      MindfulGamesPage(),
      DailyActivitiesPage(),
      JournalPage(),
      ProfilePage(),
    ];

    return SafeArea(
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: CurvedNavBar(
          currentIndex: index,
          onTap: (i) {
            ref.read(navigationIndexProvider.notifier).state = i;
          },
        ),
      )
    );
  }
}
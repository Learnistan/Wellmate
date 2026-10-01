import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ReadContext;
import 'package:wellmate/core/providers/syncProvider.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/widgets/curvedNavBar.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/dailyActivities.dart';
import 'package:wellmate/features/mindfulGames/presentation/pages/mindfulGamesPage.dart';
import 'package:wellmate/features/profile/presentation/pages/profilePage.dart';

import '../../home/presentation/pages/homePage.dart';
import 'navigationProvider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SyncProvider>().sync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navigationIndexProvider);

    final pages = const [
      HomePage(),
      MindfulGamesPage(),
      DailyActivitiesPage(),
      ProfilePage(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: index,
            children: pages,
          ),
        ),
        bottomNavigationBar: CurvedNavBar(
          currentIndex: index,
          onTap: (i) {
            ref.read(navigationIndexProvider.notifier).state = i;
          },
        ),
      ),
    );
  }
}
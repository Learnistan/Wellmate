import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/features/shell/presentation/mainShell.dart';
import '../../features/auth/presentation/pages/loginPage.dart';
import '../../features/home/presentation/pages/homePage.dart';
import '../../features/onboarding/presentation/pages/introPage.dart';
import '../appController.dart';

class AppRouter {
  final AppController appController;

  AppRouter(this.appController);

  late final router = GoRouter(
    refreshListenable: appController,
    initialLocation: '/',
    redirect: (context, state) {
      final isFirstLaunch = appController.isFirstLaunch;
      final isLoggedIn = appController.isLoggedIn;

      if (isFirstLaunch == null || isLoggedIn == null) {
        return '/'; // stay here (blank page)
      }

      // First Launch → Intro
      if (isFirstLaunch) {
        return '/intro';
      }

      // Not logged in → Auth
      if (!isLoggedIn) {
        return '/login';
      }

      // Logged in → Shell
      return '/shell';
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => IntroPage(appController: appController),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(appController: appController,),
      ),
      GoRoute(
        path: '/shell',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/features/auth/presentation/pages/registerPage.dart';
import 'package:wellmate/features/auth/presentation/provider/authProvider.dart';
import 'package:wellmate/features/language/presentation/languagePage.dart';
import 'package:wellmate/features/shell/presentation/mainShell.dart';
import '../../features/auth/presentation/pages/loginPage.dart';
import '../../features/home/presentation/pages/homePage.dart';
import '../../features/onboarding/presentation/pages/introPage.dart';
import '../appController.dart';

class AppRouter {
  final AppController appController;
  final AuthProvider authProvider;

  AppRouter(this.appController, this.authProvider);

  late final router = GoRouter(
    refreshListenable: Listenable.merge([appController, authProvider]),
    initialLocation: '/loading',
      redirect: (context, state) {
        final location = state.uri.path;

        final isFirstLaunch = appController.isFirstLaunch;
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthLoading = authProvider.isLoading;

        final isGoingToLogin = location == '/login';
        final isGoingToLanguage = location == '/language';
        final isGoingToIntro = location == '/intro';
        final isGoingToShell = location == '/shell';
        final isGoingToLoading = location == '/loading';
        final isGoingToRegister = location == '/register';

        // 1. Loading state
        if (isFirstLaunch == null || isAuthLoading) {
          return isGoingToLoading ? null : '/loading';
        }

        // 2. First launch flow
        if (isFirstLaunch == true) {
          if (isGoingToLanguage || isGoingToIntro) return null;
          return '/language';
        }

        // 3. Not logged in
        if (!isLoggedIn) {
          if (isGoingToLogin || isGoingToRegister) return null;
          return '/login';
        }

        // 4. Logged in
        if (isLoggedIn) {
          if (isGoingToShell) return null;
          return '/shell';
        }

        return null;
      },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => LanguagePage(),
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
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterPage(),
      ),
    ],
  );
}
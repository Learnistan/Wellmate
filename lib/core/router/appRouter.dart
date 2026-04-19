import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/features/language/presentation/languagePage.dart';
import 'package:wellmate/features/onboarding/presentation/pages/multipleChoiceQuestionsPage.dart';
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
      final goingToIntro = state.matchedLocation == '/intro';
      final goingToLanguage = state.matchedLocation == '/language';
      final goingToQuestions = state.matchedLocation == '/questions';

      if (isFirstLaunch == null || isLoggedIn == null) {
        return '/'; // stay here (blank page)
      }


      // First launch flow
      if (isFirstLaunch) {
        // allow onboarding pages
        if (goingToLanguage || goingToIntro || goingToQuestions) {
          return null;
        }
        return '/language';
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
        path: '/language',
        builder: (context, state) => LanguagePage(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => IntroPage(),
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
        path: '/questions',
        builder: (context, state) => MultipleChoiceQuestionsPage(appController: appController),
      ),
    ],
  );
}
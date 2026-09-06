import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/features/auth/presentation/pages/passwordResetPage.dart';
import 'package:wellmate/features/auth/presentation/pages/registerPage.dart';
import 'package:wellmate/features/auth/presentation/pages/verifyEmailPage.dart';
import 'package:wellmate/features/auth/presentation/provider/authProvider.dart';
import 'package:wellmate/features/chatbot/presentation/pages/chatPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/bodyScanActivityPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/breathingActivityPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/eveningCloseActivityPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/moodCalibration.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/hydrationActivityPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/morningIntentionsActivityPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/movementActivityPage.dart';
import 'package:wellmate/features/dailyActivities/presentation/pages/stretchActivityPage.dart';
import 'package:wellmate/features/language/presentation/languagePage.dart';
import 'package:wellmate/features/mindfulGames/presentation/pages/BubblesGamePage.dart';
import 'package:wellmate/features/mindfulGames/presentation/pages/emotionsGamePage.dart';
import 'package:wellmate/features/mindfulGames/presentation/pages/visualizingGamePage.dart';
import 'package:wellmate/features/onboarding/presentation/pages/multipleChoiceQuestionsPage.dart';
import 'package:wellmate/features/onboarding/presentation/pages/selectJourneyPage.dart';
import 'package:wellmate/features/shell/presentation/mainShell.dart';
import '../../features/auth/presentation/pages/loginPage.dart';
import '../../features/home/presentation/pages/homePage.dart';
import '../../features/onboarding/presentation/pages/introPage.dart';
import '../appController.dart';
import '../providers/journeyProvider.dart';

class AppRouter {
  final AppController appController;
  final AuthProvider authProvider;
  final JourneyProvider journeyProvider;

  AppRouter(this.appController, this.authProvider, this.journeyProvider);

  late final router = GoRouter(
    refreshListenable: Listenable.merge([appController, authProvider, journeyProvider]),
    initialLocation: '/loading',
      redirect: (context, state) {
        final location = state.uri.path;

        final isFirstLaunch = appController.isFirstLaunch;
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthLoading = authProvider.isLoading;
        final isVerificationPending =
            authProvider.isVerificationPending;

        final isGoingToLogin = location == '/login';
        final isGoingToLanguage = location == '/language';
        final isGoingToIntro = location == '/intro';
        final isGoingToLoading = location == '/loading';
        final isGoingToRegister = location == '/register';
        final isGoingToResetPassword = location == '/forgot-password';
        final isGoingToVerification = location == '/verify-email';
        final isGoingToQuestions = location == '/questions';
        final isGoingToJourneys = location == '/journeys';

        // 1. Loading state
        if (isFirstLaunch == null || isAuthLoading) {
          return isGoingToLoading ? null : '/loading';
        }

        // 2. First launch flow
        if (isFirstLaunch == true) {
          if (isGoingToLanguage || isGoingToIntro || isGoingToQuestions || isGoingToJourneys) return null;
          return '/language';
        }

        // 3. Firebase user exists, but email is not verified
        if (isVerificationPending) {
          return isGoingToVerification
              ? null
              : '/verify-email';
        }

        // 4. Not logged in
        if (!isLoggedIn) {
          if (isGoingToLogin || isGoingToRegister || isGoingToResetPassword) return null;
          return '/login';
        }

        // 5. Logged in
        if (isLoggedIn) {
          final selectedJourney = journeyProvider.selectedJourney;

          if (selectedJourney == null) {
            return isGoingToJourneys ? null : '/journeys';
          }

          final allowedRoutes = [
            '/shell',
            '/home',
            '/journeys',
            '/breathing',
            '/movement',
            '/hydration',
            '/body-scan',
            '/mood-calibration',
            '/chat',
            '/visualizing',
            '/bubbles',
            '/emotions',
            '/morning-intentions',
            '/evening-close',
            '/stretch',
            '/forgot-password'
          ];

          if (allowedRoutes.contains(location)) {
            return null;
          }

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
        path: '/register',
        builder: (context, state) => RegisterPage()
      ),
      GoRoute(
          path: '/verify-email',
          builder: (context, state) => VerifyEmailPage()
      ),
      GoRoute(
        path: '/questions',
        builder: (context, state) => MultipleChoiceQuestionsPage(appController: appController),
      ),
      GoRoute(
        path: '/journeys',
        builder: (context, state) => SelectJourneyPage()
      ),
      GoRoute(
        path: '/breathing',
        builder: (context, state) => BreathingActivityPage(),
      ),
      GoRoute(
        path: '/movement',
        builder: (context, state) => MovementActivityPage(),
      ),
      GoRoute(
        path: '/hydration',
        builder: (context, state) {
          final int cups = (state.extra as int?) ?? 0;

          return HydrationActivityPage(cups: cups);
        },
      ),
      GoRoute(
        path: '/body-scan',
        builder: (context, state) => BodyScanActivityPage(),
      ),
      GoRoute(
        path: '/mood-calibration',
        builder: (context, state) => MoodCalibration(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => ChatPage(),
      ),
      GoRoute(
        path: '/visualizing',
        builder: (context, state) => VisualizingGamePage(),
      ),
      GoRoute(
        path: '/bubbles',
        builder: (context, state) => BubblesGamePage(),
      ),
      GoRoute(
        path: '/emotions',
        builder: (context, state) => EmotionsGamePage(),
      ),
      GoRoute(
        path: '/morning-intentions',
        builder: (context, state) => MorningIntentionsActivityPage(),
      ),
      GoRoute(
        path: '/evening-close',
        builder: (context, state) => EveningCloseActivityPage(),
      ),
      GoRoute(
        path: '/stretch',
        builder: (context, state) => StretchActivityPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordPage(),
      ),
    ],
  );
}
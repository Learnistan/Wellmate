import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/loginPage.dart';
import '../../features/home/presentation/pages/homePage.dart';
import '../../features/onboarding/presentation/pages/introPage.dart';
import '../../features/splash/presentation/pages/splashPage.dart';
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

      // Splash logic
      if (state.fullPath == '/') return null;

      // First Launch → Intro
      if (isFirstLaunch) {
        return '/intro';
      }

      // Not logged in → Auth
      if (!isLoggedIn) {
        return '/login';
      }

      // Logged in → Home
      return '/home';
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
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
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
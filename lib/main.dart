import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/providers/journeyProvider.dart';
import 'package:wellmate/core/theme/appTheme.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/activateAllActivitiesUseCase.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/addActivity.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/addActivityLog.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/getActivity.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/getTodayHydrationGlasses.dart';
import 'package:wellmate/features/dailyActivities/domain/useCases/updateActivity.dart';
import 'package:wellmate/features/dailyActivities/presentation/providers/activityProvider.dart';
import 'package:wellmate/features/home/data/dataSources/homeLocalDataSource.dart';
import 'package:wellmate/features/home/data/repositories/homeRepositoryImpl.dart';
import 'package:wellmate/features/home/domain/useCases/getLastCompletedDifferenceUseCase.dart';
import 'package:wellmate/features/home/domain/useCases/getProgressUseCase.dart';
import 'package:wellmate/features/home/domain/useCases/initProgressUseCase.dart';
import 'package:wellmate/features/home/domain/useCases/updateProgressUseCase.dart';
import 'core/appController.dart';
import 'core/database/databaseHelper.dart';
import 'core/localization/localeProvider.dart';
import 'core/router/appRouter.dart';
import 'core/services/notificationService.dart';
import 'core/storage/data/dataSources/local_storage_dataSource.dart';
import 'core/storage/data/repository/appStorageRepositoryImpl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/data/dataSources/authRemoteDataSource.dart';
import 'features/auth/data/repositories/authRepositoryImpl.dart';
import 'features/auth/domain/useCases/signIn.dart';
import 'features/auth/domain/useCases/signOut.dart';
import 'features/auth/domain/useCases/signUp.dart';
import 'features/auth/presentation/provider/authProvider.dart';
import 'features/dailyActivities/data/dataSources/activityLocalDataSource.dart';
import 'features/dailyActivities/data/repositories/activityRepositoryImpl.dart';
import 'features/home/presentation/providers/homeProvider.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.initNotification();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language_code') ?? 'en';

  final firebaseAuth = FirebaseAuth.instance;
  final remoteDataSource = AuthRemoteDataSource(firebaseAuth);
  final authRepository = AuthRepositoryImpl(remoteDataSource);

  final localDataSource = LocalStorageDataSource();
  final repository = AppStorageRepositoryImpl(localDataSource);
  final appController = AppController(repository);
  final dbHelper = DatabaseHelper.instance;
  final localDataSource2 = ActivityLocalDataSource(dbHelper);
  final localDataSource3 = HomeLocalDataSource(dbHelper);

  final repository2 = ActivityRepositoryImpl(localDataSource2);
  final repository3 = HomeRepositoryImpl(localDataSource3);

  runApp(
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => LocaleProvider(Locale(savedLanguage)),
        child: MyApp(appController, authRepository, repository2, repository3, notificationService),
      )
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppController appController;
  final AuthRepositoryImpl repository;
  final ActivityRepositoryImpl repository2;
  final HomeRepositoryImpl repository3;
  final NotificationService notificationService;

  const MyApp(this.appController, this.repository, this.repository2, this.repository3, this.notificationService, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppRouter? appRouter;

  @override
  void initState() {
    super.initState();
    widget.appController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeProvider(
            InitProgressUseCase(widget.repository3),
            UpdateProgressUseCase(widget.repository3),
            GetProgressUseCase(widget.repository3),
            GetLastCompletedDifferenceUseCase(widget.repository3),
            ActivateAllActivitiesUseCase(widget.repository2),
            widget.notificationService
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInUseCase: SignIn(widget.repository),
            signUpUseCase: SignUp(widget.repository),
            signOutUseCase: SignOut(widget.repository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(
            addActivity: AddActivity(widget.repository2),
            getActivities: GetActivities(widget.repository2),
            updateActivity: UpdateActivity(widget.repository2),
            addActivityLog: AddActivityLog(widget.repository2),
            getTodayHydrationGlasses: GetTodayHydrationGlasses(widget.repository2),
          )
        ),
        ChangeNotifierProvider(
          create: (_) => JourneyProvider()..loadJourney(),
        )
      ],
      child: Builder(
        builder: (context) {
          // ✅ SAFE: provider exists here
          final authProvider = Provider.of<AuthProvider>(context, listen: false);

          // ✅ initialize ONLY ONCE
          appRouter ??= AppRouter(widget.appController, authProvider);

          final localeProvider = context.watch<LocaleProvider>();

          return Consumer<LocaleProvider>(
            builder: (context, provider, _) {
              return MaterialApp.router(
                routerConfig: appRouter!.router,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.buildTheme(provider.locale),
                locale: localeProvider.locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('fa'),
                  Locale('ps'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wellmate/features/auth/domain/useCases/deleteAccount.dart';
import 'package:wellmate/features/auth/domain/useCases/sendPasswordResetEmail.dart';
import 'package:wellmate/features/auth/domain/useCases/signInWithGoogle.dart';
import 'package:wellmate/features/profile/data/dataSources/profileRemoteDataSource.dart';
import 'package:wellmate/features/profile/domain/useCases/saveProfile.dart';
import 'package:wellmate/features/profile/domain/useCases/updateSelectedJourney.dart'; // NEW (adjust path/file name to where you created it)
import 'features/profile/domain/useCases/clearLocalProfile.dart';
import 'features/profile/domain/useCases/deleteProfile.dart';
import 'features/profile/domain/useCases/getProfile.dart';
import 'features/profile/domain/useCases/reauthenticateUser.dart';
import 'features/profile/domain/useCases/restoreProfile.dart';
import 'core/sync/syncData.dart';
import 'core/providers/syncProvider.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellmate/core/providers/journeyProvider.dart';
import 'package:wellmate/core/theme/appTheme.dart';
import 'package:wellmate/features/auth/domain/useCases/checkEmailVerification.dart';
import 'package:wellmate/features/auth/domain/useCases/renderVerificationEmail.dart';
import 'package:wellmate/features/chatbot/data/dataSources/openAIRemoteDataSource.dart';
import 'package:wellmate/features/chatbot/data/repositories/chatRepositoyImpl.dart';
import 'package:wellmate/features/chatbot/domain/useCases/sendMessage.dart';
import 'package:wellmate/features/chatbot/presentation/providers/chatProvider.dart';
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
import 'package:wellmate/features/home/domain/useCases/resetJourney.dart';
import 'package:wellmate/features/home/domain/useCases/updateProgressUseCase.dart';
import 'package:wellmate/features/profile/data/repositories/profileRepositoryImpl.dart';
import 'package:wellmate/features/profile/domain/useCases/getActiveJourneysUseCase.dart';
import 'package:wellmate/features/profile/presentation/providers/profileProvider.dart';
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
import 'features/profile/data/dataSources/profileDataSource.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize();

  final notificationService = NotificationService();
  await notificationService.initNotification();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language_code') ?? 'en';

  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final remoteDataSource = AuthRemoteDataSource(firebaseAuth);
  final authRepository = AuthRepositoryImpl(remoteDataSource);

  final client = http.Client();

  final localDataSource = LocalStorageDataSource();
  final repository = AppStorageRepositoryImpl(localDataSource);
  final appController = AppController(repository);
  final dbHelper = DatabaseHelper.instance;
  final localDataSource2 = ActivityLocalDataSource(dbHelper);
  final localDataSource3 = HomeLocalDataSource(dbHelper);
  final localDataSource4 = ProfileDataSource(dbHelper);
  final remoteDataSource2 = ProfileRemoteDataSource(firestore);

  final repository2 = ActivityRepositoryImpl(localDataSource2);
  final repository3 = HomeRepositoryImpl(localDataSource3);
  final repository4 = ProfileRepositoryImpl(localDataSource4, remoteDataSource2);

  runApp(
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => LocaleProvider(Locale(savedLanguage)),
        child: MyApp(appController, authRepository, repository2, repository3, client, notificationService, repository4, firebaseAuth),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppController appController;
  final AuthRepositoryImpl repository;
  final ActivityRepositoryImpl repository2;
  final HomeRepositoryImpl repository3;
  final NotificationService notificationService;
  final ProfileRepositoryImpl repository4;
  final http.Client client;
  final FirebaseAuth firebaseAuth;

  const MyApp(this.appController, this.repository, this.repository2, this.repository3, this.client, this.notificationService, this.repository4, this.firebaseAuth, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppRouter? appRouter;
  late final JourneyProvider journeyProvider = JourneyProvider()..loadJourney();

  @override
  void initState() {
    super.initState();
    widget.appController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UpdateSelectedJourney>(
          create: (_) => UpdateSelectedJourney(widget.repository4),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInUseCase: SignIn(widget.repository),
            signUpUseCase: SignUp(widget.repository),
            signOutUseCase: SignOut(widget.repository),
            checkEmailVerificationUseCase: CheckEmailVerification(widget.repository),
            resendVerificationEmailUseCase: ResendVerificationEmail(widget.repository),
            firebaseAuth: widget.firebaseAuth,
            signInWithGoogleUseCase: SignInWithGoogle(widget.repository),
            sendPasswordResetEmailUseCase: SendPasswordResetEmail(widget.repository),
            deleteAccountUseCase: DeleteAccount(widget.repository),
            saveProfileUseCase: SaveProfile(widget.repository4),
            restoreProfileUseCase: RestoreProfile(widget.repository4),
            journeyProvider: journeyProvider,
            clearLocalProfileUseCase: ClearLocalProfile(widget.repository4),
            deleteProfileUseCase: DeleteProfile(widget.repository4),
            reauthenticateUserUseCase: ReauthenticateUser(widget.repository),
          ),
        ),
        ChangeNotifierProvider.value(value: journeyProvider),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(
            InitProgressUseCase(widget.repository3),
            UpdateProgressUseCase(widget.repository3),
            GetProgressUseCase(widget.repository3),
            GetLastCompletedDifferenceUseCase(widget.repository3),
            ActivateAllActivitiesUseCase(widget.repository2),
            widget.notificationService,
            ResetJourneyUseCase(widget.repository3),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(
            addActivity: AddActivity(widget.repository2),
            getActivities: GetActivities(widget.repository2),
            updateActivity: UpdateActivity(widget.repository2),
            addActivityLog: AddActivityLog(widget.repository2),
            getTodayHydrationGlasses: GetTodayHydrationGlasses(widget.repository2),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            GetActiveJourneysUseCase(widget.repository4),
            GetProfile(widget.repository4),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            SendMessage(
              ChatRepositoryImpl(
                OpenAIRemoteDataSource(FirebaseFunctions.instance),
              ),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(
            SyncData([widget.repository4]),
            widget.firebaseAuth,
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);

          appRouter ??= AppRouter(widget.appController, authProvider, journeyProvider);

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
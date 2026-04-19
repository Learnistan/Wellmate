import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:wellmate/core/theme/appTheme.dart';
import 'core/appController.dart';
import 'core/localization/localeProvider.dart';
import 'core/router/appRouter.dart';
import 'core/storage/data/dataSources/local_storage_dataSource.dart';
import 'core/storage/data/repository/appStorageRepositoryImpl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/data/dataSources/authRemoteDataSource.dart';
import 'features/auth/data/repositories/authRepositoryImpl.dart';
import 'features/auth/domain/useCases/signIn.dart';
import 'features/auth/domain/useCases/signOut.dart';
import 'features/auth/domain/useCases/signUp.dart';
import 'features/auth/presentation/provider/authProvider.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firebaseAuth = FirebaseAuth.instance;
  final remoteDataSource = AuthRemoteDataSource(firebaseAuth);
  final authRepository = AuthRepositoryImpl(remoteDataSource);

  final localDataSource = LocalStorageDataSource();
  final repository = AppStorageRepositoryImpl(localDataSource);
  final appController = AppController(repository);

  runApp(
      ProviderScope(
          child: MyApp(appController, authRepository)
      )
  );
}

class MyApp extends StatefulWidget {
  final AppController appController;
  final AuthRepositoryImpl repository;

  const MyApp(this.appController, this.repository, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late final appRouter = AppRouter(widget.appController);

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
          create: (_) => LocaleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInUseCase: SignIn(widget.repository),
            signUpUseCase: SignUp(widget.repository),
            signOutUseCase: SignOut(widget.repository),
          ),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) {
          return MaterialApp.router(
            routerConfig: appRouter.router,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildTheme(provider.locale),
            locale: provider.locale,

            supportedLocales: const [
              Locale('en'),
              Locale('fa'), // Dari
              Locale('ps'), // Pashto
            ],

            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
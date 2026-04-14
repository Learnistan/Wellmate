import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'core/appController.dart';
import 'core/localization/localeProvider.dart';
import 'core/router/appRouter.dart';
import 'core/storage/data/dataSources/local_storage_dataSource.dart';
import 'core/storage/data/repository/appStorageRepositoryImpl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  final localDataSource = LocalStorageDataSource();
  final repository = AppStorageRepositoryImpl(localDataSource);
  final appController = AppController(repository);

  runApp(
    ProviderScope(
        child: MyApp(appController)
    )
  );
}

class MyApp extends StatefulWidget {
  final AppController appController;

  const MyApp(this.appController, {super.key});

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
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) {
          return MaterialApp.router(
            routerConfig: appRouter.router,
            debugShowCheckedModeBanner: false,

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
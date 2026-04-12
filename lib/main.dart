import 'package:flutter/material.dart';
import 'core/appController.dart';
import 'core/router/appRouter.dart';
import 'core/storage/data/dataSources/local_storage_dataSource.dart';
import 'core/storage/data/repository/appStorageRepositoryImpl.dart';

void main() {
  final localDataSource = LocalStorageDataSource();
  final repository = AppStorageRepositoryImpl(localDataSource);
  final appController = AppController(repository);

  runApp(MyApp(appController));
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
    return MaterialApp.router(
      routerConfig: appRouter.router,
    );
  }
}
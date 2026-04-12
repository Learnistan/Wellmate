import 'package:flutter/material.dart';

import '../../../../core/appController.dart';

class IntroPage extends StatelessWidget {
  final AppController appController;

  const IntroPage({required this.appController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Intro"),
              ElevatedButton(
                  onPressed: () => {appController.completeOnboarding()},
                  child: const Text("Let's Go")
              )
            ],
          )
      ),
    );
  }
}
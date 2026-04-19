import 'package:flutter/material.dart';
import '../../../../core/appController.dart';

class MultipleChoiceQuestionsPage extends StatelessWidget {
  final AppController appController;

  const MultipleChoiceQuestionsPage({super.key, required this.appController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("MultipleChoice Questions"),
              ElevatedButton(
                  onPressed: () => {
                    appController.completeOnboarding()
                  },
                  child: const Text("Let's Go")
              )
            ],
          )
      ),
    );
  }
}
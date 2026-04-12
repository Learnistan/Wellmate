import 'package:flutter/material.dart';
import 'package:wellmate/core/appController.dart';

class LoginPage extends StatelessWidget {
  final AppController appController;

  const LoginPage({required this.appController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Login"),
              ElevatedButton(
                  onPressed: () => {appController.login()},
                  child: const Text("Let's Go")
              )
            ],
          )
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/appController.dart';

import '../provider/authProvider.dart';

class LoginPage extends StatelessWidget {
  final AppController appController;

  LoginPage({required this.appController});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: emailController),
              TextField(controller: passwordController),

              const SizedBox(height: 20),

              if (authProvider.isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    authProvider.login(
                      emailController.text,
                      passwordController.text,
                    );
                  },
                  child: Text("Login"),
                ),

              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: const Text("Create account"),
              )

            ],
          )
      ),
    );
  }
}
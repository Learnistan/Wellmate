import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/appController.dart';

import '../provider/authProvider.dart';
import '../../../../core/widgets/ButtonCom.dart';
import '../../../../core/widgets/AppInputField.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  final AppController appController;

  LoginPage({super.key, required this.appController});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Text(
                loc.welcomeBack,
                textAlign: TextAlign.center,
                style: AppTextStyles.semiBold(locale).copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                loc.loginSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.semiBold(locale).copyWith(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              AppInputField(
                controller: emailController,
                label: loc.email,
              ),

              const SizedBox(height: 12),

              AppInputField(
                controller: passwordController,
                label: loc.password,
                obscureText: true,
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    // TODO: forgot password
                  },
                  child: Text(
                    loc.forgotPassword,
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              authProvider.isLoading
                  ? const CircularProgressIndicator()
                  : AppButton(
                text: loc.login,
                onPressed: () {
                  authProvider.login(
                    emailController.text,
                    passwordController.text,
                  );
                },
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.18,
                    height: 2,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  const Text("Or", style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.18,
                    height: 2,
                    color: AppColors.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon("assets/images/google.png"),
                  const SizedBox(width: 10),
                  _socialIcon("assets/images/facebook.png"),
                  const SizedBox(width: 10),
                  _socialIcon("assets/images/apple-logo.png"),
                ],
              ),

              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.dontHaveAccount,
                    style: AppTextStyles.semiBold(locale).copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/register');
                    },
                    child: Text(
                      loc.signUp,
                      style: AppTextStyles.semiBold(locale).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(String path) {
    return SizedBox(
      width: 50.09,
      height: 40.91,
      child: Center(
        child: Image.asset(
          path,
          width: 40.09,
          height: 40.91,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
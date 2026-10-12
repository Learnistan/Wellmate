import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:wellmate/core/appController.dart';
import 'package:wellmate/core/constants/assets.dart';
import 'package:wellmate/core/utils/authFailureLocalization.dart';

import '../provider/authProvider.dart';
import '../../../../core/widgets/ButtonCom.dart';
import '../../../../core/widgets/AppInputField.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  final AppController appController;

  const LoginPage({
    super.key,
    required this.appController,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    await authProvider.login(
      emailController.text.trim(),
      passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: keyboardHeight + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: SizedBox(),
                          ),

                          Text(
                            loc.welcomeBack,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.semiBold(locale)
                                .copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            loc.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.semiBold(locale)
                                .copyWith(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 40),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                AppInputField(
                                  controller: emailController,
                                  label: loc.email,
                                  validator: (value) {
                                    final email =
                                        value?.trim() ?? '';

                                    if (email.isEmpty) {
                                      return loc.emailRequired;
                                    }

                                    final emailRegex = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    );

                                    if (!emailRegex.hasMatch(email)) {
                                      return loc.invalidEmail;
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                AppInputField(
                                  controller: passwordController,
                                  label: loc.password,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty) {
                                      return loc.passwordRequired;
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                context.push('/forgot-password');
                              },
                              child: Text(
                                loc.forgotPassword,
                                style: AppTextStyles.semiBold(locale)
                                    .copyWith(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          if (authProvider.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              authProvider.error!.localized(loc),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          authProvider.isLoading
                              ? const CircularProgressIndicator()
                              : AppButton(
                            text: loc.login,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  loc.or,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Google Sign In
                              SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () async {
                                    await authProvider.signInWithGoogleUseCase();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF202124),
                                    side: const BorderSide(
                                      color: Color(0xFFDADCE0),
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        AppAssets.GoogleIcon,
                                        width: 22,
                                        height: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Apple Sign In
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: SignInWithAppleButton(
                                  style: SignInWithAppleButtonStyle.black,
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: authProvider.isLoading
                                      ? () {}
                                      : () async {
                                    await authProvider.signInWithApple();
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        loc.dontHaveAccount,
                                        style: AppTextStyles
                                            .semiBold(locale)
                                            .copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.go('/register');
                                      },
                                      child: Text(
                                        loc.signUp,
                                        style: AppTextStyles
                                            .semiBold(locale)
                                            .copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
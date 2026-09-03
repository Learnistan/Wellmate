import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/appController.dart';
import 'package:wellmate/core/constants/assets.dart';
import 'package:wellmate/core/utils/authFailureLocalization.dart';
import 'package:wellmate/core/widgets/SocialIcon.dart';

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

    final success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // context.go('/home');
    }
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
                        mainAxisAlignment:
                        MainAxisAlignment.center,
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

                                    if (!emailRegex
                                        .hasMatch(email)) {
                                      return loc.invalidEmail;
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                AppInputField(
                                  controller:
                                  passwordController,
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
                                style:
                                AppTextStyles.semiBold(locale)
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

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context)
                                    .size
                                    .width *
                                    0.18,
                                height: 2,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.or,
                                style:
                                TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: MediaQuery.of(context)
                                    .size
                                    .width *
                                    0.18,
                                height: 2,
                                color: AppColors.secondary,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              SocialIcon(
                                path: AppAssets.GoogleIcon,
                                onTap: () {
                                  authProvider.signInWithGoogleUseCase();
                                },
                              ),
                              const SizedBox(width: 10),
                              SocialIcon(
                                path: AppAssets.FacebookIcon,
                              ),
                              const SizedBox(width: 10),
                              SocialIcon(
                                path: AppAssets.AppleIcon,
                              ),
                            ],
                          ),

                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      loc.dontHaveAccount,
                                      style: AppTextStyles
                                          .semiBold(locale)
                                          .copyWith(
                                        color: Colors.grey,
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
                                          color:
                                          AppColors.primary,
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
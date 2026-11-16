import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/AppInputField.dart';
import '../../../../core/widgets/ButtonCom.dart';
import '../provider/authProvider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
  });

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loc = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resetPassword(
      emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.passwordResetMessage1,
          ),
        ),
      );

      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.passwordResetMessage2,
        ),
      ),
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
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: SizedBox(),
                          ),

                          Text(
                            loc.forgotPassword,
                            textAlign: TextAlign.center,
                            style:
                            AppTextStyles.semiBold(locale)
                                .copyWith(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            loc.enterEmailToSendResetLink,
                            textAlign: TextAlign.center,
                            style:
                            AppTextStyles.semiBold(locale)
                                .copyWith(
                              fontSize: 18,
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
                                      return loc.enterYourEmail;
                                    }

                                    final emailRegex = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    );

                                    if (!emailRegex.hasMatch(email)) {
                                      return loc.enterValidEmail;
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          authProvider.isLoading
                              ? const CircularProgressIndicator()
                              : AppButton(
                            text: loc.sendResetLink,
                            onPressed: _sendResetEmail,
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () {
                              context.pop();
                            },
                            child: Text(
                              loc.login,
                              style:
                              AppTextStyles.semiBold(locale)
                                  .copyWith(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          const Expanded(
                            flex: 1,
                            child: SizedBox(),
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
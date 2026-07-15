import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../provider/authProvider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/ButtonCom.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() =>
      _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  int _resendSeconds = 60;

  bool get _canResend => _resendSeconds == 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _resendSeconds = 60;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds <= 1) {
          timer.cancel();

          setState(() {
            _resendSeconds = 0;
          });
        } else {
          setState(() {
            _resendSeconds--;
          });
        }
      },
    );
  }

  Future<void> _checkVerification() async {
    final authProvider = context.read<AuthProvider>();

    final success =
    await authProvider.checkVerification();

    if (!mounted) return;

    if (success) {
      context.go('/home');
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();

    final success =
    await authProvider.resendVerificationEmail();

    if (!mounted) return;

    if (success) {
      _startResendTimer();
    }
  }

  Future<void> _returnToLogin() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    context.go('/login');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final email =
                  auth.pendingEmail ?? 'your email address';

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints:
                    const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          loc.verifyYourEmail,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '${loc.weSentLink}\n$email',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          loc.clickOnVerifyLink,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        if (auth.error != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red
                                  .withValues(alpha: 0.08),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Text(
                              auth.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],

                        if (auth.message != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green
                                  .withValues(alpha: 0.08),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Text(
                              auth.message!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        auth.isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text:
                            loc.verified,
                            onPressed:
                            _checkVerification,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: auth.isLoading ||
                              !_canResend
                              ? null
                              : _resendEmail,
                          child: Text(
                            _canResend
                                ? loc.resendVerifyEmail
                                : loc.resendVerifyEmailSec(_resendSeconds),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : _returnToLogin,
                          child: Text(
                            loc.userAnotherEmail,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          loc.checkYourSpam,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
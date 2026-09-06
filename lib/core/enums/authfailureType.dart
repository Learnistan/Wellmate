enum AuthFailureType {
  invalidEmail,
  emailAlreadyInUse,
  weakPassword,
  invalidCredentials,
  userDisabled,
  tooManyRequests,
  networkError,
  operationNotAllowed,
  emailNotVerified,
  verificationSessionExpired,
  userNotFoundAfterLogin,
  accountCreationFailed,
  unknown,
}

enum AuthMessageType {
  verificationRequired,
  verificationEmailSent,
  verificationSuccessful,
  newVerificationEmailSent,
  passwordResetEmailSent,
}

class AuthException implements Exception {
  final AuthFailureType type;
  final String? debugMessage;

  const AuthException(
      this.type, {
        this.debugMessage,
      });

  @override
  String toString() {
    return 'AuthException(type: $type, debugMessage: $debugMessage)';
  }
}
import '../../../../l10n/app_localizations.dart';
import '../enums/authfailureType.dart';

extension AuthFailureLocalization on AuthFailureType {
  String localized(AppLocalizations loc) {
    switch (this) {
      case AuthFailureType.invalidEmail:
        return loc.authInvalidEmail;

      case AuthFailureType.emailAlreadyInUse:
        return loc.authEmailAlreadyInUse;

      case AuthFailureType.weakPassword:
        return loc.authWeakPassword;

      case AuthFailureType.invalidCredentials:
        return loc.authInvalidCredentials;

      case AuthFailureType.userDisabled:
        return loc.authUserDisabled;

      case AuthFailureType.tooManyRequests:
        return loc.authTooManyRequests;

      case AuthFailureType.networkError:
        return loc.authNetworkError;

      case AuthFailureType.operationNotAllowed:
        return loc.authOperationNotAllowed;

      case AuthFailureType.emailNotVerified:
        return loc.authEmailNotVerified;

      case AuthFailureType.verificationSessionExpired:
        return loc.authVerificationSessionExpired;

      case AuthFailureType.userNotFoundAfterLogin:
        return loc.authLoginFailed;

      case AuthFailureType.accountCreationFailed:
        return loc.authAccountCreationFailed;

      case AuthFailureType.unknown:
        return loc.authUnknownError;
    }
  }
}

extension AuthMessageLocalization on AuthMessageType {
  String localized(
      AppLocalizations loc, {
        String? email,
      }) {
    switch (this) {
      case AuthMessageType.verificationRequired:
        return loc.authVerificationRequired;

      case AuthMessageType.verificationEmailSent:
        return loc.authVerificationEmailSent(email ?? '');

      case AuthMessageType.verificationSuccessful:
        return loc.authVerificationSuccessful;

      case AuthMessageType.newVerificationEmailSent:
        return loc.authNewVerificationEmailSent;

      case AuthMessageType.passwordResetEmailSent:
        return loc.passwordResetEmailSent;
    }
  }
}
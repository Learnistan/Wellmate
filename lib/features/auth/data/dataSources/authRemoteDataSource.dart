import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/enums/authfailureType.dart';

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSource(this.firebaseAuth);

  Future<User> signIn(String email, String password) async {
    try {
      final credential =
      await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.reload();

      final user = firebaseAuth.currentUser;

      if (user == null) {
        throw const AuthException(
          AuthFailureType.userNotFoundAfterLogin,
        );
      }

      if (!user.emailVerified) {
        /*
         * Do not sign out here if your verification screen needs
         * FirebaseAuth.currentUser to resend and check verification.
         */
        throw const AuthException(
          AuthFailureType.emailNotVerified,
        );
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        _mapFirebaseAuthError(error.code),
        debugMessage: error.message,
      );
    }
  }

  Future<User> signUp(String email, String password) async {
    try {
      final credential =
      await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthException(
          AuthFailureType.accountCreationFailed,
        );
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        _mapFirebaseAuthError(error.code),
        debugMessage: error.message,
      );
    }
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = firebaseAuth.currentUser;

      if (user == null) {
        throw const AuthException(
          AuthFailureType.verificationSessionExpired,
        );
      }

      await user.reload();

      final refreshedUser = firebaseAuth.currentUser;

      if (refreshedUser == null) {
        throw const AuthException(
          AuthFailureType.verificationSessionExpired,
        );
      }

      if (refreshedUser.emailVerified) {
        return;
      }

      await refreshedUser.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        _mapFirebaseAuthError(error.code),
        debugMessage: error.message,
      );
    }
  }

  Future<User?> checkEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;

      if (user == null) {
        return null;
      }

      await user.reload();

      final refreshedUser = firebaseAuth.currentUser;

      if (refreshedUser == null ||
          !refreshedUser.emailVerified) {
        return null;
      }

      await refreshedUser.getIdToken(true);

      return refreshedUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        _mapFirebaseAuthError(error.code),
        debugMessage: error.message,
      );
    }
  }

  AuthFailureType _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthFailureType.invalidEmail;

      case 'email-already-in-use':
        return AuthFailureType.emailAlreadyInUse;

      case 'weak-password':
        return AuthFailureType.weakPassword;

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailureType.invalidCredentials;

      case 'user-disabled':
        return AuthFailureType.userDisabled;

      case 'too-many-requests':
        return AuthFailureType.tooManyRequests;

      case 'network-request-failed':
        return AuthFailureType.networkError;

      case 'operation-not-allowed':
        return AuthFailureType.operationNotAllowed;

      default:
        return AuthFailureType.unknown;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount googleUser =
    await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message: 'Google Sign-In did not return an ID token.',
      );
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return firebaseAuth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (error) {
      // Do not reveal whether an email is registered.
      //
      // With Firebase Email Enumeration Protection enabled,
      // Firebase normally won't throw user-not-found here.
      // This keeps the behavior safe if that protection is disabled.
      if (error.code == 'user-not-found') {
        return;
      }

      throw AuthException(
        _mapFirebaseAuthError(error.code),
        debugMessage: error.message,
      );
    }
  }

}
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSource(this.firebaseAuth);

  Future<User> signIn(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.reload();

      final user = firebaseAuth.currentUser;

      if (user == null) {
        throw Exception('Login failed. Please try again.');
      }

      if (!user.emailVerified) {
        // Sign out so an unverified account cannot access protected pages.
        await firebaseAuth.signOut();

        throw Exception(
          'Your email is not verified. Please check your inbox.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
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
        throw Exception('Account creation failed. Please try again.');
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      // Keep the user signed in temporarily so the verification page
      // can resend the verification email and reload the account.
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = firebaseAuth.currentUser;

      if (user == null) {
        throw Exception(
          'Your verification session has expired. Please sign in again.',
        );
      }

      await user.reload();

      final refreshedUser = firebaseAuth.currentUser;

      if (refreshedUser == null) {
        throw Exception(
          'Your verification session has expired. Please sign in again.',
        );
      }

      if (refreshedUser.emailVerified) {
        return;
      }

      await refreshedUser.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
  }

  Future<User?> checkEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;

      if (user == null) {
        return null;
      }

      // Firebase may still have the old verification value locally.
      await user.reload();

      final refreshedUser = firebaseAuth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        return null;
      }

      // Refresh the ID token so email_verified is also updated
      // for backend services and Firebase Security Rules.
      await refreshedUser.getIdToken(true);

      return refreshedUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'email-already-in-use':
        return 'This email address is already registered.';

      case 'weak-password':
        return 'Please choose a stronger password.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';

      default:
        return exception.message ??
            'Authentication failed. Please try again.';
    }
  }
}
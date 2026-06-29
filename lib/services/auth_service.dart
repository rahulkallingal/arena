import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Which login field an error should be shown against.
enum AuthField { email, password, general }

/// A login/signup error mapped to the field it belongs to.
class AuthError {
  final AuthField field;
  final String message;
  const AuthError(this.field, this.message);
}

/// Handles real accounts with **email + password**.
///
/// Sign up creates an account, stores a display name (shown next to messages),
/// and saves a `users/{uid}` profile doc. Log in signs an existing account back
/// in. The account is the user's own and works on any phone.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authState() => _auth.authStateChanges();

  String get displayName => _auth.currentUser?.displayName ?? 'Anonymous';

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  String? get email => _auth.currentUser?.email;

  /// Sends (or re-sends) the email-verification link to the current user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reloads the user so [isEmailVerified] reflects the latest server state.
  Future<void> reloadUser() => _auth.currentUser?.reload() ?? Future.value();

  /// Creates a new account, sets the display name, saves the profile, and
  /// sends an email-verification link.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'displayName': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Send the verification email (non-blocking for the user's first session).
    try {
      await user.sendEmailVerification();
    } catch (_) {/* ignore — they can resend from the banner */}
    // Make sure currentUser.displayName is populated for the first screen.
    await user.reload();
  }

  /// Logs an existing account in.
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Classifies a login/signup error to the field it belongs to, so the UI can
  /// highlight the email field for email problems and the password field for
  /// password problems (instead of always blaming the password).
  static AuthError classifyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
        case 'user-not-found':
          return const AuthError(
              AuthField.email, 'Incorrect email address.');
        case 'email-already-in-use':
          return const AuthError(AuthField.email,
              'An account with this email already exists. Try logging in.');
        case 'wrong-password':
          return const AuthError(AuthField.password, 'Incorrect password.');
        case 'invalid-credential':
          // With email-enumeration protection, Firebase returns this for both
          // a wrong email and a wrong password. The email format is already
          // validated client-side, so we point at the password.
          return const AuthError(AuthField.password, 'Incorrect password.');
        case 'weak-password':
          return const AuthError(AuthField.password,
              'Password is too weak — use at least 6 characters.');
        case 'network-request-failed':
          return const AuthError(AuthField.general,
              'No internet connection. Check your network.');
        case 'too-many-requests':
          return const AuthError(AuthField.general,
              'Too many attempts. Wait a moment and try again.');
      }
    }
    return const AuthError(
        AuthField.general, 'Something went wrong. Please try again.');
  }

  /// Turns Firebase's error codes into friendly messages.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address doesn\'t look right.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Try logging in.';
        case 'weak-password':
          return 'Password is too weak — use at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'network-request-failed':
          return 'No internet connection. Check your network.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a moment and try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

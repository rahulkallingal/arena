import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Creates a new account, sets the display name, and saves the profile.
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

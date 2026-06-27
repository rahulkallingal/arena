import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles signing the user in and remembering their chosen display name.
///
/// v1 uses Firebase **anonymous** sign-in: the user just picks a name and
/// starts debating — no email or password needed, so testing is instant. Each
/// install still gets a stable user id, so blocking/reporting can target a user
/// later. Real Google / phone sign-in can be added on top of this (see SETUP).
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// The currently signed-in user, or null if nobody is signed in yet.
  User? get currentUser => _auth.currentUser;

  /// Fires whenever the user signs in or out — used to decide which screen to
  /// show at startup.
  Stream<User?> authState() => _auth.authStateChanges();

  /// The display name we show next to messages.
  String get displayName => _auth.currentUser?.displayName ?? 'Anonymous';

  /// Signs the user in anonymously (if needed) and saves [name] as their
  /// display name, both on the auth account and in their `users/{uid}` doc.
  Future<void> signInWithName(String name) async {
    final cleaned = name.trim();
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final user = _auth.currentUser!;
    await user.updateDisplayName(cleaned);
    await _db.collection('users').doc(user.uid).set({
      'displayName': cleaned,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() => _auth.signOut();
}

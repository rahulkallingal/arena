import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';

/// Keeps the app civil: reporting bad messages and blocking users.
///
/// Reports are written to a `reports` collection so you can review them later
/// (and a future Cloud Function can auto-hide repeatedly-reported messages).
/// Blocks are stored ON THE PHONE — a blocked person's messages simply stop
/// showing for this user. Simple, instant, and works without extra rules.
class ModerationService {
  static const _blockedKey = 'blocked_user_ids';
  final _db = FirebaseFirestore.instance;

  /// The set of user ids this person has blocked.
  Future<Set<String>> loadBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_blockedKey) ?? <String>[]).toSet();
  }

  Future<Set<String>> blockUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_blockedKey) ?? <String>[]).toSet()
      ..add(uid);
    await prefs.setStringList(_blockedKey, set.toList());
    return set;
  }

  Future<Set<String>> unblockUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_blockedKey) ?? <String>[]).toSet()
      ..remove(uid);
    await prefs.setStringList(_blockedKey, set.toList());
    return set;
  }

  /// Files a report about a message.
  Future<void> reportMessage({
    required String roomId,
    required Message message,
    required String reporterId,
    String reason = '',
  }) async {
    await _db.collection('reports').add({
      'roomId': roomId,
      'messageId': message.id,
      'messageText': message.text,
      'offenderId': message.senderId,
      'offenderName': message.senderName,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

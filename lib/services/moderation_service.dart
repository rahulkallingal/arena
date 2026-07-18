import 'dart:convert';

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
  // uid -> display name, so the "Blocked users" screen can show who they are.
  static const _blockedNamesKey = 'blocked_user_names';
  final _db = FirebaseFirestore.instance;

  /// The set of user ids this person has blocked.
  Future<Set<String>> loadBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_blockedKey) ?? <String>[]).toSet();
  }

  /// The blocked users as uid -> name, for the management screen. Older blocks
  /// stored no name; those fall back to "Someone".
  Future<Map<String, String>> loadBlockedProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_blockedKey) ?? <String>[]);
    final names = _readNames(prefs);
    return {for (final id in ids) id: names[id] ?? 'Someone'};
  }

  Map<String, String> _readNames(SharedPreferences prefs) {
    final raw = prefs.getString(_blockedNamesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> blockUser(String uid, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_blockedKey) ?? <String>[]).toSet()
      ..add(uid);
    await prefs.setStringList(_blockedKey, set.toList());
    final names = _readNames(prefs);
    if (name != null && name.isNotEmpty) names[uid] = name;
    await prefs.setString(_blockedNamesKey, jsonEncode(names));
    return set;
  }

  Future<Set<String>> unblockUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_blockedKey) ?? <String>[]).toSet()
      ..remove(uid);
    await prefs.setStringList(_blockedKey, set.toList());
    final names = _readNames(prefs)..remove(uid);
    await prefs.setString(_blockedNamesKey, jsonEncode(names));
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

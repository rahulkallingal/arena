import 'package:cloud_firestore/cloud_firestore.dart';

/// One chat message inside a room. Stored at `rooms/{roomId}/messages/{id}`.
///
/// [stance] lets a debater tag their message as arguing For or Against the
/// topic (or leave it neutral). The chat colours the bubble accordingly so a
/// room reads like a real debate.
enum Stance { neutral, forSide, againstSide }

class Message {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final Stance stance;
  final DateTime? createdAt;

  /// Reactions keyed by user id → emoji (e.g. {uid: '👍'}). One reaction per
  /// user; changing it overwrites the previous one.
  final Map<String, String> reactions;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.stance = Stance.neutral,
    this.createdAt,
    this.reactions = const {},
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawReactions = (d['reactions'] as Map<String, dynamic>?) ?? {};
    return Message(
      id: doc.id,
      text: d['text'] ?? '',
      senderId: d['senderId'] ?? '',
      senderName: d['senderName'] ?? 'Anonymous',
      stance: _stanceFromString(d['stance']),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      reactions: rawReactions.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Total count per emoji, e.g. {'👍': 3, '❤️': 1}.
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  /// The emoji the given user reacted with, or null if they haven't reacted.
  String? myReaction(String? uid) => uid == null ? null : reactions[uid];

  Map<String, dynamic> toCreateMap() => {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'stance': stance.name,
        'createdAt': FieldValue.serverTimestamp(),
        'reactions': <String, String>{},
      };

  static Stance _stanceFromString(dynamic value) {
    switch (value) {
      case 'forSide':
        return Stance.forSide;
      case 'againstSide':
        return Stance.againstSide;
      default:
        return Stance.neutral;
    }
  }
}

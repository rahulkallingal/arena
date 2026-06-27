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

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.stance = Stance.neutral,
    this.createdAt,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Message(
      id: doc.id,
      text: d['text'] ?? '',
      senderId: d['senderId'] ?? '',
      senderName: d['senderName'] ?? 'Anonymous',
      stance: _stanceFromString(d['stance']),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'stance': stance.name,
        'createdAt': FieldValue.serverTimestamp(),
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

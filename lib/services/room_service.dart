import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../models/message.dart';
import '../models/room.dart';

/// Reads and writes debate rooms and their messages in Firestore.
class RoomService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  /// Live list of all rooms, newest activity first. Updates automatically as
  /// rooms are created or get new messages.
  Stream<List<Room>> watchRooms() {
    return _rooms
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Room.fromDoc).toList());
  }

  /// Live list of rooms created by a specific user.
  Stream<List<Room>> watchMyRooms(String userId) {
    return _rooms
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(Room.fromDoc).toList());
  }

  /// Creates a room and returns its new id. For a private room, pass the raw
  /// [password]; we store only its hash.
  Future<String> createRoom({
    required String name,
    required String topic,
    required String category,
    required bool isPrivate,
    String? password,
    required String createdBy,
    required String createdByName,
  }) async {
    final room = Room(
      id: '',
      name: name.trim(),
      topic: topic.trim(),
      category: category,
      isPrivate: isPrivate,
      passwordHash:
          isPrivate && password != null ? hashPassword(password) : null,
      createdBy: createdBy,
      createdByName: createdByName,
    );
    final ref = await _rooms.add(room.toCreateMap());
    return ref.id;
  }

  /// Checks a typed [password] against a room's stored hash.
  bool checkPassword(Room room, String password) {
    if (!room.isPrivate) return true;
    return room.passwordHash == hashPassword(password);
  }

  /// Live list of messages in a room, oldest first (so the newest sits at the
  /// bottom like a normal chat).
  Stream<List<Message>> watchMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Message.fromDoc).toList());
  }

  /// Sends a message and bumps the room's lastActivity so it floats to the top.
  /// Pass [replyTo] to quote another message.
  Future<void> sendMessage({
    required String roomId,
    required String text,
    required String senderId,
    required String senderName,
    required Stance stance,
    Message? replyTo,
  }) async {
    final message = Message(
      id: '',
      text: text.trim(),
      senderId: senderId,
      senderName: senderName,
      stance: stance,
      replyToId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSender: replyTo?.senderName,
    );
    final batch = _db.batch();
    final msgRef = _rooms.doc(roomId).collection('messages').doc();
    batch.set(msgRef, message.toCreateMap());
    batch.update(_rooms.doc(roomId), {
      'lastActivity': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Deletes a message (used when you remove your own message via moderation).
  Future<void> deleteMessage(String roomId, String messageId) async {
    await _rooms.doc(roomId).collection('messages').doc(messageId).delete();
  }

  /// Adds or changes the current user's reaction on a message. Passing the same
  /// emoji the user already has removes it (toggle off).
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String emoji,
    String? currentEmoji,
  }) async {
    final ref = _rooms.doc(roomId).collection('messages').doc(messageId);
    if (currentEmoji == emoji) {
      // Tapped the same one again → remove it.
      await ref.update({'reactions.$userId': FieldValue.delete()});
    } else {
      await ref.update({'reactions.$userId': emoji});
    }
  }

  // ---- Participated / joined rooms --------------------------------------
  CollectionReference<Map<String, dynamic>> _joinedCol(String userId) =>
      _db.collection('users').doc(userId).collection('joinedRooms');

  /// Records that [userId] has joined [room] (so it shows under "Visited").
  /// Stores a denormalized snapshot so the list renders without extra reads.
  /// If [stance] is given it is remembered for next time; merge means an
  /// existing stance is never wiped by a re-join that omits it.
  Future<void> recordJoin(String userId, Room room, {Stance? stance}) async {
    await _joinedCol(userId).doc(room.id).set({
      'roomId': room.id,
      'name': room.name,
      'topic': room.topic,
      'category': room.category,
      'isPrivate': room.isPrivate,
      'createdBy': room.createdBy,
      'createdByName': room.createdByName,
      'joinedAt': FieldValue.serverTimestamp(),
      if (stance != null) 'stance': stance.name,
    }, SetOptions(merge: true));
  }

  /// The stance [userId] previously chose for [roomId], or null if they have
  /// never picked a side in this room yet.
  Future<Stance?> getStoredStance(String userId, String roomId) async {
    final doc = await _joinedCol(userId).doc(roomId).get();
    final name = doc.data()?['stance'];
    if (name == null) return null;
    return Stance.values.firstWhere((s) => s.name == name,
        orElse: () => Stance.neutral);
  }

  /// Updates the remembered stance for a room the user is already in.
  Future<void> setStance(String userId, String roomId, Stance stance) async {
    await _joinedCol(userId).doc(roomId).set(
      {'stance': stance.name},
      SetOptions(merge: true),
    );
  }

  /// Removes a room from this user's "Visited" list (does not delete the room).
  Future<void> removeVisited(String userId, String roomId) async {
    await _joinedCol(userId).doc(roomId).delete();
  }

  // ---- Hidden rooms (creator removes a room from their own list) ---------
  CollectionReference<Map<String, dynamic>> _hiddenCol(String userId) =>
      _db.collection('users').doc(userId).collection('hiddenRooms');

  /// Hides [roomId] from this user's "My Rooms" list WITHOUT deleting the room,
  /// so anyone still chatting there is unaffected.
  Future<void> hideRoom(String userId, String roomId) async {
    await _hiddenCol(userId).doc(roomId).set(
      {'hiddenAt': FieldValue.serverTimestamp()},
    );
  }

  /// Brings a previously hidden room back into the user's list.
  Future<void> unhideRoom(String userId, String roomId) async {
    await _hiddenCol(userId).doc(roomId).delete();
  }

  /// Live set of room ids this user has hidden from their own list.
  Stream<Set<String>> watchHiddenRoomIds(String userId) {
    return _hiddenCol(userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Live list of rooms the user has joined, most recently joined first.
  Stream<List<Room>> watchJoinedRooms(String userId) {
    return _joinedCol(userId)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              return Room(
                id: m['roomId'] ?? d.id,
                name: m['name'] ?? '',
                topic: m['topic'] ?? '',
                category: m['category'] ?? 'Other',
                isPrivate: m['isPrivate'] ?? false,
                createdBy: m['createdBy'] ?? '',
                createdByName: m['createdByName'] ?? 'Someone',
              );
            }).toList());
  }

  /// Scrambles a password with SHA-256 so the real password is never stored.
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }
}

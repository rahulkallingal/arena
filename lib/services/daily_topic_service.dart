import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/daily_topics.dart';
import '../models/room.dart';

/// Picks the "topic of the day" and manages the shared daily room.
///
/// The topic is chosen purely from the calendar date, so EVERY phone shows the
/// same topic on the same day with no server needed. The daily room uses a
/// date-based id (e.g. `daily_2026-6-28`) so everyone lands in the same room.
class DailyTopicService {
  final _db = FirebaseFirestore.instance;

  /// Today's date with the time stripped off.
  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The topic for a given day, chosen deterministically from the date.
  DailyTopic topicFor(DateTime date) {
    final dayNumber =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    final index = dayNumber % kDailyTopics.length;
    return kDailyTopics[index];
  }

  DailyTopic todayTopic() => topicFor(_today());

  String roomIdFor(DateTime date) =>
      'daily_${date.year}-${date.month}-${date.day}';

  String todayRoomId() => roomIdFor(_today());

  /// Returns today's shared daily room, creating it on first access. [uid] /
  /// [name] are the current user (so it satisfies the "create as yourself"
  /// rule); the room still shows "Arena" as the author.
  Future<Room> ensureTodayRoom({
    required String uid,
  }) async {
    final id = todayRoomId();
    final ref = _db.collection('rooms').doc(id);
    final existing = await ref.get();
    if (!existing.exists) {
      final t = todayTopic();
      await ref.set({
        'name': 'Topic of the Day',
        'topic': t.topic,
        'category': t.category,
        'isPrivate': false,
        'passwordHash': null,
        'createdBy': uid,
        'createdByName': 'Arena',
        'isDaily': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });
    }
    final snap = await ref.get();
    return Room.fromDoc(snap);
  }
}

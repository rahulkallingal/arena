import 'package:cloud_firestore/cloud_firestore.dart';

/// The admin-set override for a day's "topic of the day". Stored in Firestore
/// at `config/dailyOverride`. When present for a given date, each phone uses this
/// topic (at the chosen time) for that day's push instead of the hardcoded pool.
class DailyOverride {
  final String topic;
  final String category;
  final String date; // 'yyyy-mm-dd' the override applies to
  final int hour;
  final int minute;
  const DailyOverride({
    required this.topic,
    required this.category,
    required this.date,
    required this.hour,
    required this.minute,
  });

  bool appliesTo(DateTime day) =>
      date == '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
}

class DailyOverrideService {
  static DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('config').doc('dailyOverride');

  /// The current override, or null if none / cleared. Best-effort.
  static Future<DailyOverride?> get() async {
    try {
      final snap = await _doc.get();
      final d = snap.data();
      final topic = (d?['topic'] as String?)?.trim() ?? '';
      final date = (d?['date'] as String?) ?? '';
      if (topic.isEmpty || date.isEmpty) return null;
      return DailyOverride(
        topic: topic,
        category: (d?['category'] as String?) ?? 'Trending',
        date: date,
        hour: (d?['hour'] as int?) ?? 9,
        minute: (d?['minute'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Admin: queue [topic] as the override for [date] (yyyy-mm-dd) at [hour]:[minute].
  static Future<void> set({
    required String topic,
    required String date,
    required int hour,
    required int minute,
    String category = 'Trending',
  }) async {
    await _doc.set({
      'topic': topic.trim(),
      'category': category,
      'date': date,
      'hour': hour,
      'minute': minute,
      'setAt': FieldValue.serverTimestamp(),
    });
  }
}

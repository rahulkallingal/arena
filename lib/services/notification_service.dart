import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'daily_topic_service.dart';

/// Local "topic of the day" notifications.
///
/// Each phone schedules its own daily alert (at 9 AM) showing that day's topic,
/// so the daily hook works with NO server. We pre-schedule the next two weeks
/// and refresh them every time the app opens.
///
/// IMPORTANT: every method swallows its own errors. Notifications are a nice
/// extra — a failure here must NEVER stop the app from working (this is exactly
/// what crashed PetBloom's release build).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Sets up the plugin and asks for notification permission. Safe to call once
  /// at startup.
  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _ready = true;
    } catch (_) {
      // Notifications are optional — ignore any setup failure.
    }
  }

  /// Schedules a daily alert with each upcoming day's topic, for [days] ahead.
  /// Called on every app launch so the schedule stays fresh and accurate.
  static Future<void> scheduleDailyTopics({int days = 14, int hour = 9}) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final daily = DailyTopicService();
      final nowUtc = tz.TZDateTime.now(tz.UTC);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_topic',
          'Daily Topic',
          channelDescription: 'The Arena debate topic of the day',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      for (var i = 0; i < days; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final topic = daily.topicFor(date);
        // Build the local 9 AM instant, then express it as a UTC instant so it
        // fires at the right wall-clock time without needing the zone name.
        final localWhen =
            DateTime(date.year, date.month, date.day, hour);
        final whenUtc = tz.TZDateTime.from(localWhen.toUtc(), tz.UTC);
        if (!whenUtc.isAfter(nowUtc)) continue; // skip if already past

        await _plugin.zonedSchedule(
          id: i, // a stable id per day-offset
          title: "Today's debate is live 🔥",
          body: topic.topic,
          scheduledDate: whenUtc,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // Never let a scheduling failure bubble up.
    }
  }
}

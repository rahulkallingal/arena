import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-room "notify me about new messages" opt-in. Default is OFF.
///
/// When a user turns it ON for a room, the phone subscribes to that room's
/// Firebase Cloud Messaging topic. A Cloud Function then pushes a notification
/// to that topic on every new message — so the alert arrives even when the app
/// is closed. Turning it OFF unsubscribes.
///
/// The on/off choice is also remembered on the phone (shared_preferences) so the
/// bell shows the right state when the room is reopened.
class RoomNotifyService {
  /// The room the user is currently looking at, if any. The foreground message
  /// handler uses this to avoid popping a notification for the room already on
  /// screen. Set when a chat room opens; cleared when it closes.
  static String? activeRoomId;

  static String _prefKey(String roomId) => 'notify_$roomId';

  /// FCM topic names only allow [a-zA-Z0-9-_.~%]. Room ids are normally safe,
  /// but sanitise defensively. MUST match the sanitising in the Cloud Function.
  static String topicFor(String roomId) =>
      'room_${roomId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')}';

  /// Whether notifications are currently on for [roomId].
  static Future<bool> isOn(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(roomId)) ?? false;
  }

  /// Turns notifications on/off for [roomId]. Subscribes/unsubscribes the phone
  /// to the room's push topic and remembers the choice. Throws if it can't reach
  /// Firebase, so the caller can revert the toggle and warn the user.
  static Future<void> setOn(String roomId, bool on) async {
    final topic = topicFor(roomId);
    if (on) {
      // Make sure we're allowed to show notifications (Android 13+/iOS).
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(roomId), on);
  }
}

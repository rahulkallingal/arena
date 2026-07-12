import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'models/room.dart';
import 'screens/chat_room_screen.dart';
import 'screens/login_screen.dart';
import 'screens/rooms_list_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/room_notify_service.dart';
import 'theme.dart';

/// Lets push/notification handlers navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Runs when a push arrives while the app is in the background or terminated.
/// The message carries a `notification` payload, so Android shows it itself —
/// there's nothing to do here, but a handler must be registered.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connects the app to your Firebase project by reading the
  // android/app/google-services.json file added during setup.
  await Firebase.initializeApp();
  // Set up the daily "topic of the day" alerts. Best-effort — wrapped so it can
  // never block or crash startup.
  await NotificationService.init();
  await NotificationService.scheduleDailyTopics();
  // Tapping a foreground notification we showed ourselves opens its room.
  NotificationService.onRoomTap = _openRoom;
  // Every device joins the app-wide broadcast topic so admin pushes reach all.
  await RoomNotifyService.subscribeAll();
  _setupPushNotifications();
  _wireUserReplyTopic();
  runApp(const ArenaApp());
}

/// Opens the room a tapped notification points at. Loads the room from
/// Firestore by id, then pushes the chat screen via the global navigator.
/// Best-effort — a failure here must never crash the app.
Future<void> _openRoom(String? roomId) async {
  if (roomId == null || roomId.isEmpty) return;
  // Only makes sense once someone is signed in.
  if (FirebaseAuth.instance.currentUser == null) return;
  try {
    final doc =
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
    if (!doc.exists) return;
    final room = Room.fromDoc(doc);
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)));
  } catch (_) {
    // Non-fatal — just don't navigate.
  }
}

/// Reads the roomId out of a push and opens that room. Used for taps that reach
/// us through Firebase (app in background, or launched from a cold start).
void _openRoomFromMessage(RemoteMessage? message) {
  if (message == null) return;
  _openRoom(message.data['roomId'] as String?);
}

/// Subscribes each signed-in device to that user's personal reply topic, so
/// "someone replied to you" pushes reach the right person — and unsubscribes on
/// logout so a shared phone's next user doesn't inherit the alerts.
String? _replyTopicUid;
void _wireUserReplyTopic() {
  try {
    AuthService().authState().listen((user) async {
      final uid = user?.uid;
      if (uid == _replyTopicUid) return;
      final previous = _replyTopicUid;
      _replyTopicUid = uid;
      if (previous != null) await RoomNotifyService.unsubscribeUser(previous);
      if (uid != null) await RoomNotifyService.subscribeUser(uid);
    });
  } catch (_) {
    // Push is optional — never block startup.
  }
}

/// Wires up per-room push notifications. Best-effort — a failure here must never
/// stop the app from starting.
void _setupPushNotifications() {
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    // App launched from a terminated state by tapping a push → open its room.
    FirebaseMessaging.instance.getInitialMessage().then(_openRoomFromMessage);
    // Push tapped while the app was in the background → open its room.
    FirebaseMessaging.onMessageOpenedApp.listen(_openRoomFromMessage);
    // When a push arrives while the app is open, show it ourselves — unless the
    // user is already looking at that very room.
    FirebaseMessaging.onMessage.listen((message) {
      final roomId = message.data['roomId'] as String?;
      // If the user is already looking at that room they can see the message,
      // so don't pop a redundant notification.
      if (roomId != null && roomId == RoomNotifyService.activeRoomId) return;
      final n = message.notification;
      if (n == null) return;
      switch (message.data['type']) {
        case 'reply':
          NotificationService.showReply(
              n.title ?? 'Arena', n.body ?? 'Someone replied to you',
              roomId: roomId);
          break;
        case 'trending':
          NotificationService.showTrending(n.title ?? 'Arena',
              n.body ?? 'A debate you joined is on fire 🔥',
              roomId: roomId);
          break;
        case 'broadcast':
          NotificationService.showBroadcast(
              n.title ?? 'Arena', n.body ?? 'A new debate is live 🔥',
              roomId: roomId);
          break;
        default:
          NotificationService.showRoomMessage(
              n.title ?? 'Arena', n.body ?? 'New message',
              roomId: roomId);
      }
    });
  } catch (_) {
    // Push is optional — ignore setup failures.
  }
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arena',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildArenaTheme(),
      home: const _Root(),
    );
  }
}

/// Decides the first screen: if the user has already picked a name (is signed
/// in) we go straight to the rooms list, otherwise we ask for a name.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder(
      stream: auth.authState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return const RoomsListScreen();
      },
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/rooms_list_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/room_notify_service.dart';
import 'theme.dart';

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
  _setupPushNotifications();
  runApp(const ArenaApp());
}

/// Wires up per-room push notifications. Best-effort — a failure here must never
/// stop the app from starting.
void _setupPushNotifications() {
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    // When a push arrives while the app is open, show it ourselves — unless the
    // user is already looking at that very room.
    FirebaseMessaging.onMessage.listen((message) {
      final roomId = message.data['roomId'];
      if (roomId != null && roomId == RoomNotifyService.activeRoomId) return;
      final n = message.notification;
      if (n != null) {
        NotificationService.showRoomMessage(
            n.title ?? 'Arena', n.body ?? 'New message');
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

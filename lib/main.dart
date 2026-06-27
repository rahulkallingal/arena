import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/name_screen.dart';
import 'screens/rooms_list_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connects the app to your Firebase project. The firebase_options.dart file
  // is generated for you by the `flutterfire configure` command during setup.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Set up the daily "topic of the day" alerts. Best-effort — wrapped so it can
  // never block or crash startup.
  await NotificationService.init();
  await NotificationService.scheduleDailyTopics();
  runApp(const ArenaApp());
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
        if (user == null || (user.displayName ?? '').isEmpty) {
          return const NameScreen();
        }
        return const RoomsListScreen();
      },
    );
  }
}

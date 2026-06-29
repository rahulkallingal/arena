import 'package:flutter/material.dart';

import '../data/daily_topics.dart';
import '../models/room.dart';
import '../services/auth_service.dart';
import '../services/daily_topic_service.dart';
import '../services/room_service.dart';
import '../theme.dart';
import '../widgets/join_stance_dialog.dart';
import '../widgets/room_card.dart';
import 'chat_room_screen.dart';
import 'create_room_screen.dart';
import 'login_screen.dart';
import 'room_discovery_screen.dart';

/// The home screen: today's featured topic, a search box, category filters, and
/// the live list of every debate room.
class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> {
  final _rooms = RoomService();
  final _auth = AuthService();
  final _daily = DailyTopicService();
  final _searchController = TextEditingController();

  String _query = '';
  String? _category; // null = all categories
  bool _openingDaily = false;
  bool _showJoined = false; // false = rooms I created, true = rooms I joined
  bool _hideVerifyBanner = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDailyRoom() async {
    if (_openingDaily) return;
    setState(() => _openingDaily = true);
    try {
      final room = await _daily.ensureTodayRoom(uid: _auth.currentUser!.uid);
      // Remember the daily room under "Visited" too, like any other room.
      try {
        await _rooms.recordJoin(_auth.currentUser!.uid, room);
      } catch (_) {/* non-fatal */}
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open today\'s room.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingDaily = false);
    }
  }

  bool _matchesFilters(Room room) {
    if (room.isDaily) return false; // shown in the featured card instead
    if (_category != null && room.category != _category) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return room.name.toLowerCase().contains(q) ||
        room.topic.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arena',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            tooltip: 'Discover rooms',
            icon: const Icon(Icons.explore),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RoomDiscoveryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New room'),
      ),
      body: Column(
        children: [
          if (_auth.currentUser != null &&
              !(_auth.currentUser!.emailVerified) &&
              !_hideVerifyBanner)
            _VerifyEmailBanner(
              onResend: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _auth.sendEmailVerification();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Verification email sent.')),
                  );
                } catch (_) {}
              },
              onDismiss: () => setState(() => _hideVerifyBanner = true),
            ),
          _DailyTopicCard(
            topic: _daily.todayTopic(),
            loading: _openingDaily,
            onTap: _openDailyRoom,
          ),
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
          ),
          _CategoryFilter(
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
          ),
          _RoomsToggle(
            showJoined: _showJoined,
            onChanged: (v) => setState(() => _showJoined = v),
          ),
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: _showJoined
                  ? _rooms.watchJoinedRooms(_auth.currentUser!.uid)
                  : _rooms.watchMyRooms(_auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Centered(
                    emoji: '⚠️',
                    title: 'Could not load rooms',
                    subtitle: 'Check your internet connection and try again.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list =
                    snapshot.data!.where(_matchesFilters).toList();
                if (list.isEmpty) {
                  final filtering = _query.isNotEmpty || _category != null;
                  return _Centered(
                    emoji: filtering
                        ? '🔍'
                        : (_showJoined ? '👥' : '🗣️'),
                    title: filtering
                        ? 'No rooms match'
                        : (_showJoined
                            ? 'No visited rooms yet'
                            : 'No rooms created yet'),
                    subtitle: filtering
                        ? 'Try a different search or category.'
                        : (_showJoined
                            ? 'Rooms you open will show up here, so you can '
                                'jump back in any time.'
                            : 'Create a new debate room or discover rooms from others!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 90),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final room = list[i];
                    return RoomCard(
                      room: room,
                      onTap: () => _openRoom(room),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRoom(Room room) async {
    if (room.isPrivate) {
      final ok = await _askPassword(room);
      if (ok != true) return;
    }
    if (!mounted) return;
    // Ask which side they're on before entering the debate.
    final stance = await pickJoinStance(context, topic: room.topic);
    if (stance == null || !mounted) return;
    // Remember this room under "Joined" so they can come back easily.
    try {
      await _rooms.recordJoin(_auth.currentUser!.uid, room);
    } catch (_) {/* non-fatal */}
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(room: room, initialStance: stance),
      ),
    );
  }

  Future<bool?> _askPassword(Room room) {
    final controller = TextEditingController();
    String? error;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Private room'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('"${room.name}" needs a password to join.',
                      style: const TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(88, 44),
                  ),
                  onPressed: () {
                    if (_rooms.checkPassword(room, controller.text)) {
                      Navigator.pop(context, true);
                    } else {
                      setLocal(() => error = 'Wrong password');
                    }
                  },
                  child: const Text('Join'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A toggle to switch the list between rooms I created and rooms I've joined.
class _RoomsToggle extends StatelessWidget {
  final bool showJoined;
  final ValueChanged<bool> onChanged;
  const _RoomsToggle({required this.showJoined, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          _seg('My Rooms', !showJoined, () => onChanged(false)),
          const SizedBox(width: 8),
          _seg('Visited', showJoined, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// A dismissible banner nudging the user to verify their email.
class _VerifyEmailBanner extends StatelessWidget {
  final VoidCallback onResend;
  final VoidCallback onDismiss;
  const _VerifyEmailBanner({required this.onResend, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accent.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              size: 18, color: AppColors.textDark),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Please verify your email to secure your account.',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          TextButton(onPressed: onResend, child: const Text('Resend')),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// The featured "Topic of the Day" banner at the top of the list.
class _DailyTopicCard extends StatelessWidget {
  final DailyTopic topic;
  final bool loading;
  final VoidCallback onTap;

  const _DailyTopicCard({
    required this.topic,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'TOPIC OF THE DAY',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to join the debate →',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search rooms…',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _CategoryFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = <String?>[null, ...kCategories];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = items[i];
          final isSel = c == selected;
          final label = c == null ? 'All' : '${categoryEmoji(c)} $c';
          return ChoiceChip(
            label: Text(label),
            selected: isSel,
            onSelected: (_) => onSelected(c),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
          );
        },
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _Centered(
      {required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

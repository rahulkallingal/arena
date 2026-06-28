import 'package:flutter/material.dart';

import '../data/daily_topics.dart';
import '../models/room.dart';
import '../services/auth_service.dart';
import '../services/daily_topic_service.dart';
import '../services/room_service.dart';
import '../theme.dart';
import '../widgets/room_card.dart';
import 'chat_room_screen.dart';
import 'create_room_screen.dart';
import 'name_screen.dart';

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
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const NameScreen()),
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
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: _rooms.watchRooms(),
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
                  return _Centered(
                    emoji: _query.isNotEmpty || _category != null ? '🔍' : '🗣️',
                    title: _query.isNotEmpty || _category != null
                        ? 'No rooms match'
                        : 'No debates yet',
                    subtitle: _query.isNotEmpty || _category != null
                        ? 'Try a different search or category.'
                        : 'Be the first — tap "New room" to start one.',
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
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
      );
    }
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

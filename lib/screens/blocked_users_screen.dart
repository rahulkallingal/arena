import 'package:flutter/material.dart';

import '../services/moderation_service.dart';
import '../theme.dart';

/// Lists the people this user has blocked (on this device) and lets them
/// unblock. Blocks are local to the phone — see [ModerationService].
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _moderation = ModerationService();
  Map<String, String> _blocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final blocked = await _moderation.loadBlockedProfiles();
    if (mounted) {
      setState(() {
        _blocked = blocked;
        _loading = false;
      });
    }
  }

  Future<void> _unblock(String uid, String name) async {
    await _moderation.unblockUser(uid);
    if (mounted) {
      setState(() => _blocked = Map.of(_blocked)..remove(uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name unblocked — you\'ll see their messages again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Blocked users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        'Blocked people\'s messages are hidden from you in every '
                        'room, on this device. Unblock to see them again.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textGrey, height: 1.3),
                      ),
                    ),
                    for (final entry in _blocked.entries)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            entry.value.isNotEmpty
                                ? entry.value[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(entry.value),
                        trailing: OutlinedButton(
                          onPressed: () => _unblock(entry.key, entry.value),
                          child: const Text('Unblock'),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 48, color: AppColors.textGrey),
            SizedBox(height: 12),
            Text(
              "You haven't blocked anyone",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
            SizedBox(height: 6),
            Text(
              'Long-press a message in any room and choose Block to hide that '
              'person. They\'ll show up here so you can unblock them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

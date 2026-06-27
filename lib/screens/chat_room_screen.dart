import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../services/auth_service.dart';
import '../services/moderation_service.dart';
import '../services/room_service.dart';
import '../theme.dart';
import '../widgets/message_bubble.dart';

/// The live debate. Shows the topic at the top, the running conversation, and
/// an input bar where you pick a stance (For / Against / Neutral) and send.
class ChatRoomScreen extends StatefulWidget {
  final Room room;
  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _rooms = RoomService();
  final _auth = AuthService();
  final _moderation = ModerationService();

  Stance _stance = Stance.neutral;
  bool _sending = false;
  Set<String> _blocked = {};

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    final blocked = await _moderation.loadBlocked();
    if (mounted) setState(() => _blocked = blocked);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final user = _auth.currentUser!;
    try {
      await _rooms.sendMessage(
        roomId: widget.room.id,
        text: text,
        senderId: user.uid,
        senderName: _auth.displayName,
        stance: _stance,
      );
      _input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message failed — check your internet.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Long-press menu on a message: delete your own, or report/block others.
  void _showMessageActions(Message m) {
    final isMine = m.senderId == _auth.currentUser?.uid;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.primary),
                  title: const Text('Delete my message'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _deleteMessage(m);
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report message'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _reportMessage(m);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.primary),
                  title: Text('Block ${m.senderName}'),
                  subtitle:
                      const Text('Hide all their messages on this phone'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _blockUser(m);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(Message m) async {
    try {
      await _rooms.deleteMessage(widget.room.id, m.id);
    } catch (_) {
      _toast('Could not delete the message.');
    }
  }

  Future<void> _reportMessage(Message m) async {
    try {
      await _moderation.reportMessage(
        roomId: widget.room.id,
        message: m,
        reporterId: _auth.currentUser!.uid,
      );
      _toast('Thanks — message reported.');
    } catch (_) {
      _toast('Could not send the report.');
    }
  }

  Future<void> _blockUser(Message m) async {
    final updated = await _moderation.blockUser(m.senderId);
    if (mounted) {
      setState(() => _blocked = updated);
      _toast('${m.senderName} blocked.');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.room.name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              '${categoryEmoji(widget.room.category)} ${widget.room.category}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _TopicBanner(topic: widget.room.topic),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _rooms.watchMessages(widget.room.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load messages.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Hide messages from anyone this user has blocked.
                final messages = snapshot.data!
                    .where((m) => !_blocked.contains(m.senderId))
                    .toList();
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No arguments yet.\nFire the first shot! 🔥',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  );
                }
                // Jump to the newest message after the list builds.
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _jumpToBottom());
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return GestureDetector(
                      onLongPress: () => _showMessageActions(m),
                      child: MessageBubble(
                        message: m,
                        isMine: m.senderId == myUid,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _input,
            stance: _stance,
            sending: _sending,
            onStanceChanged: (s) => setState(() => _stance = s),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _TopicBanner extends StatelessWidget {
  final String topic;
  const _TopicBanner({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              topic,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Stance stance;
  final bool sending;
  final ValueChanged<Stance> onStanceChanged;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.stance,
    required this.sending,
    required this.onStanceChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _StanceChip(
                  label: 'For',
                  color: AppColors.forSide,
                  selected: stance == Stance.forSide,
                  onTap: () => onStanceChanged(
                      stance == Stance.forSide ? Stance.neutral : Stance.forSide),
                ),
                const SizedBox(width: 8),
                _StanceChip(
                  label: 'Against',
                  color: AppColors.againstSide,
                  selected: stance == Stance.againstSide,
                  onTap: () => onStanceChanged(stance == Stance.againstSide
                      ? Stance.neutral
                      : Stance.againstSide),
                ),
                const Spacer(),
                if (stance != Stance.neutral)
                  const Text('Stance set',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Make your argument…',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: sending ? null : onSend,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: sending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StanceChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StanceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

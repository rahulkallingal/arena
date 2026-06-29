import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../models/room.dart';
import '../services/room_service.dart';
import '../theme.dart';
import '../widgets/join_stance_dialog.dart';
import 'chat_room_screen.dart';

class JoinByCodeScreen extends StatefulWidget {
  const JoinByCodeScreen({super.key});

  @override
  State<JoinByCodeScreen> createState() => _JoinByCodeScreenState();
}

class _JoinByCodeScreenState extends State<JoinByCodeScreen> {
  final _codeController = TextEditingController();
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _error = 'Please enter a room ID or paste a link');
      return;
    }

    // Extract room ID from link if pasted
    String roomId = code;
    if (code.contains('/room/')) {
      try {
        roomId = code.split('/room/').last.split('?').first;
      } catch (e) {
        setState(() => _error = 'Invalid link format');
        return;
      }
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      // Find room by ID
      final doc =
          await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();

      if (!mounted) return;

      if (!doc.exists) {
        setState(() {
          _searching = false;
          _error = 'Room not found. Check the ID and try again.';
        });
        return;
      }

      final room = Room.fromDoc(doc);

      // Use the side picked last time; only ask the first time in this room.
      if (!mounted) return;
      setState(() => _searching = false);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Stance? stance;
      if (uid != null) {
        try {
          stance = await RoomService().getStoredStance(uid, room.id);
        } catch (_) {/* treat as not-yet-chosen */}
      }
      if (stance == null) {
        if (!mounted) return;
        stance = await pickJoinStance(context, topic: room.topic);
        if (stance == null || !mounted) return;
      }

      // Remember this room under "Visited" so it shows in their history.
      if (uid != null) {
        try {
          await RoomService().recordJoin(uid, room, stance: stance);
        } catch (_) {/* non-fatal */}
      }

      // Navigate to room with the chosen stance.
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(room: room, initialStance: stance!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'Error joining room: ${e.toString()}';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        _codeController.text = data!.text!;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pasting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Join by Code'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Enter Room ID or Paste Link',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can paste the room ID or the full link that was shared with you.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Input field
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: 'Enter room ID or paste link...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste, color: AppColors.primary),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 16),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Join button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _searching ? null : _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _searching
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Join Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Example section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Examples:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _exampleItem(
                      'Room ID:',
                      'debate-abc123xyz',
                    ),
                    const SizedBox(height: 12),
                    _exampleItem(
                      'Link:',
                      'https://arena.app/room/debate-abc123xyz',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exampleItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

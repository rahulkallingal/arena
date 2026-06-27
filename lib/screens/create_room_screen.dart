import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../theme.dart';
import 'chat_room_screen.dart';

/// Form to create a new debate room — name, the topic/question, a category, and
/// whether it's public or private (with a password).
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _name = TextEditingController();
  final _topic = TextEditingController();
  final _password = TextEditingController();
  final _rooms = RoomService();
  final _auth = AuthService();

  String _category = kCategories.first;
  bool _isPrivate = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final topic = _topic.text.trim();
    if (name.length < 3) {
      setState(() => _error = 'Give the room a name (at least 3 characters).');
      return;
    }
    if (topic.length < 5) {
      setState(() => _error = 'Write the debate topic (at least 5 characters).');
      return;
    }
    if (_isPrivate && _password.text.trim().length < 4) {
      setState(() => _error = 'Private rooms need a password (4+ characters).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = _auth.currentUser!;
      final id = await _rooms.createRoom(
        name: name,
        topic: topic,
        category: _category,
        isPrivate: _isPrivate,
        password: _isPrivate ? _password.text : null,
        createdBy: user.uid,
        createdByName: _auth.displayName,
      );
      final room = Room(
        id: id,
        name: name,
        topic: topic,
        category: _category,
        isPrivate: _isPrivate,
        createdBy: user.uid,
        createdByName: _auth.displayName,
      );
      if (!mounted) return;
      // Replace this form with the new room's chat.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
      );
    } catch (e) {
      setState(() => _error = 'Could not create the room. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New debate room')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Label('Room name'),
          TextField(
            controller: _name,
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'e.g. Space Truthers',
            ),
          ),
          const SizedBox(height: 8),
          const _Label('Debate topic / question'),
          TextField(
            controller: _topic,
            maxLength: 200,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              hintText:
                  'e.g. If the moon landing was real, how did a glass visor '
                  'shield astronauts from solar gamma rays?',
            ),
          ),
          const SizedBox(height: 8),
          const _Label('Category'),
          DropdownButtonFormField<String>(
            value: _category,
            items: kCategories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${categoryEmoji(c)}  $c'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Private room'),
            subtitle: const Text('Only people with the password can join'),
          ),
          if (_isPrivate)
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Set a password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.primary)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create & open'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

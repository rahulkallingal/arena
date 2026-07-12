import 'package:flutter/material.dart';

import '../data/avatars.dart';

/// A round avatar for a user. Shows their chosen emoji on a coloured circle; if
/// they haven't picked one, falls back to the first letter of their name.
///
/// [emoji] is whatever is stored on the profile/message (the picked emoji). A
/// stored value that looks like a URL (e.g. an old Google photo URL) is treated
/// as "no emoji" and falls back to the initial, so it never renders as raw text.
class UserAvatar extends StatelessWidget {
  final String? emoji;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    required this.emoji,
    required this.name,
    this.size = 36,
  });

  bool get _hasEmoji {
    final e = emoji?.trim();
    return e != null && e.isNotEmpty && !e.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final seed = _hasEmoji ? emoji!.trim() : (name.isEmpty ? '?' : name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarColorFor(seed),
        shape: BoxShape.circle,
      ),
      child: _hasEmoji
          ? Text(emoji!.trim(), style: TextStyle(fontSize: size * 0.55))
          : Text(
              _initial(name),
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  static String _initial(String name) {
    final t = name.trim();
    return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
  }
}

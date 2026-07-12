import 'package:flutter/material.dart';

/// The set of emoji "avatars" a user can pick as their display picture.
///
/// An avatar is just an emoji drawn on a coloured circle — no image files, no
/// storage cost, and it works offline. The chosen emoji is stored on the user's
/// profile (and copied onto each message) so it can be shown next to their name.
const List<String> kAvatarEmojis = [
  '😀', '😎', '🤩', '🥳', '🤠', '🤖', '👽', '👾',
  '🦊', '🐼', '🐯', '🦁', '🐶', '🐸', '🐵', '🦉',
  '🚀', '🎸', '⚽', '🎮', '🍕', '🌮', '🔥', '⭐',
];

/// Background colours for the avatar circles. The colour is chosen
/// deterministically from the avatar/name, so the same person is always the
/// same colour on every device.
const List<Color> _kAvatarColors = [
  Color(0xFFEF5350), // red
  Color(0xFFAB47BC), // purple
  Color(0xFF5C6BC0), // indigo
  Color(0xFF29B6F6), // light blue
  Color(0xFF26A69A), // teal
  Color(0xFF66BB6A), // green
  Color(0xFFFFA726), // orange
  Color(0xFFFF7043), // deep orange
  Color(0xFF8D6E63), // brown
  Color(0xFF78909C), // blue grey
];

/// A stable background colour for [seed] (an emoji or a display name).
Color avatarColorFor(String seed) {
  if (seed.isEmpty) return _kAvatarColors.first;
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _kAvatarColors[hash % _kAvatarColors.length];
}

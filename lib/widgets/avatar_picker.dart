import 'package:flutter/material.dart';

import '../data/avatars.dart';
import '../theme.dart';
import 'user_avatar.dart';

/// A grid of the available emoji avatars. Tapping one calls [onSelected]; the
/// currently [selected] avatar is ringed. Used at signup and on the profile
/// screen.
class AvatarPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: kAvatarEmojis.map((e) {
        final isSelected = e == selected;
        return GestureDetector(
          onTap: () => onSelected(e),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: UserAvatar(emoji: e, name: e, size: 44),
          ),
        );
      }).toList(),
    );
  }
}

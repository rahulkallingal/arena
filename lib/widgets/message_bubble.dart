import 'package:flutter/material.dart';

import '../models/message.dart';
import '../theme.dart';

/// One chat bubble. My own messages sit on the right; others on the left.
/// A small coloured tag shows whether the message argues For or Against the
/// topic.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const MessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine ? AppColors.primary : AppColors.card;
    final textColor = isMine ? Colors.white : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border: isMine
                  ? null
                  : const Border.fromBorderSide(
                      BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.stance != Stance.neutral) ...[
                  _StanceTag(stance: message.stance, onDark: isMine),
                  const SizedBox(height: 4),
                ],
                Text(
                  message.text,
                  style: TextStyle(fontSize: 15, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "FOR" / "AGAINST" pill shown at the top of a bubble.
class _StanceTag extends StatelessWidget {
  final Stance stance;
  final bool onDark; // true when sitting on my own (red) bubble
  const _StanceTag({required this.stance, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final isFor = stance == Stance.forSide;
    final color = isFor ? AppColors.forSide : AppColors.againstSide;
    final label = isFor ? 'FOR' : 'AGAINST';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.22) : color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/room_service.dart';
import '../theme.dart';

/// A compact "Who's winning?" panel shown at the top of a debate room. Anyone
/// watching can vote which side is winning; the bar shows the live split.
class VotePanel extends StatelessWidget {
  final String roomId;
  final String? myUid;

  const VotePanel({super.key, required this.roomId, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final rooms = RoomService();
    return StreamBuilder<VoteTally>(
      stream: rooms.watchVotes(roomId, myUid),
      builder: (context, snap) {
        final tally = snap.data ??
            const VoteTally(forCount: 0, againstCount: 0, myVote: null);
        final total = tally.total;
        final forPct = total == 0 ? 0.5 : tally.forCount / total;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Who\'s winning?',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGrey)),
                  const Spacer(),
                  Text(
                    total == 0 ? 'No votes yet' : '$total vote${total == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // The split bar.
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Expanded(
                      flex: (forPct * 1000).round().clamp(1, 999),
                      child: Container(height: 8, color: AppColors.forSide),
                    ),
                    Expanded(
                      flex: ((1 - forPct) * 1000).round().clamp(1, 999),
                      child: Container(height: 8, color: AppColors.againstSide),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _VoteButton(
                      label: 'FOR',
                      count: tally.forCount,
                      color: AppColors.forSide,
                      selected: tally.myVote == 'for',
                      onTap: myUid == null
                          ? null
                          : () => rooms.castVote(
                              roomId: roomId, userId: myUid!, side: 'for'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VoteButton(
                      label: 'AGAINST',
                      count: tally.againstCount,
                      color: AppColors.againstSide,
                      selected: tally.myVote == 'against',
                      onTap: myUid == null
                          ? null
                          : () => rooms.castVote(
                              roomId: roomId, userId: myUid!, side: 'against'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

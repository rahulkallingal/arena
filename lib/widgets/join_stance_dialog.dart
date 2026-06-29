import 'package:flutter/material.dart';

import '../models/message.dart';
import '../theme.dart';

/// Asks the user which side they're on before entering a debate. Returns the
/// chosen [Stance], or null if they cancelled.
Future<Stance?> pickJoinStance(BuildContext context, {required String topic}) {
  return showModalBottomSheet<Stance>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pick your side',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                topic,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _SideButton(
                label: 'Support 👍',
                color: AppColors.forSide,
                onTap: () => Navigator.pop(ctx, Stance.forSide),
              ),
              const SizedBox(height: 10),
              _SideButton(
                label: 'Oppose 👎',
                color: AppColors.againstSide,
                onTap: () => Navigator.pop(ctx, Stance.againstSide),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx, Stance.neutral),
                child: const Text('Just watching for now',
                    style: TextStyle(color: AppColors.textGrey)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SideButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SideButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

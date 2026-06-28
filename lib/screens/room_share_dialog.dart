import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room.dart';
import '../theme.dart';

class RoomShareDialog extends StatefulWidget {
  final Room room;

  const RoomShareDialog({super.key, required this.room});

  @override
  State<RoomShareDialog> createState() => _RoomShareDialogState();
}

class _RoomShareDialogState extends State<RoomShareDialog> {
  bool _copiedId = false;
  bool _copiedLink = false;

  String get _roomLink => 'https://arena.app/room/${widget.room.id}';

  Future<void> _copyToClipboard(String text, {bool isLink = false}) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      if (isLink) {
        _copiedLink = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copiedLink = false);
        });
      } else {
        _copiedId = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copiedId = false);
        });
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLink ? 'Link copied!' : 'Room ID copied!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Room',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.room.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Room ID Section
            const Text(
              'Room ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.room.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _copyToClipboard(widget.room.id, isLink: false),
                    icon: Icon(
                      _copiedId ? Icons.check : Icons.copy,
                      size: 18,
                    ),
                    label: Text(_copiedId ? 'Copied' : 'Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copiedId ? Colors.green : AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Room Link Section
            const Text(
              'Share Link',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _roomLink,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(_roomLink, isLink: true),
                    icon: Icon(
                      _copiedLink ? Icons.check : Icons.copy,
                      size: 18,
                    ),
                    label: Text(_copiedLink ? 'Copied' : 'Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _copiedLink ? Colors.green : AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share buttons
            const Text(
              'Share Via',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareButton(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  onTap: () => _shareVia('whatsapp'),
                ),
                _shareButton(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: () => _shareVia('email'),
                ),
                _shareButton(
                  icon: Icons.share,
                  label: 'More',
                  onTap: () => _shareVia('more'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _shareVia(String platform) {
    final message =
        'Join the debate! Room: ${widget.room.name}\n\n$_roomLink\n\nOr use Room ID: ${widget.room.id}';

    // TODO: Implement actual sharing via platform
    // For now, just copy to clipboard as fallback
    _copyToClipboard(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share message copied for $platform')),
    );
  }
}

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
      child: SingleChildScrollView(
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
            _valueBox(
              value: widget.room.id,
              monospaceSize: 14,
              color: AppColors.textDark,
              copied: _copiedId,
              onCopy: () => _copyToClipboard(widget.room.id, isLink: false),
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
            _valueBox(
              value: _roomLink,
              monospaceSize: 12,
              color: AppColors.primary,
              copied: _copiedLink,
              onCopy: () => _copyToClipboard(_roomLink, isLink: true),
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

  /// A full-width box that shows a selectable value with a Copy button below it.
  /// Laid out as a Column (not a Row with Expanded) so it always renders the
  /// value and the button regardless of available width.
  Widget _valueBox({
    required String value,
    required double monospaceSize,
    required Color color,
    required bool copied,
    required VoidCallback onCopy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: monospaceSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              icon: Icon(copied ? Icons.check : Icons.copy, size: 18),
              label: Text(copied ? 'Copied' : 'Copy'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: copied ? Colors.green : AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/services/streak_saver_service.dart';

class StreakSaverDialog extends ConsumerStatefulWidget {
  final DateTime brokenDate;
  final int streakLost;

  const StreakSaverDialog({
    super.key,
    required this.brokenDate,
    required this.streakLost,
  });

  @override
  ConsumerState<StreakSaverDialog> createState() => _StreakSaverDialogState();
}

class _StreakSaverDialogState extends ConsumerState<StreakSaverDialog> {
  final _streakSaverService = StreakSaverService();
  bool _isLoading = false;

  Future<void> _restoreStreak(bool useFreeStreak) async {
    setState(() => _isLoading = true);

    final success = await _streakSaverService.restoreStreak(useFreeStreak);

    if (!mounted) return;

    if (success) {
      // Refresh providers
      ref.invalidate(streakSaversProvider);
      ref.invalidate(totalXpProvider);

      Navigator.of(context).pop(true); // Return success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 Streak restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to restore streak'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final streakSaversAsync = ref.watch(streakSaversProvider);
    final totalXpAsync = ref.watch(totalXpProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final dialogRadius = (20 * scale).clamp(16.0, 20.0);
    final dialogPad = (24 * scale).clamp(18.0, 24.0);
    final iconBoxSize = (80 * scale).clamp(68.0, 80.0);
    final iconSize = (50 * scale).clamp(40.0, 50.0);
    final titleSize = (24 * scale).clamp(19.0, 24.0);
    final messageSize = (14 * scale).clamp(12.0, 14.0);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(dialogPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department_outlined,
                size: iconSize,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Streak Broken 💔',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              'Your ${widget.streakLost}-day streak ended on ${_formatDate(widget.brokenDate)}',
              style: TextStyle(fontSize: messageSize, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Restoration Options
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                  children: [
                    // Option 1: Free Streak Saver
                    streakSaversAsync.when(
                      data: (savers) {
                        if (savers > 0) {
                          return _buildOption(
                            icon: Icons.card_giftcard,
                            title: 'Use Free Streak Saver',
                            subtitle: 'You have $savers available',
                            color: Colors.green,
                            scale: scale,
                            onTap: () => _restoreStreak(true),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    // Option 2: Use XP
                    totalXpAsync.when(
                      data: (xp) {
                        final canAfford = xp >= 100;
                        return _buildOption(
                          icon: Icons.bolt,
                          title: 'Restore with 100 XP',
                          subtitle:
                              canAfford
                                  ? 'Current XP: $xp'
                                  : 'Insufficient XP (need 100)',
                          color: canAfford ? Colors.amber : Colors.grey,
                          scale: scale,
                          onTap: canAfford ? () => _restoreStreak(false) : null,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
            const SizedBox(height: 16),
            // Cancel Button
            TextButton(
              onPressed:
                  _isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text(
                'Start Fresh',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required double scale,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    final tilePad = (16 * scale).clamp(12.0, 16.0);
    final leadingIconSize = (32 * scale).clamp(26.0, 32.0);
    final titleSize = (16 * scale).clamp(14.0, 16.0);
    final subtitleSize = (12 * scale).clamp(10.0, 12.0);
    final trailingIconSize = (16 * scale).clamp(13.0, 16.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(tilePad),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey[400],
              size: leadingIconSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: isEnabled ? Colors.grey[700] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: trailingIconSize,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

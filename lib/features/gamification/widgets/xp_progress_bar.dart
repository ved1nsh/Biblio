import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/xp_provider.dart';

class XpProgressBar extends ConsumerWidget {
  final bool showLabel;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const XpProgressBar({
    super.key,
    this.showLabel = true,
    this.height = 8,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpProgressAsync = ref.watch(xpProgressProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final labelSize = (12 * scale).clamp(10.0, 12.0);

    return xpProgressAsync.when(
      data: (progress) {
        final current = progress['current'] ?? 0;
        final min = progress['min'] ?? 0;
        final max = progress['max'] ?? 100;
        final progressInLevel = current - min;
        final levelRange = max - min;
        final percentage =
            levelRange <= 0 ? 0.0 : (progressInLevel / levelRange).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progressInLevel / $levelRange XP',
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: labelSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: height,
                backgroundColor: backgroundColor ?? Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? _getProgressColor(percentage),
                ),
              ),
            ),
          ],
        );
      },
      loading:
          () => ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              minHeight: height,
              backgroundColor: Colors.grey[200],
            ),
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.33) return Colors.red;
    if (percentage < 0.66) return Colors.orange;
    return Colors.green;
  }
}

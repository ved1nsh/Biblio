import 'package:flutter/material.dart';
import '../constants/reading_session_colors.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String suffix;
  final String? subtext;
  final double? progressValue; // Optional progress bar (0.0 to 1.0)
  final Color? progressColor;

  const StatsCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.suffix = '',
    this.subtext,
    this.progressValue,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final labelSize = (13 * scale).clamp(11.0, 14.0);
    final valueSize = (28 * scale).clamp(22.0, 36.0);
    final suffixSize = (14 * scale).clamp(11.0, 16.0);
    final subtextSize = (12 * scale).clamp(10.0, 13.0);
    final iconSize = (16 * scale).roundToDouble().clamp(14.0, 18.0);

    return Container(
      padding: EdgeInsets.all((14 * scale).clamp(12.0, 16.0)),
      decoration: BoxDecoration(
        color: ReadingSessionColors.statsCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and label
          Row(
            children: [
              Icon(icon, size: iconSize, color: iconColor),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                    color: ReadingSessionColors.statsLabelColor,
                    fontFamily: 'SF-UI-Display',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: (10 * scale).clamp(8.0, 12.0)),
          // Value row - aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191B46),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    suffix,
                    style: TextStyle(
                      fontSize: suffixSize,
                      fontWeight: FontWeight.w500,
                      color: ReadingSessionColors.statsLabelColor,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress bar (if provided)
          if (progressValue != null) ...[
            SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: progressValue!,
                  backgroundColor:
                      progressColor?.withValues(alpha: 0.2) ??
                      Colors.blue.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    progressColor ?? Colors.blue,
                  ),
                ),
              ),
            ),
          ],

          // Subtext (if provided) - aligned to the right
          if (subtext != null) ...[
            SizedBox(height: (6 * scale).clamp(4.0, 6.0)),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                subtext!,
                style: TextStyle(
                  fontSize: subtextSize,
                  fontWeight: FontWeight.w500,
                  color: ReadingSessionColors.statsLabelColor,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

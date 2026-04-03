import 'dart:math';
import 'package:flutter/material.dart';

class DailyProgressCard extends StatelessWidget {
  final int todayMinutes;
  final int todaySeconds;
  final int goalMinutes;
  final VoidCallback? onTap;

  const DailyProgressCard({
    super.key,
    required this.todayMinutes,
    this.todaySeconds = 0,
    this.goalMinutes = 30,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD97757);
    const textDark = Color(0xFF2D2D2D);
    const textGrey = Color(0xFF8A8A8A);
    const trackColor = Color(0xFFF0ECE6);

    final totalSeconds = todayMinutes * 60 + todaySeconds;
    final goalSeconds = goalMinutes * 60;
    final progress = (totalSeconds / goalSeconds).clamp(0.0, 1.0);

    final bool useHours = todayMinutes >= 60;
    final int displayPrimary = useHours ? todayMinutes ~/ 60 : todayMinutes;
    final int displaySecondary = useHours ? todayMinutes % 60 : todaySeconds;
    final String primaryUnit = useHours ? 'hr' : 'min';
    final String secondaryUnit = useHours ? 'min' : 'sec';
    final percentage = (progress * 100).round();
    final goalReached = progress >= 1.0;
    final hasStarted = totalSeconds > 0;

    // Helper text for the progress pill
    String progressLabel;
    if (goalReached) {
      progressLabel = 'Goal complete!';
    } else if (!hasStarted) {
      progressLabel = 'Start reading to begin';
    } else if (percentage < 25) {
      progressLabel = 'Just getting started';
    } else if (percentage < 50) {
      progressLabel = 'Keep it up!';
    } else if (percentage < 75) {
      progressLabel = 'Halfway there';
    } else {
      progressLabel = 'Almost done!';
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final arcSize = (230 * scale).clamp(180.0, 230.0);
    final arcHalf = arcSize / 2;
    final timeFont = (42 * scale).clamp(34.0, 42.0);
    final unitFont = (16 * scale).clamp(13.0, 16.0);
    final padH = (24 * scale).clamp(16.0, 24.0);
    final headerFontSize = (17 * scale).clamp(14.0, 17.0);
    final headerIconSize = (20 * scale).clamp(16.0, 20.0);
    final headerIconPad = (9 * scale).clamp(7.0, 9.0);
    final smallFontSize = (13 * scale).clamp(11.0, 13.0);
    final tinyFontSize = (11 * scale).clamp(9.0, 11.0);
    final ctaFontSize = (13 * scale).clamp(11.0, 13.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          padH,
          padH,
          padH,
          (20 * scale).clamp(14.0, 20.0),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ─── Header Row ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(headerIconPad),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: accent,
                    size: headerIconSize,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Today's Reading",
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                    fontFamily: 'SF-UI-Display',
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (goalReached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFF43A047),
                          size: smallFontSize,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Done!',
                          style: TextStyle(
                            fontSize: tinyFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF43A047),
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // ─── Semi-Circle Progress Arc ───────────────────────────
            Center(
              child: CustomPaint(
                size: Size(arcSize, arcHalf),
                painter: _SemiCirclePainter(
                  progress: progress,
                  trackColor: trackColor,
                  progressColor: goalReached ? const Color(0xFF43A047) : accent,
                  strokeWidth: 12,
                ),
                child: SizedBox(
                  width: arcSize,
                  height: arcHalf,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Main time display with spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$displayPrimary',
                            style: TextStyle(
                              fontSize: timeFont,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontFamily: 'SF-UI-Display',
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            primaryUnit,
                            style: TextStyle(
                              fontSize: unitFont,
                              fontWeight: FontWeight.w500,
                              color: textGrey,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            displaySecondary.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: timeFont,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontFamily: 'SF-UI-Display',
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            secondaryUnit,
                            style: TextStyle(
                              fontSize: unitFont,
                              fontWeight: FontWeight.w500,
                              color: textGrey,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Helper text pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (goalReached
                                  ? const Color(0xFF43A047)
                                  : accent)
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          progressLabel,
                          style: TextStyle(
                            fontSize: tinyFontSize,
                            fontWeight: FontWeight.w600,
                            color:
                                goalReached ? const Color(0xFF43A047) : accent,
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ─── Goal Progress Bar ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Goal',
                  style: TextStyle(
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: textGrey,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                Text(
                  useHours
                      ? '${displayPrimary}h ${displaySecondary}m / $goalMinutes min'
                      : '$todayMinutes / $goalMinutes min',
                  style: TextStyle(
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goalReached ? const Color(0xFF43A047) : accent,
                ),
              ),
            ),

            // ─── CTA Footer ────────────────────────────────────────
            if (onTap != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View detailed stats',
                      style: TextStyle(
                        fontSize: ctaFontSize,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: ctaFontSize + 2,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Semi-Circle Progress Painter ────────────────────────────────────────

class _SemiCirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _SemiCirclePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: min(size.width / 2, size.height),
    );

    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    // Draw the semi-circle track (180°)
    canvas.drawArc(rect, pi, pi, false, trackPaint);

    // Draw progress over the track
    if (progress > 0) {
      canvas.drawArc(rect, pi, pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCirclePainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}

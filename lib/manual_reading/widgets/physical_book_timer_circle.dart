import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biblio/reading_session/constants/reading_session_colors.dart';

class PhysicalBookTimerCircle extends StatelessWidget {
  final String displayTime;
  final String label;

  /// Progress from 0.0 to 1.0 for the arc ring (used in Pomodoro/Custom modes)
  final double? progress;

  const PhysicalBookTimerCircle({
    super.key,
    required this.displayTime,
    this.label = 'minutes',
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final timerSize = (250 * scale).clamp(210.0, 250.0).roundToDouble();

    return Center(
      child: SizedBox(
        width: timerSize,
        height: timerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: timerSize,
              height: timerSize,
              decoration: BoxDecoration(
                color: ReadingSessionColors.timerCircleBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ReadingSessionColors.timerCircleBorder.withValues(
                    alpha: 0.25,
                  ),
                  width: (16 * scale).clamp(12.0, 16.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ReadingSessionColors.timerCircleBorder.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            // Progress arc (if countdown mode)
            if (progress != null)
              SizedBox(
                width: timerSize,
                height: timerSize,
                child: CircularProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  strokeWidth: (16 * scale).clamp(12.0, 16.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    ReadingSessionColors.timerCircleBorder,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
            // If no progress (stopwatch mode), show the full border ring
            if (progress == null)
              Container(
                width: timerSize,
                height: timerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ReadingSessionColors.timerCircleBorder,
                    width: (16 * scale).clamp(12.0, 16.0),
                  ),
                ),
              ),
            // Time text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTime,
                  style: GoogleFonts.inter(
                    fontSize: (56 * scale).clamp(48.0, 56.0),
                    fontWeight: FontWeight.w800,
                    color: ReadingSessionColors.timerTextColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w500,
                    color: ReadingSessionColors.timerLabelColor,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

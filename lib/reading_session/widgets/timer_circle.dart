import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/reading_session_colors.dart';

class TimerCircle extends StatelessWidget {
  final String displayTime;

  const TimerCircle({super.key, required this.displayTime});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final circleSize = (220 * scale).roundToDouble().clamp(170.0, 250.0);
    final borderWidth = (14 * scale).roundToDouble().clamp(10.0, 16.0);
    final timeFontSize = (48 * scale).clamp(34.0, 56.0);
    final labelFontSize = (12 * scale).clamp(11.0, 14.0);

    return Center(
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: ReadingSessionColors.timerCircleBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: ReadingSessionColors.timerCircleBorder,
            width: borderWidth,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTime,
                  style: GoogleFonts.inter(
                    fontSize: timeFontSize,
                    fontWeight: FontWeight.w800,
                    color: ReadingSessionColors.timerTextColor,
                  ),
                ),
                Text(
                  'minutes read',
                  style: TextStyle(
                    fontSize: labelFontSize,
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

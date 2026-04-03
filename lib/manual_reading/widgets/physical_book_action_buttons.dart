import 'package:flutter/material.dart';
import 'package:biblio/reading_session/constants/reading_session_colors.dart';

class PhysicalBookActionButtons extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onFinish;

  const PhysicalBookActionButtons({
    super.key,
    required this.isRunning,
    required this.onToggle,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return Column(
      children: [
        // Pause / Resume button
        SizedBox(
          width: double.infinity,
          height: (50 * scale).clamp(42.0, 50.0),
          child: ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: ReadingSessionColors.bookCardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: ReadingSessionColors.timerCircleBorder.withValues(
                    alpha: 0.5,
                  ),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              isRunning ? 'Pause' : 'Resume',
              style: TextStyle(
                fontSize: (18 * scale).clamp(16.0, 18.0),
                fontWeight: FontWeight.w600,
                color: ReadingSessionColors.headerTextColor,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
        SizedBox(height: (12 * scale).clamp(8.0, 12.0)),
        // Finish Session button
        SizedBox(
          width: double.infinity,
          height: (56 * scale).clamp(48.0, 56.0),
          child: ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: ReadingSessionColors.continueButtonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Text(
              'Finish Session',
              style: TextStyle(
                fontSize: (18 * scale).clamp(16.0, 18.0),
                fontWeight: FontWeight.w700,
                color: ReadingSessionColors.continueButtonText,
                fontFamily: 'SF-UI-Display',
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

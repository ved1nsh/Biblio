import 'package:flutter/material.dart';
import '../constants/reading_session_colors.dart';

class ActionButtons extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onEnd;

  const ActionButtons({
    super.key,
    required this.isRunning,
    required this.onToggle,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final buttonHeight = (50 * scale).clamp(44.0, 56.0);
    final fontSize = (15 * scale).clamp(13.0, 16.0);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton.icon(
            onPressed: onToggle,
            icon: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              color: ReadingSessionColors.continueButtonText,
            ),
            label: Text(
              isRunning ? 'Pause Reading' : 'Continue Reading',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: ReadingSessionColors.continueButtonText,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReadingSessionColors.continueButtonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: (10 * scale).clamp(8.0, 12.0)),
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: onEnd,
            style: ElevatedButton.styleFrom(
              backgroundColor: ReadingSessionColors.endButtonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Back to Book',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: ReadingSessionColors.endButtonText,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

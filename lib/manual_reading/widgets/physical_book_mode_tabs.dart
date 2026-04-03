import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biblio/reading_session/constants/reading_session_colors.dart';

class PhysicalBookModeTabs extends StatelessWidget {
  final int selectedMode;
  final Function(int) onModeSelected;

  const PhysicalBookModeTabs({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    const activeColor = ReadingSessionColors.tabActiveBackground;

    return Center(
      child: Container(
        padding: EdgeInsets.all((3 * scale).clamp(2.0, 3.0)),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegment('Stopwatch', 0, activeColor, scale),
            _buildSegment('Pomodoro', 1, activeColor, scale),
            _buildSegment('Custom', 2, activeColor, scale),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(
    String label,
    int mode,
    Color activeColor,
    double scale,
  ) {
    final isSelected = selectedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onModeSelected(mode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: (8 * scale).clamp(6.0, 8.0),
          horizontal: (16 * scale).clamp(12.0, 16.0),
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: (16 * scale).clamp(14.0, 16.0),
            fontWeight: FontWeight.w600,
            color:
                isSelected ? ReadingSessionColors.tabActiveText : activeColor,
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ),
    );
  }
}

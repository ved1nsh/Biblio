import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/reading_session_colors.dart';

class ModeTabs extends StatelessWidget {
  final int selectedMode;
  final Function(int) onModeSelected;

  const ModeTabs({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    const activeColor = ReadingSessionColors.tabActiveBackground;
    final tabFontSize = (14 * scale).clamp(11.0, 16.0);
    final tabVerticalPad = (8 * scale).clamp(6.0, 10.0);
    final tabHorizontalPad = (10 * scale).clamp(8.0, 14.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegment(
                'Open Read',
                0,
                activeColor,
                tabFontSize,
                tabVerticalPad,
                tabHorizontalPad,
              ),
              _buildSegment(
                'Target Read',
                1,
                activeColor,
                tabFontSize,
                tabVerticalPad,
                tabHorizontalPad,
              ),
              _buildSegment(
                'Pomodoro Focus',
                2,
                activeColor,
                tabFontSize,
                tabVerticalPad,
                tabHorizontalPad,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(
    String label,
    int mode,
    Color activeColor,
    double fontSize,
    double vPad,
    double hPad,
  ) {
    final isSelected = selectedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onModeSelected(mode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
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

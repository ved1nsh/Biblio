import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/epub_theme_controller.dart';

class TextSelectionMenu extends StatelessWidget {
  final EpubThemeController themeController;
  final VoidCallback onHighlight;
  final VoidCallback onAi;
  final VoidCallback onNote;
  final VoidCallback onClose;

  const TextSelectionMenu({
    super.key,
    required this.themeController,
    required this.onHighlight,
    required this.onAi,
    required this.onNote,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final containerPadH = (8 * scale).clamp(6.0, 8.0);
    final containerPadV = (8 * scale).clamp(6.0, 8.0);
    final containerRadius = (30 * scale).clamp(24.0, 30.0).roundToDouble();
    final buttonPadH = (16 * scale).clamp(12.0, 16.0);
    final buttonPadV = (10 * scale).clamp(8.0, 10.0);
    final iconSize = (24 * scale).clamp(20.0, 24.0).roundToDouble();
    final fontSize = (11 * scale).clamp(9.0, 11.0);
    final iconLabelGap = (4 * scale).clamp(3.0, 4.0);
    final dividerHeight = (40 * scale).clamp(32.0, 40.0);
    final dividerWidth = 1.0;
    final labelColor = themeController.textColor.withValues(alpha: 0.8);

    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: containerPadH,
            vertical: containerPadV,
          ),
          decoration: BoxDecoration(
            color:
                themeController.isDarkMode
                    ? const Color(0xFF2C2C2C)
                    : Colors.white,
            borderRadius: BorderRadius.circular(containerRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuButton(
                  context: context,
                  icon: Icons.highlight_rounded,
                  label: "Highlight",
                  color: const Color(0xFFFFB74D),
                  onTap: onHighlight,
                  padH: buttonPadH,
                  padV: buttonPadV,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconLabelGap: iconLabelGap,
                  textColor: labelColor,
                ),
                _buildVerticalDivider(dividerHeight, dividerWidth),
                _buildMenuButton(
                  context: context,
                  icon: Icons.auto_awesome_rounded,
                  label: "AI",
                  color: const Color(0xFFD97757),
                  onTap: onAi,
                  padH: buttonPadH,
                  padV: buttonPadV,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconLabelGap: iconLabelGap,
                  textColor: labelColor,
                ),
                _buildVerticalDivider(dividerHeight, dividerWidth),
                _buildMenuButton(
                  context: context,
                  icon: Icons.note_add_rounded,
                  label: "Note",
                  color: const Color(0xFF90CAF9),
                  onTap: onNote,
                  padH: buttonPadH,
                  padV: buttonPadV,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconLabelGap: iconLabelGap,
                  textColor: labelColor,
                ),
                _buildVerticalDivider(dividerHeight, dividerWidth),
                _buildMenuButton(
                  context: context,
                  icon: Icons.close_rounded,
                  label: "Close",
                  color: Colors.grey,
                  onTap: onClose,
                  padH: buttonPadH,
                  padV: buttonPadV,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconLabelGap: iconLabelGap,
                  textColor: labelColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double padH,
    required double padV,
    required double iconSize,
    required double fontSize,
    required double iconLabelGap,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: iconLabelGap),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(double height, double width) {
    return Container(
      height: height,
      width: width,
      color:
          themeController.isDarkMode
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.3),
    );
  }
}

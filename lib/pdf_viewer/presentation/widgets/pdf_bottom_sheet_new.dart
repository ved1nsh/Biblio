import 'dart:ui';

import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PdfBottomSheet extends StatelessWidget {
  final ReadingTimerController timerController;
  final bool isDarkMode;
  final VoidCallback onOpenContents;
  final VoidCallback onReadingTimeTap;
  final VoidCallback onDarkModeToggle;
  final VoidCallback onCircleSearch;

  const PdfBottomSheet({
    super.key,
    required this.timerController,
    required this.isDarkMode,
    required this.onOpenContents,
    required this.onReadingTimeTap,
    required this.onDarkModeToggle,
    required this.onCircleSearch,
  });

  static const double _blurSigma = 25.0;
  static const double _iconSize = 23.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final bgColor =
        isDarkMode
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.78)
            : const Color(0xFFFCF9F5).withValues(alpha: 0.62);
    final borderColor =
        isDarkMode
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.55);
    final iconColor =
        isDarkMode
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.55);

    return Padding(
      padding: EdgeInsets.only(
        left: (20 * scale).clamp(16.0, 20.0),
        right: (20 * scale).clamp(16.0, 20.0),
        bottom: bottomPadding + (14 * scale).clamp(10.0, 14.0),
        top: (6 * scale).clamp(4.0, 6.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: (8 * scale).clamp(6.0, 8.0),
              vertical: (10 * scale).clamp(8.0, 10.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildItem(
                  icon: Icons.format_list_bulleted_rounded,
                  iconColor: iconColor,
                  scale: scale,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenContents();
                  },
                ),
                _buildDivider(),
                ListenableBuilder(
                  listenable: timerController,
                  builder: (context, _) {
                    return _buildItem(
                      icon: Icons.access_time_rounded,
                      iconColor: iconColor,
                      label: timerController.bottomSheetDisplay,
                      scale: scale,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onReadingTimeTap();
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildItem(
                  icon:
                      isDarkMode
                          ? Icons.wb_sunny_rounded
                          : Icons.brightness_2_rounded,
                  iconColor: iconColor,
                  scale: scale,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDarkModeToggle();
                  },
                ),
                _buildDivider(),
                _buildItem(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: iconColor,
                  scale: scale,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCircleSearch();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color iconColor,
    required double scale,
    required VoidCallback onTap,
    String? label,
  }) {
    final size = (_iconSize * scale).clamp(19.0, 23.0);
    final fontSize = (13 * scale).clamp(11.0, 13.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (12 * scale).clamp(10.0, 12.0),
          vertical: (6 * scale).clamp(5.0, 6.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: size),
            if (label != null) ...[
              SizedBox(width: (5 * scale).clamp(4.0, 5.0)),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      color:
          isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
    );
  }
}

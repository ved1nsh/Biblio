import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating menu shown when text is selected in the PDF viewer.
/// Provides Highlight, AI, Note, and Close actions.
/// Styled to match the EPUB TextSelectionMenu but without EpubThemeController dependency.
class PdfTextSelectionMenu extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onHighlight;
  final VoidCallback onAi;
  final VoidCallback onNote;
  final VoidCallback onClose;

  const PdfTextSelectionMenu({
    super.key,
    required this.isDarkMode,
    required this.onHighlight,
    required this.onAi,
    required this.onNote,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return Positioned(
      bottom: (30 * scale).roundToDouble(),
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: (8 * scale).roundToDouble(),
            vertical: (8 * scale).roundToDouble(),
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular((30 * scale).roundToDouble()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
                  icon: Icons.highlight_rounded,
                  label: 'Highlight',
                  color: const Color(0xFFFFB74D),
                  onTap: onHighlight,
                  scale: scale,
                ),
                _buildVerticalDivider(scale),
                _buildMenuButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI',
                  color: const Color(0xFFD97757),
                  onTap: onAi,
                  scale: scale,
                ),
                _buildVerticalDivider(scale),
                _buildMenuButton(
                  icon: Icons.note_add_rounded,
                  label: 'Note',
                  color: const Color(0xFF90CAF9),
                  onTap: onNote,
                  scale: scale,
                ),
                _buildVerticalDivider(scale),
                _buildMenuButton(
                  icon: Icons.close_rounded,
                  label: 'Close',
                  color: Colors.grey,
                  onTap: onClose,
                  scale: scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double scale,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (16 * scale).roundToDouble(),
          vertical: (10 * scale).roundToDouble(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: (24 * scale).roundToDouble()),
            SizedBox(height: (4 * scale).roundToDouble()),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: (11 * scale).clamp(9.0, 11.0),
                fontWeight: FontWeight.w500,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(double scale) {
    return Container(
      height: (36 * scale).roundToDouble(),
      width: 1,
      color:
          isDarkMode
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
    );
  }
}

import 'package:flutter/material.dart';

class PhysicalBookToolBar extends StatelessWidget {
  final VoidCallback onFocusMode;
  final VoidCallback? onScanQuote;
  final VoidCallback? onAskAi;
  final VoidCallback? onBookJournal;

  const PhysicalBookToolBar({
    super.key,
    required this.onFocusMode,
    this.onScanQuote,
    this.onAskAi,
    this.onBookJournal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ToolButton(
          icon: Icons.bedtime_rounded,
          label: 'Focus Mode',
          onTap: onFocusMode,
          filled: true,
        ),
        _ToolButton(
          icon: Icons.document_scanner_rounded,
          label: 'Scan Quote',
          onTap: onScanQuote ?? () {},
        ),
        _ToolButton(
          icon: Icons.psychology_rounded,
          label: 'Ask AI',
          onTap: onAskAi ?? () {},
        ),
        _ToolButton(
          icon: Icons.menu_book_rounded,
          label: 'Journal',
          onTap: onBookJournal ?? () {},
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    const activeColor = Color(0xFF8B4513);
    const iconColor = Color(0xFF3D2008);
    final buttonSize = (62 * scale).clamp(52.0, 62.0).roundToDouble();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: filled ? activeColor : const Color(0xFFE8D9B8),
              borderRadius: BorderRadius.circular(
                (18 * scale).clamp(14.0, 18.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: filled ? 0.22 : 0.10),
                  blurRadius: filled ? 14 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: (30 * scale).clamp(25.0, 30.0),
              color: filled ? Colors.white : iconColor,
            ),
          ),
          SizedBox(height: (7 * scale).clamp(5.0, 7.0)),
          Text(
            label,
            style: TextStyle(
              fontSize: (11 * scale).clamp(9.0, 11.0),
              fontWeight: FontWeight.w700,
              color: filled ? activeColor : iconColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ],
      ),
    );
  }
}

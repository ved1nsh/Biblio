import 'package:flutter/material.dart';

class StreakHeader extends StatelessWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final Color titleColor;

  const StreakHeader({
    super.key,
    required this.backgroundColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (32 * scale).clamp(26.0, 32.0);

    return Padding(
      padding: const EdgeInsets.only(top: 15.0), // Added top padding
      child: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Streaks & Stats',
          style: TextStyle(
            color: titleColor,
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ),
    );
  }

  @override
  // Increased height to account for padding
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 15);
}

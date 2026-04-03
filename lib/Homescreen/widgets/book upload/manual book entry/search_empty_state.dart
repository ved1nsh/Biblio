import 'package:flutter/material.dart';

class SearchEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SearchEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (80 * scale).roundToDouble(),
            color: Colors.black.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: (18 * scale).clamp(14.0, 18.0),
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: (14 * scale).clamp(11.0, 14.0),
              fontFamily: 'SF-UI-Display',
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

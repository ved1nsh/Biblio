import 'package:flutter/material.dart';

// Displays empty state UI when user has no books in their entire library
class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final textSize = (18 * scale).clamp(14.0, 18.0);
    final iconSize = (80 * scale).clamp(68.0, 80.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: iconSize,
            color: Colors.black.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No books in your library',
            style: TextStyle(
              fontSize: textSize,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first book',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'SF-UI-Display',
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

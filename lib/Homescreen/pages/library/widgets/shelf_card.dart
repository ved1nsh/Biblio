import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShelfCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final int bookCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ShelfCard({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.bookCount,
    required this.onTap,
    this.onLongPress,
  });

  /// Derives a shelf icon from the shelf name (matching homepage logic)
  static IconData getShelfIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('read') && lower.contains('to')) {
      return Icons.bookmark_outline;
    }
    if (lower.contains('top')) return Icons.emoji_events_outlined;
    if (lower.contains('own')) return Icons.menu_book_outlined;
    if (lower.contains('pdf') || lower.contains('library')) {
      return Icons.library_books_outlined;
    }
    if (lower.contains('fav')) return Icons.favorite_outline;
    return Icons.collections_bookmark_outlined;
  }

  /// Background colors matched with homepage BookshelvesWidget
  static const List<Color> bgColors = [
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFFFF3E0),
    Color(0xFFF3E5F5),
  ];

  static const List<Color> iconColors = [
    Color(0xFF2D5A3D),
    Color(0xFF1565C0),
    Color(0xFFD97A73),
    Color(0xFFD9A373),
    Color(0xFF9B8FD9),
  ];

  /// Convenience factory to build a ShelfCard from a shelf name + book count
  static ShelfCard fromShelfName({
    required String name,
    required int bookCount,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final colorIndex = name.hashCode.abs() % bgColors.length;
    return ShelfCard(
      title: name,
      icon: getShelfIcon(name),
      backgroundColor: bgColors[colorIndex],
      iconColor: iconColors[colorIndex],
      bookCount: bookCount,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final iconContainerSize = (44 * scale).clamp(38.0, 50.0);
    final iconSize = (22 * scale).clamp(18.0, 24.0);
    final nameSize = (15 * scale).clamp(13.0, 17.0);
    final countSize = (12 * scale).clamp(10.0, 13.0);
    final cardPadding = (16 * scale).clamp(12.0, 20.0);

    return GestureDetector(
      onTap: onTap,
      onLongPress:
          onLongPress != null
              ? () {
                HapticFeedback.heavyImpact();
                onLongPress!();
              }
              : null,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: nameSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF-UI-Display',
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
              style: TextStyle(
                fontSize: countSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'SF-UI-Display',
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

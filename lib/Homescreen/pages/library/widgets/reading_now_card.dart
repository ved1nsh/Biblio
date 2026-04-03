import 'package:flutter/material.dart';

class ReadingNowCard extends StatelessWidget {
  final int activeBookCount;
  final VoidCallback onTap;

  const ReadingNowCard({
    super.key,
    required this.activeBookCount,
    required this.onTap,
  });

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
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: const Color(0xFFD97A73).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: const Color(0xFFD97A73),
                size: iconSize,
              ),
            ),
            const Spacer(),
            Text(
              'Reading Now',
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
              '$activeBookCount ${activeBookCount == 1 ? 'book' : 'books'}',
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

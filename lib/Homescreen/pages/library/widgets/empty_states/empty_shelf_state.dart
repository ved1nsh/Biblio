import 'package:flutter/material.dart';

// Displays empty state UI when a specific shelf has no books, showing shelf name and description
class EmptyShelfState extends StatelessWidget {
  final String shelfName;
  final String? shelfDescription;
  final bool showShelfHeader;

  const EmptyShelfState({
    super.key,
    required this.shelfName,
    this.shelfDescription,
    this.showShelfHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final shelfNameSize = (24 * scale).clamp(18.0, 24.0);
    final textSize = (18 * scale).clamp(14.0, 18.0);
    final iconSize = (80 * scale).clamp(68.0, 80.0);
    final spacerHeight = (200 * scale).clamp(170.0, 200.0);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showShelfHeader) ...[
              Text(
                shelfName,
                style: TextStyle(
                  fontSize: shelfNameSize,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              if (shelfDescription != null && shelfDescription!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  shelfDescription!,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
            SizedBox(height: spacerHeight),

            // Empty state message in the center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: iconSize,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This shelf is empty',
                    style: TextStyle(
                      fontSize: textSize,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add books to "$shelfName" from your library',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF-UI-Display',
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

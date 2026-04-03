// UI-only header for the EPUB viewer (back button, chapter, title, author).

import 'package:flutter/material.dart';

class EpubViewerHeader extends StatelessWidget {
  final double height;
  final String chapterTitle;
  final String bookTitle;
  final String author;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onBack;
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;

  const EpubViewerHeader({
    super.key,
    required this.height,
    required this.chapterTitle,
    required this.bookTitle,
    required this.author,
    required this.textColor,
    required this.backgroundColor,
    required this.onBack,
    this.isFullScreen = false,
    this.onToggleFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final backIconSize = (28 * scale).clamp(24.0, 28.0);
    final fullscreenIconSize = (26 * scale).clamp(22.0, 26.0);
    final titleFontSize = (18 * scale).clamp(14.0, 18.0);
    final hPadding = (60 * scale).clamp(48.0, 60.0);

    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 8),
      decoration: BoxDecoration(color: backgroundColor),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: textColor,
                  size: backIconSize,
                ),
                onPressed: onBack,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          // Full-screen toggle button
          if (onToggleFullScreen != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    isFullScreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: textColor.withValues(alpha: 0.6),
                    size: fullscreenIconSize,
                  ),
                  onPressed: onToggleFullScreen,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chapterTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.6),
                      fontFamily: 'SF-UI-Display',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bookTitle,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF-UI-Display',
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by $author',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SF-UI-Display',
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

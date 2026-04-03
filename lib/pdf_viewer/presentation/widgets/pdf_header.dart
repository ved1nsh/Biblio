import 'package:flutter/material.dart';

class PdfHeader extends StatelessWidget {
  final String bookTitle;
  final String bookAuthor;
  final VoidCallback onBackPressed;
  final VoidCallback onFocusModeTap;
  final bool isDarkMode;

  const PdfHeader({
    super.key,
    required this.bookTitle,
    required this.bookAuthor,
    required this.onBackPressed,
    required this.onFocusModeTap,
    this.isDarkMode = false,
  });

  Color get _titleColor => isDarkMode ? Colors.white : Colors.black87;

  Color get _subtitleColor =>
      isDarkMode
          ? Colors.white.withOpacity(0.6)
          : Colors.black.withOpacity(0.6);

  Color get _iconColor => isDarkMode ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final containerHeight = (130 * scale).clamp(110.0, 130.0);
    final topPad = (50 * scale).clamp(42.0, 50.0);
    final hPad = (60 * scale).clamp(50.0, 60.0);
    final titleSize = (22 * scale).clamp(18.0, 22.0);
    final iconSize = (28 * scale).clamp(24.0, 28.0);

    return Container(
      height: containerHeight,
      padding: EdgeInsets.only(left: 16, right: 16, top: topPad, bottom: 8),
      child: Stack(
        children: [
          // Back button (left)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: _iconColor, size: iconSize),
                onPressed: onBackPressed,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),

          // Centered book info
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bookTitle,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF-UI-Display',
                      color: _titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by $bookAuthor',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SF-UI-Display',
                      color: _subtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Focus mode button (right)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_rounded,
                  color: _iconColor,
                  size: iconSize,
                ),
                onPressed: onFocusModeTap,
                padding: const EdgeInsets.all(12),
                tooltip: 'Focus Mode',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

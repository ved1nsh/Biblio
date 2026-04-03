import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuoteCard extends StatelessWidget {
  final String quoteId;
  final String quoteText;
  final String bookId;
  final String bookTitle;
  final String authorName;
  final DateTime createdAt;

  // Style props
  final String fontFamily;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final String textAlign;
  final double lineHeight;
  final double letterSpacing;
  final String backgroundColor;
  final String textColor;
  final bool showAuthor;
  final bool showBookTitle;
  final bool showUsername;

  final VoidCallback onDelete;
  final VoidCallback onTap;

  const QuoteCard({
    super.key,
    required this.quoteId,
    required this.quoteText,
    required this.bookId,
    required this.bookTitle,
    required this.authorName,
    required this.createdAt,
    required this.fontFamily,
    required this.fontSize,
    required this.isBold,
    required this.isItalic,
    required this.textAlign,
    required this.lineHeight,
    required this.letterSpacing,
    required this.backgroundColor,
    required this.textColor,
    required this.showAuthor,
    required this.showBookTitle,
    required this.showUsername,
    required this.onDelete,
    required this.onTap,
  });

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  TextAlign _alignFromString(String value) {
    switch (value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final cardMarginBottom = (16 * scale).clamp(12.0, 16.0);
    final cardPad = (18 * scale).clamp(14.0, 18.0);
    final watermarkSize = (11 * scale).clamp(9.0, 11.0);
    final metaGap = (12 * scale).clamp(10.0, 12.0);
    final dateSize = (10 * scale).clamp(8.0, 10.0);
    final quoteSize = (fontSize * scale).clamp(fontSize * 0.85, fontSize);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteDialog(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: cardMarginBottom),
        decoration: BoxDecoration(
          color: _hexToColor(backgroundColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 4,
              left: 14,
              child: Text(
                'biblio',
                style: TextStyle(
                  fontFamily: 'SF-UI-Display',
                  fontSize: watermarkSize,
                  color: _hexToColor(textColor).withOpacity(0.12),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quoteText,
                    textAlign: _alignFromString(textAlign),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: quoteSize,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                      height: lineHeight,
                      letterSpacing: letterSpacing,
                      color: _hexToColor(textColor),
                    ),
                  ),
                  SizedBox(height: metaGap),
                  if (showAuthor)
                    Text(
                      '- $authorName',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: quoteSize * 0.7,
                        color: _hexToColor(textColor).withOpacity(0.7),
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (showBookTitle)
                    Text(
                      bookTitle,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: quoteSize * 0.65,
                        color: _hexToColor(textColor).withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: dateSize,
                      color: _hexToColor(textColor).withOpacity(0.4),
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Quote'),
            content: const Text('Are you sure you want to delete this quote?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

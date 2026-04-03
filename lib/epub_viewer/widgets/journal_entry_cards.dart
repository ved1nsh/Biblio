// Widgets for rendering individual journal entry cards:
// HighlightCard, QuoteCard, and NoteCard used in the journal timeline view.

import 'package:flutter/material.dart';
import '../models/journal_entry.dart';

class HighlightCard extends StatelessWidget {
  final JournalEntry entry;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double scale;

  const HighlightCard({
    super.key,
    required this.entry,
    required this.textColor,
    required this.onTap,
    required this.onDelete,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD97757);
    final cardPad = (16 * scale).clamp(12.0, 16.0);
    final iconSize = (16 * scale).clamp(14.0, 16.0);
    final labelSize = (12 * scale).clamp(10.0, 12.0);
    final trailingIconSize = (18 * scale).clamp(16.0, 18.0);
    final topGap = (14 * scale).clamp(10.0, 14.0);
    final railMinHeight = (40 * scale).clamp(32.0, 40.0);
    final bodyFontSize = (15 * scale).clamp(13.0, 15.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.highlight_rounded, size: iconSize, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Highlighted Text',
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFamily: 'SF-UI-Display',
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: trailingIconSize,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.touch_app_rounded,
                  size: iconSize,
                  color: accent.withValues(alpha: 0.4),
                ),
              ],
            ),
            SizedBox(height: topGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  constraints: BoxConstraints(minHeight: railMinHeight),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.text,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      height: 1.55,
                      fontFamily: 'SF-UI-Display',
                      fontStyle: FontStyle.italic,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  final JournalEntry entry;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double scale;

  const QuoteCard({
    super.key,
    required this.entry,
    required this.textColor,
    required this.onTap,
    required this.onDelete,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6A8CAF);
    final cardPad = (16 * scale).clamp(12.0, 16.0);
    final iconSize = (16 * scale).clamp(14.0, 16.0);
    final labelSize = (12 * scale).clamp(10.0, 12.0);
    final trailingIconSize = (18 * scale).clamp(16.0, 18.0);
    final topGap = (14 * scale).clamp(10.0, 14.0);
    final railMinHeight = (40 * scale).clamp(32.0, 40.0);
    final bodyFontSize = (15 * scale).clamp(13.0, 15.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, size: iconSize, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Book Quote',
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFamily: 'SF-UI-Display',
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.more_horiz,
                    size: trailingIconSize,
                    color: textColor.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.touch_app_rounded,
                  size: iconSize,
                  color: accent.withValues(alpha: 0.4),
                ),
              ],
            ),
            SizedBox(height: topGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  constraints: BoxConstraints(minHeight: railMinHeight),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.text,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      height: 1.55,
                      fontFamily: 'SF-UI-Display',
                      fontStyle: FontStyle.italic,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final JournalEntry entry;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double scale;

  const NoteCard({
    super.key,
    required this.entry,
    required this.textColor,
    required this.onTap,
    required this.onDelete,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final cardPad = (16 * scale).clamp(12.0, 16.0);
    final iconSize = (15 * scale).clamp(13.0, 15.0);
    final labelSize = (12 * scale).clamp(10.0, 12.0);
    final trailingIconSize = (16 * scale).clamp(14.0, 16.0);
    final actionIconSize = (18 * scale).clamp(16.0, 18.0);
    final textGap = (12 * scale).clamp(10.0, 12.0);
    final bodyFontSize = (15 * scale).clamp(13.0, 15.0);
    final imageHeight = (120 * scale).clamp(96.0, 120.0);
    final fallbackHeight = (80 * scale).clamp(64.0, 80.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textColor.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: iconSize,
                  color: textColor.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 6),
                Text(
                  'Personal Note',
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF-UI-Display',
                    color: textColor.withValues(alpha: 0.55),
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.touch_app_rounded,
                  size: trailingIconSize,
                  color: textColor.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.more_horiz,
                    size: actionIconSize,
                    color: textColor.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
            SizedBox(height: textGap),
            Text(
              entry.text,
              style: TextStyle(
                fontSize: bodyFontSize,
                height: 1.55,
                fontFamily: 'SF-UI-Display',
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
            if (entry.imagePath != null && entry.imagePath!.isNotEmpty) ...[
              SizedBox(height: textGap),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  entry.imagePath!,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: fallbackHeight,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: textColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class TableOfContentsView extends StatelessWidget {
  final List<EpubChapter> chapters;
  final String? currentChapterTitle;
  final Color textColor;
  final Color dividerColor;
  final void Function(EpubChapter) onChapterTap;
  final double scale;

  const TableOfContentsView({
    super.key,
    required this.chapters,
    this.currentChapterTitle,
    required this.textColor,
    required this.dividerColor,
    required this.onChapterTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: (8 * scale).clamp(6.0, 8.0)),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isCurrent = chapter.title == currentChapterTitle;
        return _buildChapterItem(chapter, index, isCurrent);
      },
    );
  }

  Widget _buildEmptyState() {
    final iconSize = (64 * scale).clamp(50.0, 64.0).roundToDouble();
    final titleFontSize = (18 * scale).clamp(15.0, 18.0);
    final messageFontSize = (14 * scale).clamp(12.0, 14.0);
    final spacing1 = (16 * scale).clamp(12.0, 16.0);
    final spacing2 = (8 * scale).clamp(6.0, 8.0);
    final padding = (32 * scale).clamp(24.0, 32.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: iconSize,
              color: textColor.withValues(alpha: 0.2),
            ),
            SizedBox(height: spacing1),
            Text(
              'No chapter data available',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: spacing2),
            Text(
              'This EPUB doesn\'t contain\ntable of contents information',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: messageFontSize,
                fontFamily: 'SF-UI-Display',
                color: textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterItem(
    EpubChapter chapter,
    int index,
    bool isCurrentChapter,
  ) {
    final padH = (20 * scale).clamp(16.0, 20.0);
    final padV = (16 * scale).clamp(12.0, 16.0);
    final badgeSize = (36 * scale).roundToDouble().clamp(28.0, 36.0);
    final badgeRadius = (8 * scale).clamp(6.0, 8.0).roundToDouble();
    final badgeFontSize = (14 * scale).clamp(11.0, 14.0);
    final spacing = (16 * scale).clamp(12.0, 16.0);
    final titleFontSize = (16 * scale).clamp(13.0, 16.0);
    final subtitleSpacing = (4 * scale).clamp(3.0, 4.0);
    final subtitleFontSize = (13 * scale).clamp(11.0, 13.0);
    final badgePadH = (8 * scale).clamp(6.0, 8.0);
    final badgePadV = (4 * scale).clamp(3.0, 4.0);
    final badgeMarginLeft = (8 * scale).clamp(6.0, 8.0);
    final badgeLabelFontSize = (10 * scale).clamp(8.0, 10.0);
    final chevronSize = (20 * scale).clamp(16.0, 20.0).roundToDouble();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChapterTap(chapter),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color:
                isCurrentChapter
                    ? const Color(0xFFD97757).withValues(alpha: 0.1)
                    : Colors.transparent,
            border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color:
                      isCurrentChapter
                          ? const Color(0xFFD97757)
                          : const Color(0xFFD97757).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(badgeRadius),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF-UI-Display',
                      color:
                          isCurrentChapter
                              ? Colors.white
                              : const Color(0xFFD97757),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight:
                                  isCurrentChapter
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              fontFamily: 'SF-UI-Display',
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentChapter)
                          Container(
                            margin: EdgeInsets.only(left: badgeMarginLeft),
                            padding: EdgeInsets.symmetric(
                              horizontal: badgePadH,
                              vertical: badgePadV,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97757),
                              borderRadius: BorderRadius.circular(
                                (12 * scale).clamp(10.0, 12.0).roundToDouble(),
                              ),
                            ),
                            child: Text(
                              'You are here',
                              style: TextStyle(
                                fontSize: badgeLabelFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: subtitleSpacing),
                    Text(
                      'Chapter ${index + 1}',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontFamily: 'SF-UI-Display',
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textColor.withValues(alpha: 0.3),
                size: chevronSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

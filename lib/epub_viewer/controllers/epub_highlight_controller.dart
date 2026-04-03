import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../../core/services/highlights_service.dart';

class EpubHighlightController {
  final HighlightsService _highlightsService = HighlightsService();
  final Set<String> _renderedHighlights = {};

  HighlightsService get highlightsService => _highlightsService;

  Future<void> restoreHighlights({
    required String bookId,
    required EpubController epubController,
  }) async {
    try {
      // ✅ Guard: if highlights are already rendered, don't add them again
      if (_renderedHighlights.isNotEmpty) {
        debugPrint(
          '⚠️ Highlights already rendered (${_renderedHighlights.length}), skipping restore',
        );
        return;
      }

      // ✅ CLEAR existing highlights first to prevent stacking
      await _clearAllHighlights(epubController);
      _renderedHighlights.clear();

      final highlights = await _highlightsService.getHighlightsByBook(bookId);

      if (highlights.isEmpty) {
        debugPrint('📝 No highlights to restore');
        return;
      }

      debugPrint('📝 Restoring ${highlights.length} highlights...');

      for (final highlight in highlights) {
        final cfiRange = highlight['cfi_range'] as String?;
        final color = highlight['highlight_color'] as String? ?? '#FFB74D';

        if (cfiRange == null || cfiRange.isEmpty) continue;

        // Skip if already rendered (extra safety check)
        if (_renderedHighlights.contains(cfiRange)) {
          debugPrint('⚠️ Skipping duplicate highlight: $cfiRange');
          continue;
        }

        try {
          await epubController.webViewController?.evaluateJavascript(
            source: """
              try {
                rendition.annotations.add('highlight', '$cfiRange', {}, (e) => {
                  console.log('Restored highlight at $cfiRange');
                }, 'hl', {
                  'fill': '$color',
                  'fill-opacity': '0.3',
                  'mix-blend-mode': 'multiply'
                });
              } catch (e) {
                console.error('Failed to restore highlight:', e);
              }
            """,
          );

          _renderedHighlights.add(cfiRange);
        } catch (e) {
          debugPrint('⚠️ Failed to render highlight $cfiRange: $e');
        }
      }

      debugPrint('✅ Restored ${_renderedHighlights.length} highlights');
    } catch (e) {
      debugPrint('❌ Error restoring highlights: $e');
    }
  }

  // ✅ NEW METHOD: Clear all highlights from the rendition
  Future<void> _clearAllHighlights(EpubController epubController) async {
    try {
      await epubController.webViewController?.evaluateJavascript(
        source: """
          try {
            if (typeof rendition !== 'undefined' && rendition.annotations) {
              // Remove all existing highlight annotations
              rendition.annotations.remove(null, 'highlight');
              console.log('✅ Cleared all existing highlights');
            }
          } catch (e) {
            console.error('Failed to clear highlights:', e);
          }
        """,
      );
      debugPrint('🧹 Cleared all highlights from rendition');
    } catch (e) {
      debugPrint('⚠️ Failed to clear highlights: $e');
    }
  }

  Future<bool> saveHighlight({
    required String bookId,
    required String highlightedText,
    required String cfiRange,
    required EpubController epubController,
    String highlightColor = '#FFB74D',
  }) async {
    if (_renderedHighlights.contains(cfiRange)) {
      debugPrint('⚠️ Highlight already exists');
      return false;
    }

    // ✅ Extract the start CFI from the range
    final cfiStart = _extractCfiStart(cfiRange);

    final success = await _highlightsService.saveHighlight(
      bookId: bookId,
      highlightedText: highlightedText,
      cfiRange: cfiRange,
      cfiStart: cfiStart,
      highlightColor: highlightColor,
    );

    if (success) {
      _renderedHighlights.add(cfiRange);

      try {
        // ✅ FIXED: Use webViewController directly instead of addHighlight
        await epubController.webViewController?.evaluateJavascript(
          source: """
            try {
              rendition.annotations.add('highlight', '$cfiRange', {}, (e) => {
                console.log('Added highlight at $cfiRange');
              }, 'hl', {
                'fill': '$highlightColor',
                'fill-opacity': '0.3',
                'mix-blend-mode': 'multiply'
              });
            } catch (e) {
              console.error('Failed to add highlight:', e);
            }
          """,
        );
        debugPrint('✅ Highlight rendered in EPUB: $highlightedText');
      } catch (e) {
        debugPrint('⚠️ Failed to render highlight: $e');
      }
    }

    return success;
  }

  // ✅ Extract the start CFI from a range CFI
  String _extractCfiStart(String cfiRange) {
    try {
      final parts = cfiRange.split(',');

      if (parts.length >= 2) {
        final basePath = parts[0];
        final startOffset = parts[1];
        final cfiStart = '$basePath$startOffset)';

        debugPrint('📍 Extracted CFI Start: $cfiStart');
        return cfiStart;
      }

      debugPrint('⚠️ Could not extract CFI start, using full range');
      return cfiRange;
    } catch (e) {
      debugPrint('⚠️ CFI extraction error: $e');
      return cfiRange;
    }
  }

  void removeRenderedHighlight(String cfi) {
    _renderedHighlights.remove(cfi);
  }

  bool isHighlighted(String cfi) => _renderedHighlights.contains(cfi);

  void dispose() {
    _renderedHighlights.clear();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../widgets/return_to_current_button.dart';
import '../widgets/navigation_warning_banner.dart'; // ✅ NEW import

class EpubNavigationController {
  String? savedReadingCfi;
  OverlayEntry? _returnToCurrentOverlay;
  OverlayEntry? _warningBannerOverlay; // ✅ NEW

  /// Navigate to a specific CFI using the snapToHighlight function
  Future<bool> _snapToCfi(EpubController epubController, String cfi) async {
    try {
      // Sanitize the CFI for JavaScript
      final escapedCfi = cfi
          .replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'")
          .replaceAll('"', '\\"');

      // Call the injected snapToHighlight function
      final result = await epubController.webViewController?.evaluateJavascript(
        source: "window.snapToHighlight('$escapedCfi');",
      );

      debugPrint('🎯 snapToHighlight result: $result');
      return result == true || result == 'true';
    } catch (e) {
      debugPrint('❌ snapToCfi failed: $e');
      return false;
    }
  }

  /// Get the current exact CFI from the rendition
  Future<String?> _getCurrentCfi(EpubController epubController) async {
    try {
      final result = await epubController.webViewController?.evaluateJavascript(
        source: '''
          (function() {
            try {
              if (typeof rendition !== 'undefined') {
                var loc = rendition.currentLocation();
                if (loc && loc.start && loc.start.cfi) {
                  return loc.start.cfi;
                }
              }
            } catch(e) {
              console.error('Error getting current CFI:', e);
            }
            return null;
          })();
        ''',
      );

      if (result != null && result != 'null' && result.toString().isNotEmpty) {
        final cfi = result.toString().replaceAll('"', '').replaceAll("'", '');
        debugPrint('📍 Current CFI captured: $cfi');
        return cfi;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get current CFI: $e');
    }
    return null;
  }

  /// Navigate to a progress percentage
  void navigateToProgress({
    required double targetProgress,
    required double currentProgress,
    required String? lastTrackedCfi,
    required EpubController epubController,
    required BuildContext context,
  }) async {
    // Capture exact current position before navigating
    final exactCfi = await _getCurrentCfi(epubController);
    savedReadingCfi = exactCfi ?? lastTrackedCfi;

    debugPrint('💾 Saved reading CFI: $savedReadingCfi');
    debugPrint(
      '🎯 Navigating to progress: ${(targetProgress * 100).toStringAsFixed(1)}%',
    );

    // Navigate using percentage
    epubController.toProgressPercentage(targetProgress);

    // Show return button if we moved significantly
    final difference = (currentProgress - targetProgress).abs();
    if (difference > 0.02 && savedReadingCfi != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) {
          showReturnToCurrentButton(
            currentProgress: currentProgress,
            epubController: epubController,
            context: context,
          );
        }
      });
    }
  }

  /// Navigate to a specific CFI (highlight/note)
  void navigateToCfi({
    required String cfi,
    required String? lastTrackedCfi,
    required double currentProgress,
    required EpubController epubController,
    required BuildContext context,
  }) async {
    // Capture exact current position before navigating
    final exactCfi = await _getCurrentCfi(epubController);
    savedReadingCfi = exactCfi ?? lastTrackedCfi;

    debugPrint('💾 Saved reading CFI: $savedReadingCfi');
    debugPrint('🎯 Navigating to CFI: $cfi');

    // Use snapToHighlight for precise navigation
    final success = await _snapToCfi(epubController, cfi);

    if (!success) {
      debugPrint('⚠️ Snap failed, falling back to display()');
      epubController.display(cfi: cfi);
    }

    // Show warning banner + return button if we have a saved position
    if (savedReadingCfi != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          showNavigationWarning(context); // ✅ NEW
          showReturnToCurrentButton(
            currentProgress: currentProgress,
            epubController: epubController,
            context: context,
          );
        }
      });
    }
  }

  /// Show the warning banner about potential offset
  void showNavigationWarning(BuildContext context) {
    removeNavigationWarning();

    _warningBannerOverlay = OverlayEntry(
      builder:
          (ctx) => Positioned(
            top: 60, // Below the top app bar
            left: 20,
            right: 20,
            child: NavigationWarningBanner(onDismiss: removeNavigationWarning),
          ),
    );

    Overlay.of(context).insert(_warningBannerOverlay!);
    debugPrint('ℹ️ Navigation warning banner shown');
  }

  /// Remove the warning banner
  void removeNavigationWarning() {
    _warningBannerOverlay?.remove();
    _warningBannerOverlay = null;
  }

  /// Show the return-to-current-page button
  void showReturnToCurrentButton({
    required double currentProgress,
    required EpubController epubController,
    required BuildContext context,
  }) {
    removeReturnToCurrentButton();

    if (savedReadingCfi == null) {
      debugPrint('⚠️ No saved CFI - cannot show return button');
      return;
    }

    final page = _estimatePage(currentProgress);

    _returnToCurrentOverlay = OverlayEntry(
      builder:
          (ctx) => Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: ReturnToCurrentButton(
              currentPage: page,
              onTap: () async {
                if (savedReadingCfi != null) {
                  debugPrint('🔙 Returning to saved CFI: $savedReadingCfi');

                  // Use snapToHighlight for precise return navigation
                  final success = await _snapToCfi(
                    epubController,
                    savedReadingCfi!,
                  );

                  if (!success) {
                    debugPrint(
                      '⚠️ Snap return failed, falling back to display()',
                    );
                    epubController.display(cfi: savedReadingCfi!);
                  }
                }
                removeReturnToCurrentButton();
                removeNavigationWarning(); // ✅ Also remove warning when returning
              },
              onDismiss: () {
                removeReturnToCurrentButton();
                removeNavigationWarning(); // ✅ Also remove warning when dismissing
              },
            ),
          ),
    );

    Overlay.of(context).insert(_returnToCurrentOverlay!);
    debugPrint('✅ Return button shown - saved CFI: $savedReadingCfi');
  }

  /// Remove the return button overlay
  void removeReturnToCurrentButton() {
    _returnToCurrentOverlay?.remove();
    _returnToCurrentOverlay = null;
  }

  /// Estimate page number from progress (for UI display)
  int _estimatePage(double progress) {
    const estimatedTotalPages = 300;
    return (progress * estimatedTotalPages).round().clamp(
      1,
      estimatedTotalPages,
    );
  }

  /// Clean up resources
  void dispose() {
    removeReturnToCurrentButton();
    removeNavigationWarning(); // ✅ NEW cleanup
  }
}

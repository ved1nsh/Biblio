// UI-only reader stack: renders EpubViewer and optional loader overlay.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class EpubViewerReader extends StatelessWidget {
  final String filePath;
  final EpubController epubController;
  final EpubDisplaySettings displaySettings;
  final bool isRestoringPosition;
  final Color loaderColor;
  final Color backgroundColor;

  final VoidCallback onEpubLoaded;
  final ValueChanged<List<EpubChapter>> onChaptersLoaded;
  final ValueChanged<EpubLocation> onRelocated;
  final void Function(
    String selectedText,
    String? contextText,
    String cfiRange,
  )?
  onTextSelected;

  const EpubViewerReader({
    super.key,
    required this.filePath,
    required this.epubController,
    required this.displaySettings,
    required this.isRestoringPosition,
    required this.loaderColor,
    required this.backgroundColor,
    required this.onEpubLoaded,
    required this.onChaptersLoaded,
    required this.onRelocated,
    this.onTextSelected,
  });

  EpubSource _resolveSource(String path) {
    final uri = Uri.tryParse(path);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return EpubSource.fromUrl(path);
    }

    if (uri != null && uri.scheme == 'file') {
      return EpubSource.fromFile(File.fromUri(uri));
    }

    return EpubSource.fromFile(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final source = _resolveSource(filePath);

    return Stack(
      fit: StackFit.expand,
      children: [
        EpubViewer(
          key: ValueKey(filePath),
          epubController: epubController,
          epubSource: source,
          displaySettings: displaySettings,
          suppressNativeContextMenu: true,
          onEpubLoaded: onEpubLoaded,
          onChaptersLoaded: onChaptersLoaded,
          onRelocated: onRelocated,
          onTextSelected: (selection) {
            if (onTextSelected == null) return;
            onTextSelected!(
              selection.selectedText,
              null, // contextText not available in your fork
              selection.selectionCfi,
            );
          },
        ),
        // Animated loader overlay - fades out smoothly when ready
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isRestoringPosition,
            child: AnimatedOpacity(
              opacity: isRestoringPosition ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: Container(
                color: backgroundColor,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: (30 * scale).clamp(24.0, 30.0)),
                    Text(
                      isRestoringPosition
                          ? 'Adjusting layout...'
                          : 'Loading your book...',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        color: Colors.white,
                        fontSize: (16 * scale).clamp(14.0, 16.0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

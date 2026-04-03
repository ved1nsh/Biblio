import 'package:flutter/material.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/epub_viewer/controllers/epub_theme_controller.dart';
import 'package:biblio/epub_viewer/quote_dialog/save_quote_dialog.dart';
import 'scan_quote_camera_screen.dart';
import 'scan_quote_choice_dialog.dart';
import 'scan_quote_edit_screen.dart';
import 'ocr_service.dart';
import 'image_quote_service.dart';

/// Orchestrates the full "Scan Quote" workflow:
///   1. Open camera → capture image
///   2. Show choice dialog → Save as Image or Save as Text
///   3a. Image path → upload to Supabase Storage
///   3b. OCR → editable text → SaveQuoteDialog
class ScanQuoteCoordinator {
  /// Launches the complete scan quote flow.
  /// Call this from the physical book session toolbar.
  static Future<void> launch(BuildContext context, Book book) async {
    // 1) Open camera and get the captured image path
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ScanQuoteCameraScreen(),
      ),
    );

    if (imagePath == null || !context.mounted) return;

    // 2) Show choice dialog
    final choice = await showDialog<ScanQuoteChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScanQuoteChoiceDialog(imagePath: imagePath),
    );

    if (choice == null || !context.mounted) return;

    switch (choice) {
      case ScanQuoteChoice.saveAsImage:
        await _handleSaveAsImage(context, imagePath, book);
        break;
      case ScanQuoteChoice.saveAsText:
        await _handleSaveAsText(context, imagePath, book);
        break;
    }
  }

  /// Upload the image to Supabase Storage and save a reference
  static Future<void> _handleSaveAsImage(
    BuildContext context,
    String imagePath,
    Book book,
  ) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: Card(
              color: Color(0xFFFCF9F5),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD97A73)),
                    SizedBox(height: 16),
                    Text(
                      'Saving image...',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    final service = ImageQuoteService();
    final success = await service.saveImageQuote(
      imagePath: imagePath,
      bookId: book.id,
      bookTitle: book.title,
      authorName: book.author,
      bookCoverUrl: book.coverUrl,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Quote image saved to notebook! 📸'
              : 'Failed to save image. Please try again.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Run OCR on the image and open SaveQuoteDialog with pre-filled text
  static Future<void> _handleSaveAsText(
    BuildContext context,
    String imagePath,
    Book book,
  ) async {
    // Show a loading indicator while OCR runs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: Card(
              color: Color(0xFFFCF9F5),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD97A73)),
                    SizedBox(height: 16),
                    Text(
                      'Extracting text...',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    final recognizedText = await OcrService.recognizeText(imagePath);

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    if (recognizedText == null || recognizedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No text found in the image. Try again with better lighting.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Let user edit the OCR result before styling
    if (!context.mounted) return;
    final editedText = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (_) => ScanQuoteEditScreen(
              ocrText: recognizedText,
              imagePath: imagePath,
            ),
      ),
    );

    if (editedText == null || editedText.trim().isEmpty || !context.mounted) {
      return;
    }

    // Open the SaveQuoteDialog with the edited text
    final themeController = EpubThemeController();

    if (!context.mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => SaveQuoteDialog(
              quoteText: editedText,
              bookTitle: book.title,
              authorName: book.author,
              bookId: book.id,
              bookCoverUrl: book.coverUrl,
              themeController: themeController,
              onSave: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quote saved to notebook! ✨'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

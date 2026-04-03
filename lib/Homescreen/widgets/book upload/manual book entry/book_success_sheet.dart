import 'package:biblio/Homescreen/pages/library/shelf%20widgets/add_to_shelf.dart';
import 'package:biblio/manual_reading/manual_reading_page.dart';
import 'package:biblio/pdf_viewer/presentation/pdf_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/book_model.dart';

class BookSuccessSheet extends ConsumerWidget {
  final Book book;

  const BookSuccessSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(scale),
          SizedBox(height: (24 * scale).clamp(16.0, 24.0)),
          _buildSuccessIcon(scale),
          const SizedBox(height: 16),
          _buildTitle(scale),
          const SizedBox(height: 8),
          _buildSubtitle(scale),
          SizedBox(height: (32 * scale).clamp(20.0, 32.0)),
          _buildStartReadingButton(context),
          const SizedBox(height: 12),
          _buildAddToShelfButton(context),
          const SizedBox(height: 12),
          _buildDoneButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDragHandle(double scale) {
    return Container(
      width: (40 * scale).roundToDouble(),
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSuccessIcon(double scale) {
    final iconSize = (60 * scale).roundToDouble();
    final checkSize = (32 * scale).roundToDouble();
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle, color: Colors.green, size: checkSize),
    );
  }

  Widget _buildTitle(double scale) {
    final titleSize = (22 * scale).clamp(18.0, 22.0);
    return Text(
      'Book Added Successfully!',
      style: TextStyle(
        fontSize: titleSize,
        fontFamily: 'SF-UI-Display',
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubtitle(double scale) {
    final subtitleSize = (15 * scale).clamp(12.0, 15.0);
    return Text(
      'What would you like to do next?',
      style: TextStyle(
        fontSize: subtitleSize,
        fontFamily: 'SF-UI-Display',
        fontWeight: FontWeight.w400,
        color: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildStartReadingButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          if (book.isManualEntry || book.filePath == null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManualReadingPage(book: book),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerPage(book: book),
              ),
            );
          }
        },
        icon: const Icon(Icons.auto_stories_rounded),
        label: const Text(
          'Start Reading',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'SF-UI-Display',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAddToShelfButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.black, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Close success sheet first
          Navigator.pop(context);

          // Show add to shelf dialog
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder:
                (context) =>
                    AddToShelfDialog(bookId: book.id, bookTitle: book.title),
          );
        },
        icon: const Icon(Icons.collections_bookmark, color: Colors.black),
        label: const Text(
          'Add to Shelf...',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'SF-UI-Display',
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'SF-UI-Display',
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

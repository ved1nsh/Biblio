import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/providers/shelf_provider.dart';

class SelectionActions {
  static Future<void> deleteSelectedBooks(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedBookIds,
    VoidCallback onComplete,
  ) async {
    if (selectedBookIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Books?',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to delete ${selectedBookIds.length} ${selectedBookIds.length == 1 ? 'book' : 'books'} from your library? This action cannot be undone.',
              style: const TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF9F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD97A73),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Deleting ${selectedBookIds.length} ${selectedBookIds.length == 1 ? 'book' : 'books'}...',
                      style: const TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final bookService = ref.read(bookServiceProvider);

      // Delete all books in parallel for better performance
      await Future.wait(
        selectedBookIds.map((id) => bookService.deleteBookEverywhere(id)),
      );

      // Invalidate providers to refresh UI
      ref.invalidate(allBooksProvider);
      ref.invalidate(allShelvesProvider);

      // Clear currently reading if any selected book was being read
      final currentBook = ref.read(currentlyReadingProvider);
      if (currentBook != null && selectedBookIds.contains(currentBook.id)) {
        ref.read(currentlyReadingProvider.notifier).clearBook();
      }

      onComplete();

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedBookIds.length} ${selectedBookIds.length == 1 ? 'book' : 'books'} deleted from library',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting books: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<void> removeSelectedBooksFromShelf(
    BuildContext context,
    WidgetRef ref,
    String shelfName,
    Set<String> selectedBookIds,
    VoidCallback onComplete,
  ) async {
    if (selectedBookIds.isEmpty) return;

    // Find the shelf object
    final shelvesAsync = await ref.read(allShelvesProvider.future);
    final shelf = shelvesAsync.firstWhere(
      (s) => s.name == shelfName,
      orElse: () => throw Exception('Shelf not found'),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Remove from Shelf?',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Remove ${selectedBookIds.length} ${selectedBookIds.length == 1 ? 'book' : 'books'} from "$shelfName"? ${selectedBookIds.length == 1 ? 'It' : 'They'} will remain in your library.',
              style: const TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF9F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD97A73),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Removing ${selectedBookIds.length} ${selectedBookIds.length == 1 ? 'book' : 'books'}...',
                      style: const TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final shelfService = ref.read(shelfServiceProvider);

      // Remove all books in parallel
      await Future.wait(
        selectedBookIds.map(
          (bookId) => shelfService.removeBookFromShelf(
            bookId: bookId,
            shelfId: shelf.id,
          ),
        ),
      );

      // Invalidate providers
      ref.invalidate(allShelvesProvider);
      ref.invalidate(booksInShelfProvider(shelf.id));

      onComplete();

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedBookIds.length} ${selectedBookIds.length == 1 ? 'book' : 'books'} removed from "$shelfName"',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing books: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

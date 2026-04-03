import 'package:biblio/Homescreen/pages/library/shelf%20widgets/add_to_shelf.dart';
import 'package:biblio/Homescreen/pages/library/widgets/book_journal_page.dart';
import 'package:biblio/manual_reading/manual_reading_page.dart';
import 'package:biblio/pdf_viewer/presentation/pdf_viewer_page.dart';
import 'package:biblio/epub_viewer/epub_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/providers/shelf_provider.dart';

class BookDetailsSheet extends ConsumerStatefulWidget {
  final Book book;
  final String currentShelf;

  const BookDetailsSheet({
    super.key,
    required this.book,
    this.currentShelf = 'All Books',
  });

  @override
  ConsumerState<BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends ConsumerState<BookDetailsSheet> {
  @override
  void initState() {
    super.initState();

    // Force refetch shelves info every time the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(shelvesForBookProvider(widget.book.id));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getReadingStatus() {
    if (!widget.book.isStartedReading) return 'Not Started';
    if (widget.book.currentPage >= widget.book.totalPages) return 'Finished';
    return 'Reading';
  }

  Color _getStatusColor() {
    if (!widget.book.isStartedReading) return Colors.grey;
    if (widget.book.currentPage >= widget.book.totalPages) {
      return Colors.green;
    }
    return const Color(0xFFD97A73);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final padAll = (24 * scale).clamp(18.0, 24.0);

    final status = _getReadingStatus();
    final statusColor = _getStatusColor();
    final fileType =
        widget.book.filePath?.toLowerCase().endsWith('.epub') ?? false
            ? 'EPUB'
            : widget.book.isManualEntry
            ? 'Manual'
            : 'PDF';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: (20 * scale).clamp(16.0, 20.0),
        vertical: 40,
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.all(padAll),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCloseButton(),
              const SizedBox(height: 8),
              _buildBookCover(),
              const SizedBox(height: 20),
              _buildBookTitle(),
              const SizedBox(height: 8),
              _buildAuthorName(),
              const SizedBox(height: 16),
              _buildShelvesInfo(),
              const SizedBox(height: 16),
              _buildStatusPanel(status, statusColor, fileType),
              const SizedBox(height: 20),
              _buildJournalButton(),
              const SizedBox(height: 20),
              _buildNavigationPanel(),
              const SizedBox(height: 16),
              _buildStartReadingButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: const Icon(Icons.close, size: 24),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildBookCover() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final coverWidth = (145 * scale).clamp(120.0, 145.0);
    final coverHeight = coverWidth * 1.38;

    return Container(
      height: coverHeight,
      width: coverWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
                ? Image.network(
                  widget.book.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: const Color(0xFFD97A73).withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(
                            Icons.menu_book,
                            color: Color(0xFFD97A73),
                            size: 64,
                          ),
                        ),
                      ),
                )
                : Container(
                  color: const Color(0xFFD97A73).withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book,
                      color: Color(0xFFD97A73),
                      size: 64,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildBookTitle() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (22 * scale).clamp(18.0, 22.0);

    return Text(
      widget.book.title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: titleSize,
        fontFamily: 'SF-UI-Display',
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAuthorName() {
    return Text(
      widget.book.author,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        fontFamily: 'SF-UI-Display',
        fontWeight: FontWeight.w400,
        color: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildShelvesInfo() {
    // Use a Consumer to ensure this widget rebuilds when shelves change
    return Consumer(
      builder: (context, ref, _) {
        final shelvesAsync = ref.watch(shelvesForBookProvider(widget.book.id));
        return shelvesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (shelves) {
            if (shelves.isEmpty) {
              return Text(
                'Not in any shelf',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              );
            }

            final shelfNames = shelves.map((s) => s.name).join(', ');
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.collections_bookmark,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'In: $shelfNames',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusPanel(String status, Color statusColor, String fileType) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            icon: Icons.circle_outlined,
            color: statusColor,
            value: status,
            label: 'Status',
          ),
          _buildDivider(),
          _buildStatusItem(
            icon: Icons.menu_book,
            color: Colors.brown.shade400,
            value: '${widget.book.totalPages}',
            label: 'Pages',
          ),
          _buildDivider(),
          _buildStatusItem(
            icon: Icons.description,
            color: Colors.orange.shade700,
            value: fileType,
            label: 'File',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildJournalButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: const Color(0xFFD97757).withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookJournalPage(book: widget.book),
            ),
          );
        },
        icon: const Icon(
          Icons.auto_stories_rounded,
          color: Color(0xFFD97757),
          size: 20,
        ),
        label: const Text(
          'Book Journal',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'SF-UI-Display',
            fontWeight: FontWeight.w600,
            color: Color(0xFFD97757),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationPanel() {
    final isOnAllBooks = widget.currentShelf == 'All Books';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: Colors.red.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                isOnAllBooks
                    ? _showDeleteConfirmation
                    : _showRemoveFromShelfConfirmation,
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.shade700,
              size: 18,
            ),
            label: Text(
              isOnAllBooks ? 'Remove\nfrom library' : 'Remove\nfrom shelf',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder:
                    (context) => AddToShelfDialog(
                      bookId: widget.book.id,
                      bookTitle: widget.book.title,
                    ),
              );
            },
            icon: Icon(
              Icons.collections_bookmark_outlined,
              color: Colors.brown.shade700,
              size: 18,
            ),
            label: Text(
              'Add to\nshelf',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartReadingButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFD97A73),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          debugPrint('📚 Start Reading button pressed');
          debugPrint('📚 Book: ${widget.book.title}');
          debugPrint('📚 File path: ${widget.book.filePath}');
          debugPrint('📚 Is manual: ${widget.book.isManualEntry}');

          // Get references BEFORE closing the dialog
          final bookService = ref.read(bookServiceProvider);
          final currentlyReadingNotifier = ref.read(
            currentlyReadingProvider.notifier,
          );

          // Handle manual entry books
          if (widget.book.isManualEntry || widget.book.filePath == null) {
            debugPrint('📚 Opening manual reading page');
            Navigator.pop(context); // Close sheet
            if (!context.mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManualReadingPage(book: widget.book),
              ),
            );
            return;
          }

          // Mark as started if not already
          if (!widget.book.isStartedReading) {
            debugPrint('📚 Marking book as started');
            await bookService.updateBook(
              bookId: widget.book.id,
              isStartedReading: true,
            );
            ref.invalidate(allBooksProvider);
          }

          final updatedBook = widget.book.copyWith(isStartedReading: true);
          currentlyReadingNotifier.setBook(updatedBook);

          // Close the sheet AFTER all ref operations
          if (!context.mounted) return;
          Navigator.pop(context);
          if (!context.mounted) return;

          // Check file type and navigate accordingly
          final filePath = widget.book.filePath!.toLowerCase();
          debugPrint('📚 File path (lowercase): $filePath');

          if (filePath.endsWith('.epub')) {
            debugPrint('📚 Opening EPUB viewer');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EpubViewerPage(book: widget.book),
              ),
            );
          } else {
            debugPrint('📚 Opening PDF viewer');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerPage(book: widget.book),
              ),
            );
          }
        },
        child: Text(
          widget.book.isManualEntry || widget.book.filePath == null
              ? 'Start Reading'
              : widget.book.isStartedReading
              ? 'Continue Reading'
              : 'Start Reading',
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'SF-UI-Display',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Remove Book?',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to remove "${widget.book.title}" from your library? This action cannot be undone.',
              style: const TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: () async {
                  final bookService = ref.read(bookServiceProvider);
                  await bookService.deleteBookEverywhere(widget.book.id);

                  ref.invalidate(allBooksProvider);

                  final shelvesAsync = await ref.read(
                    shelvesForBookProvider(widget.book.id).future,
                  );
                  for (final shelf in shelvesAsync) {
                    ref.invalidate(booksInShelfProvider(shelf.id));
                  }

                  final currentBook = ref.read(currentlyReadingProvider);
                  if (currentBook?.id == widget.book.id) {
                    ref.read(currentlyReadingProvider.notifier).clearBook();
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.book.title} removed from library',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.black87,
                    ),
                  );
                },
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
  }

  void _showRemoveFromShelfConfirmation() async {
    final shelvesAsync = ref.read(allShelvesProvider);
    Shelf? currentShelfObj;

    await shelvesAsync.whenData((shelves) {
      try {
        currentShelfObj = shelves.firstWhere(
          (shelf) => shelf.name == widget.currentShelf,
        );
      } catch (e) {
        currentShelfObj = null;
      }
    });

    if (currentShelfObj == null || !context.mounted) return;

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
              'Remove "${widget.book.title}" from "${widget.currentShelf}"? The book will remain in your library.',
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

    if (confirmed == true && currentShelfObj != null) {
      final shelfService = ref.read(shelfServiceProvider);
      await shelfService.removeBookFromShelf(
        bookId: widget.book.id,
        shelfId: currentShelfObj!.id,
      );

      ref.invalidate(allShelvesProvider);
      ref.invalidate(booksInShelfProvider(currentShelfObj!.id));

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.book.title} removed from ${widget.currentShelf}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }
}

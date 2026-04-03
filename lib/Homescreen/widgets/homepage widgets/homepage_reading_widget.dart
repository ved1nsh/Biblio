import 'dart:ui' as ui;
import 'dart:io';

import 'package:biblio/Homescreen/widgets/book upload/add_book_options_dialog.dart';
import 'package:biblio/Homescreen/widgets/book upload/confirm_book_details_dialog.dart';
import 'package:biblio/Homescreen/widgets/book upload/manual book entry/manual_book_entry_dialog.dart';
import 'package:biblio/manual_reading/manual_reading_page.dart';
import 'package:biblio/pdf_viewer/presentation/pdf_viewer_page.dart';
import 'package:biblio/epub_viewer/epub_viewer_page.dart';
import 'package:epubx/epubx.dart' hide Image;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/models/book_model.dart';

class HomepageReadingWidget extends ConsumerStatefulWidget {
  const HomepageReadingWidget({super.key});

  @override
  ConsumerState<HomepageReadingWidget> createState() =>
      _HomepageReadingWidgetState();
}

class _HomepageReadingWidgetState extends ConsumerState<HomepageReadingWidget> {
  int _currentPage = 0;

  List<Book> _getActiveBooks(List<Book> books) {
    final activeBooks =
        books
            .where(
              (book) =>
                  book.isStartedReading &&
                  (book.currentPage < book.totalPages || book.totalPages == 0),
            )
            .toList();

    activeBooks.sort((a, b) {
      final aDate = a.lastReadAt ?? a.updatedAt;
      final bDate = b.lastReadAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return activeBooks.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allBooksAsync = ref.watch(allBooksProvider);

    return allBooksAsync.when(
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (books) {
        final activeBooks = _getActiveBooks(books);

        if (activeBooks.isEmpty) {
          return _EmptyState(onAddBook: _showAddBookOptions);
        }

        if (activeBooks.length == 1) {
          return _ReadingCard(
            book: activeBooks[0],
            onContinue: () => _navigateToReader(context, ref, activeBooks[0]),
            onRemove:
                () => _showRemoveConfirmation(context, ref, activeBooks[0]),
          );
        }

        final currentIndex = _currentPage.clamp(0, activeBooks.length - 1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200 &&
                    _currentPage < activeBooks.length - 1) {
                  setState(() => _currentPage++);
                } else if (details.primaryVelocity! > 200 && _currentPage > 0) {
                  setState(() => _currentPage--);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _ReadingCard(
                  key: ValueKey(activeBooks[currentIndex].id),
                  book: activeBooks[currentIndex],
                  onContinue:
                      () => _navigateToReader(
                        context,
                        ref,
                        activeBooks[currentIndex],
                      ),
                  onRemove:
                      () => _showRemoveConfirmation(
                        context,
                        ref,
                        activeBooks[currentIndex],
                      ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _DotIndicator(count: activeBooks.length, currentPage: currentIndex),
          ],
        );
      },
    );
  }

  void _navigateToReader(BuildContext context, WidgetRef ref, Book book) {
    ref.read(currentlyReadingProvider.notifier).setBook(book);

    if (book.isManualEntry || book.filePath == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ManualReadingPage(book: book)),
      );
      return;
    }

    final filePath = book.filePath!.toLowerCase();

    if (filePath.endsWith('.epub')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EpubViewerPage(book: book)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PdfViewerPage(book: book)),
      );
    }
  }

  void _showRemoveConfirmation(BuildContext context, WidgetRef ref, Book book) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Remove from Currently Reading?',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            content: Text(
              'This will remove "${book.title}" from your currently reading list. '
              'The book will remain in your library.',
              style: const TextStyle(fontFamily: 'SF-UI-Display', fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97A73),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final bookService = ref.read(bookServiceProvider);
                  await bookService.updateBook(
                    bookId: book.id,
                    isStartedReading: false,
                  );
                  ref.invalidate(allBooksProvider);
                  ref.read(currentlyReadingProvider.notifier).clearBook();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${book.title} removed from currently reading',
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
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddBookOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
      builder:
          (context) => AddBookOptionsDialog(
            onImportFile: _handleImportFile,
            onAddManually: _handleAddManually,
          ),
    );
  }

  Future<void> _handleImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final extension = path.split('.').last.toLowerCase();

    if (extension == 'pdf') {
      await _handlePdfImport(path);
    } else if (extension == 'epub') {
      await _handleEpubImport(path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unsupported file type')));
      }
    }
  }

  Future<void> _handlePdfImport(String path) async {
    try {
      final file = File(path);
      final document = PdfDocument(inputBytes: file.readAsBytesSync());

      String title = document.documentInformation.title ?? 'Untitled Book';
      String author = document.documentInformation.author ?? 'Unknown Author';
      final totalPages = document.pages.count;

      document.dispose();

      ref.invalidate(allBooksProvider);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => ConfirmBookDetailsDialog(
              filePath: path,
              initialTitle: title,
              initialAuthor: author,
              totalPages: totalPages,
              fileType: 'pdf',
            ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read PDF metadata.')),
        );
      }
    }
  }

  Future<void> _handleEpubImport(String path) async {
    String title = 'Untitled Book';
    String author = 'Unknown Author';

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      if (epubBook.Title != null && epubBook.Title!.isNotEmpty) {
        title = epubBook.Title!;
      }

      if (epubBook.Author != null && epubBook.Author!.isNotEmpty) {
        author = epubBook.Author!;
      }
    } catch (e) {
      debugPrint('Error reading EPUB metadata: $e');
    }

    ref.invalidate(allBooksProvider);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ConfirmBookDetailsDialog(
            filePath: path,
            initialTitle: title,
            initialAuthor: author,
            totalPages: 0,
            fileType: 'epub',
          ),
    );
  }

  void _handleAddManually() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManualBookEntryDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reading Card — new centered layout
//
// Layout:
//   [         Book Cover (centered)        ]
//   [         Bookmark icon overlay         ]
//   [         Title (centered)              ]
//   [         by Author (centered)          ]
//   [ Chapter name              Progress % ]
//   [ ████████████░░░░░░░░░░░░░░░░░░░░░░░░ ]
//   [ Page X of Y             Xh Xm left   ]
//   [ ▶ Continue Reading                   ]
// ─────────────────────────────────────────────────────────────────────────────

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    super.key,
    required this.book,
    required this.onContinue,
    required this.onRemove,
  });

  final Book book;
  final VoidCallback onContinue;
  final VoidCallback onRemove;

  double get _progress =>
      book.totalPages > 0
          ? book.currentPage / book.totalPages
          : (book.progressPercent != null ? book.progressPercent! / 100 : 0.0);

  String get _timeLeftText {
    if (book.totalReadSeconds == null ||
        book.totalReadSeconds == 0 ||
        _progress <= 0) {
      return '';
    }
    final totalEstimatedSeconds = (book.totalReadSeconds! / _progress).round();
    final remainingSeconds = totalEstimatedSeconds - book.totalReadSeconds!;
    if (remainingSeconds <= 0) return '';

    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    }
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (_progress * 100).toInt();
    final screenWidth = MediaQuery.of(context).size.width;
    final coverWidth = (screenWidth * 0.38).clamp(130.0, 180.0);
    final coverHeight = coverWidth * 1.45;
    final closeButtonTop = (14.0).clamp(14.0, 14.0);
    final closeButtonRight = (14.0).clamp(14.0, 14.0);
    final closeButtonSize = (28.0).clamp(28.0, 28.0);

    final hasCover = book.coverUrl != null && book.coverUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Blurred cover background ──
            Positioned.fill(
              child:
                  hasCover
                      ? ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 40,
                          sigmaY: 40,
                        ),
                        child: Transform.scale(
                          scale: 1.4,
                          child: Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFF333333)),
                          ),
                        ),
                      )
                      : const ColoredBox(color: Color(0xFF333333)),
            ),
            // ── Dark scrim for readability ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.62),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: closeButtonTop,
              right: closeButtonRight,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: closeButtonSize,
                  height: closeButtonSize,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // ── Card content ──
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                // ── Book cover ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: coverWidth,
                    height: coverHeight,
                    child: _CoverImage(book: book),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Title ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Bookerly',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFfF2F2F2),
                      height: 1.25,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Author ──
                Text(
                  'by ${book.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFfF2F2F2).withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Progress label + percentage ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        book.totalPages > 0
                            ? 'Page ${book.currentPage} of ${book.totalPages}'
                            : 'Progress',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF2F2F2).withValues(alpha: 0.7),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'SF-UI-Display',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF2F2F2),
                            ),
                          ),
                          if (_timeLeftText.isNotEmpty) ...[
                            // Text(
                            //   '  ·  ',
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     fontFamily: 'SF-UI-Display',
                            //     color: Color(0xFFF2F2F2).withValues(alpha: 0.7),
                            //   ),
                            // ),
                            // Icon(
                            //   Icons.access_time_rounded,
                            //   size: 12,
                            //   color: Colors.black.withValues(alpha: 0.4),
                            // ),
                            // const SizedBox(width: 3),
                            // Text(
                            //   _timeLeftText,
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     fontFamily: 'SF-UI-Display',
                            //     fontWeight: FontWeight.w400,
                            //     color: Colors.black.withValues(alpha: 0.4),
                            //   ),
                            // ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Progress bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.9),
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Continue Reading button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf2f2f2),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Continue Reading',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'SF-UI-Display',
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ], // Column children
            ), // Column (content)
          ], // Stack children
        ), // Stack
      ), // ClipRRect
    ); // Container
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot indicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.currentPage});

  final int count;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color(0xFF1A1A1A)
                    : Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddBook});

  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 40,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No books in progress',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start reading by selecting a book from your library',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAddBook,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Colors.black.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add a Book',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover image
// ─────────────────────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    if (book.coverUrl != null) {
      return Image.network(
        book.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CoverFallback(book: book),
      );
    }
    return Container(color: Colors.black87, child: _CoverFallback(book: book));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover fallback (title initials)
// ─────────────────────────────────────────────────────────────────────────────

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        book.title
            .split(' ')
            .take(3)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontFamily: 'SF-UI-Display',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

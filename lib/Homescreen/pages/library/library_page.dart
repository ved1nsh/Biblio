import 'dart:math' as math;

import 'package:biblio/Homescreen/pages/library/shelf%20widgets/create_shelf_dialog.dart';
import 'package:biblio/Homescreen/pages/library/shelf%20widgets/edit_shelf_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/providers/shelf_provider.dart';
import 'widgets/library_header.dart';
import 'widgets/library_search_bar.dart';
import 'widgets/shelf_card.dart';
import 'widgets/reading_now_card.dart';
import 'widgets/book_card.dart';
import 'shelf_detail_page.dart';
import 'actions/shelf_actions.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  bool _isEditMode = false;
  List<Shelf> _editableShelves = [];

  late final AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _navigateToShelfDetail({
    required String shelfName,
    String? shelfId,
    String? description,
    Color? shelfColor,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ShelfDetailPage(
              shelfName: shelfName,
              shelfId: shelfId,
              description: description,
              shelfColor: shelfColor,
            ),
      ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateShelfDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreateShelfDialog(),
    );
  }

  // ─── Edit mode ──────────────────────────────────────────────────────────────

  void _enterEditMode(List<Shelf> shelves) {
    HapticFeedback.heavyImpact();
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _isEditMode = true;
      _editableShelves = List.from(shelves);
    });
    _wobbleController.repeat();
  }

  void _exitEditMode() {
    if (!_isEditMode) return;
    _wobbleController.stop();
    _wobbleController.reset();
    setState(() => _isEditMode = false);
    _saveShelfOrder();
  }

  Future<void> _saveShelfOrder() async {
    try {
      final shelfService = ref.read(shelfServiceProvider);
      for (int i = 0; i < _editableShelves.length; i++) {
        await shelfService.updateShelf(
          shelfId: _editableShelves[i].id,
          orderIndex: i,
        );
      }
      ref.invalidate(allShelvesProvider);
    } catch (e) {
      debugPrint('Error saving shelf order: $e');
    }
  }

  void _reorderShelf(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    setState(() {
      final shelf = _editableShelves.removeAt(fromIndex);
      _editableShelves.insert(toIndex, shelf);
    });
  }

  void _editShelf(Shelf shelf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditShelfDialog(shelf: shelf),
    );
  }

  void _deleteShelf(Shelf shelf) {
    ShelfActions.showDeleteConfirmation(context, ref, shelf, (_) {
      if (_isEditMode) {
        setState(() => _editableShelves.removeWhere((s) => s.id == shelf.id));
      }
    });
  }

  // ─── Wobble ─────────────────────────────────────────────────────────────────

  /// Wraps [child] in an iOS-style jiggle when edit mode is active.
  /// Each card gets a unique phase via [index] so they wobble out of sync.
  Widget _wrapWithWobble(Widget child, int index) {
    return AnimatedBuilder(
      animation: _wobbleController,
      child: child,
      builder: (context, childWidget) {
        final angle =
            math.sin(_wobbleController.value * math.pi * 2 + index * 0.85) *
            0.035;
        return Transform.rotate(angle: angle, child: childWidget);
      },
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  List<Book> _getReadingNowBooks(List<Book> books) {
    return books
        .where(
          (book) =>
              book.isStartedReading &&
              (book.currentPage < book.totalPages || book.totalPages == 0),
        )
        .toList();
  }

  int _getShelfBookCount(String shelfId) {
    final booksAsync = ref.watch(booksInShelfProvider(shelfId));
    return booksAsync.whenOrNull(data: (books) => books.length) ?? 0;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Handle deep-link from homepage (BookshelvesWidget sets selectedShelfProvider)
    ref.listen<String>(selectedShelfProvider, (previous, next) {
      if (next != 'All Books') {
        final shelves = ref.read(allShelvesProvider).value ?? [];
        Shelf? shelf;
        try {
          shelf = shelves.firstWhere((s) => s.name == next);
        } catch (_) {}

        Future.microtask(() {
          ref.read(selectedShelfProvider.notifier).state = 'All Books';
        });

        if (mounted) {
          _navigateToShelfDetail(
            shelfName: next,
            shelfId: shelf?.id,
            description: shelf?.description,
            shelfColor:
                shelf != null
                    ? Color(int.parse(shelf.color.replaceFirst('#', '0xff')))
                    : null,
          );
        }
      }
    });

    final shelvesAsync = ref.watch(allShelvesProvider);
    final allBooksAsync = ref.watch(allBooksProvider);

    return WillPopScope(
      onWillPop: () async {
        if (_isEditMode) {
          _exitEditMode();
          return false;
        }
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F5),
        body: SafeArea(
          child: Column(
            children: [
              if (_isEditMode)
                _buildEditModeHeader()
              else
                const LibraryHeader(),
              const SizedBox(height: 8),
              if (!_isEditMode) ...[
                LibrarySearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 8),
              Expanded(child: _buildContent(shelvesAsync, allBooksAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditModeHeader() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final padLeft = (24 * scale).clamp(16.0, 24.0);
    final padRight = (16 * scale).clamp(12.0, 16.0);
    final titleSize = (26 * scale).clamp(20.0, 26.0);
    final doneSize = (16 * scale).clamp(14.0, 16.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(padLeft, 8, padRight, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Edit Shelves',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF-UI-Display',
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: _exitEditMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: doneSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
                color: const Color(0xFFD97A73),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<Shelf>> shelvesAsync,
    AsyncValue<List<Book>> allBooksAsync,
  ) {
    return shelvesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (shelves) {
        return allBooksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (books) => _buildBrowseView(shelves, books),
        );
      },
    );
  }

  Widget _buildBrowseView(List<Shelf> shelves, List<Book> allBooks) {
    // In edit mode: use the local reorderable list
    final effectiveShelves = _isEditMode ? _editableShelves : shelves;

    final readingNowBooks = _getReadingNowBooks(allBooks);
    final query = _searchQuery.toLowerCase();
    // Search is disabled in edit mode
    final isSearching = query.isNotEmpty && !_isEditMode;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final gridPadding = (20 * scale).clamp(16.0, 24.0);
    final gridSpacing = (14 * scale).clamp(10.0, 16.0);

    // Card dimensions for drag feedback widget
    final cardSize = (screenWidth - gridPadding * 2 - gridSpacing) / 2;

    final List<Widget> gridCards = [];

    // 0. New Shelf card — hidden in edit mode and search mode (now at the beginning)
    if (!isSearching && !_isEditMode) {
      gridCards.add(_buildNewShelfCard());
    }

    // 1. Reading Now card (fixed, not reorderable)
    if (!isSearching || 'reading now'.contains(query)) {
      if (readingNowBooks.isNotEmpty) {
        final readingNowCard = ReadingNowCard(
          activeBookCount: readingNowBooks.length,
          onTap:
              _isEditMode
                  ? () {}
                  : () => _navigateToShelfDetail(shelfName: 'Reading Now'),
        );
        gridCards.add(
          _isEditMode ? _wrapWithWobble(readingNowCard, 0) : readingNowCard,
        );
      }
    }

    // 2. All Books card (fixed, not reorderable)
    if (!isSearching || 'all books'.contains(query)) {
      final allBooksCard = ShelfCard(
        title: 'All Books',
        icon: Icons.menu_book_rounded,
        backgroundColor: const Color(0xFFE8EAF6),
        iconColor: const Color(0xFF3949AB),
        bookCount: allBooks.length,
        onTap:
            _isEditMode
                ? () {}
                : () => _navigateToShelfDetail(shelfName: 'All Books'),
      );
      gridCards.add(
        _isEditMode ? _wrapWithWobble(allBooksCard, 1) : allBooksCard,
      );
    }

    // 3. Custom shelves — draggable + edit/delete icons in edit mode
    for (int i = 0; i < effectiveShelves.length; i++) {
      final shelf = effectiveShelves[i];
      if (isSearching && !shelf.name.toLowerCase().contains(query)) {
        continue;
      }

      final shelfColor = Color(
        int.parse(shelf.color.replaceFirst('#', '0xff')),
      );

      // Determine colors based on the shelf's saved color
      int pairIndex = ShelfCard.iconColors.indexOf(shelfColor);
      Color bgColor;
      Color iconColor = shelfColor;

      if (pairIndex != -1) {
        bgColor = ShelfCard.bgColors[pairIndex];
      } else {
        // Fallback if the user's shelf has a legacy/random color not in the predefined list
        final hsl = HSLColor.fromColor(shelfColor);
        bgColor =
            hsl
                .withLightness(0.95)
                .toColor(); // very light version for the background
      }

      final card = ShelfCard(
        title: shelf.name,
        icon: ShelfCard.getShelfIcon(shelf.name),
        backgroundColor: bgColor,
        iconColor: iconColor,
        bookCount: _getShelfBookCount(shelf.id),
        onTap:
            _isEditMode
                ? () {}
                : () => _navigateToShelfDetail(
                  shelfName: shelf.name,
                  shelfId: shelf.id,
                  description: shelf.description,
                  shelfColor: shelfColor,
                ),
        onLongPress:
            _isEditMode ? null : () => _enterEditMode(effectiveShelves),
      );

      if (_isEditMode) {
        final idx = i; // capture for closure
        final draggableCard = LongPressDraggable<int>(
          data: idx,
          feedback: Material(
            color: Colors.transparent,
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: cardSize,
              height: cardSize,
              child: Opacity(
                opacity: 0.85,
                child: ShelfCard(
                  title: shelf.name,
                  icon: ShelfCard.getShelfIcon(shelf.name),
                  backgroundColor: bgColor,
                  iconColor: iconColor,
                  bookCount: _getShelfBookCount(shelf.id),
                  onTap: () {},
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: card),
          child: DragTarget<int>(
            onAcceptWithDetails: (details) => _reorderShelf(details.data, idx),
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return Stack(
                children: [
                  // Positioned.fill fixes size shrinking caused by Stack's loose
                  // constraints preventing Spacer() from expanding correctly.
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border:
                            isHovered
                                ? Border.all(
                                  color: iconColor.withOpacity(0.7),
                                  width: 2.5,
                                )
                                : null,
                      ),
                      child: card,
                    ),
                  ),
                  // Delete — top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _deleteShelf(shelf),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  // Edit — top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _editShelf(shelf),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.black87,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        gridCards.add(_wrapWithWobble(draggableCard, idx + 2));
      } else {
        gridCards.add(card);
      }
    }

    // Search: matching books
    List<Book> matchingBooks = [];
    if (isSearching) {
      matchingBooks =
          allBooks
              .where(
                (book) =>
                    book.title.toLowerCase().contains(query) ||
                    book.author.toLowerCase().contains(query),
              )
              .take(6)
              .toList();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gridPadding, 0, gridPadding, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: gridCards,
          ),

          // Search: matching books section
          if (isSearching && matchingBooks.isNotEmpty) ...[
            SizedBox(height: (24 * scale).clamp(18.0, 24.0)),
            Text(
              'Books',
              style: TextStyle(
                fontSize: (18 * scale).clamp(14.0, 18.0),
                fontWeight: FontWeight.w700,
                fontFamily: 'SF-UI-Display',
                color: Colors.black87,
              ),
            ),
            SizedBox(height: (12 * scale).clamp(8.0, 12.0)),
            GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children:
                  matchingBooks
                      .map(
                        (book) => BookCard(
                          book: book,
                          isSelectionMode: false,
                          isSelected: false,
                          onToggleSelection: (_) {},
                          currentShelf: 'All Books',
                        ),
                      )
                      .toList(),
            ),
          ],

          // Empty search state
          if (isSearching && gridCards.isEmpty && matchingBooks.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: (60 * scale).clamp(48.0, 60.0)),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: (18 * scale).clamp(14.0, 18.0),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: (14 * scale).clamp(10.0, 14.0),
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black.withValues(alpha: 0.3),
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

  Widget _buildNewShelfCard() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final iconSize = (28 * scale).clamp(24.0, 28.0);
    final nameSize = (14 * scale).clamp(10.0, 14.0);
    final cardPadding = (16 * scale).clamp(12.0, 16.0);

    return GestureDetector(
      onTap: _showCreateShelfDialog,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: iconSize, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              'New Shelf',
              style: TextStyle(
                fontSize: nameSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

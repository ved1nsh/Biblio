import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/providers/shelf_provider.dart';
import 'widgets/library_search_bar.dart';
import 'widgets/all_books_list.dart';
import 'widgets/sort_options_sheet.dart';
import 'widgets/empty_states/empty_library_state.dart';
import 'widgets/empty_states/empty_shelf_state.dart';
import 'widgets/selection/selection_toolbar.dart';
import 'widgets/selection/bulk_add_to_shelf_dialog.dart';
import 'actions/selection_actions.dart';

class ShelfDetailPage extends ConsumerStatefulWidget {
  final String shelfName;
  final String? shelfId;
  final String? description;
  final Color? shelfColor;

  const ShelfDetailPage({
    super.key,
    required this.shelfName,
    this.shelfId,
    this.description,
    this.shelfColor,
  });

  @override
  ConsumerState<ShelfDetailPage> createState() => _ShelfDetailPageState();
}

class _ShelfDetailPageState extends ConsumerState<ShelfDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _isSelectionMode = false;
  final Set<String> _selectedBookIds = {};

  bool get _isAllBooks => widget.shelfName == 'All Books';
  bool get _isReadingNow => widget.shelfName == 'Reading Now';
  bool get _isCustomShelf => !_isAllBooks && !_isReadingNow;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Book> _filterAndSortBooks(List<Book> books) {
    var filtered = books;

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((book) {
            return book.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                book.author.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    }

    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'author':
        filtered.sort((a, b) => a.author.compareTo(b.author));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  void _toggleSelectionMode(String bookId) {
    setState(() {
      if (!_isSelectionMode) {
        _isSelectionMode = true;
        _selectedBookIds
          ..clear()
          ..add(bookId);
      } else {
        if (_selectedBookIds.contains(bookId)) {
          _selectedBookIds.remove(bookId);
        } else {
          _selectedBookIds.add(bookId);
        }

        if (_selectedBookIds.isEmpty) {
          _isSelectionMode = false;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedBookIds.clear();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFCF9F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SortOptionsSheet(
            currentSort: _sortBy,
            onSortChanged: (newSort) {
              setState(() {
                _sortBy = newSort;
              });
            },
          ),
    );
  }

  void _addSelectedBooksToShelf() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => BulkAddToShelfDialog(
            selectedBookIds: _selectedBookIds,
            onComplete: _clearSelection,
          ),
    );
  }

  Future<void> _handleDelete() async {
    if (_isAllBooks || _isReadingNow) {
      await SelectionActions.deleteSelectedBooks(
        context,
        ref,
        _selectedBookIds,
        _clearSelection,
      );
    } else {
      await SelectionActions.removeSelectedBooksFromShelf(
        context,
        ref,
        widget.shelfName,
        _selectedBookIds,
        _clearSelection,
      );
    }
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(allBooksProvider);
    ref.invalidate(allShelvesProvider);

    if (_isCustomShelf) {
      String? resolvedId = widget.shelfId;
      if (resolvedId == null) {
        final shelves = ref.read(allShelvesProvider).maybeWhen(
          data: (data) => data,
          orElse: () => [],
        );
        try {
          resolvedId = shelves.firstWhere((s) => s.name == widget.shelfName).id;
        } catch (_) {}
      }
      if (resolvedId != null) {
        ref.invalidate(booksInShelfProvider(resolvedId));
      }
    }
    // Brief delay to ensure the UI shows the refresh indicator
    await Future.delayed(const Duration(milliseconds: 600));
  }

  List<Book> _getReadingNowBooks(List<Book> allBooks) {
    final active =
        allBooks
            .where(
              (book) =>
                  book.isStartedReading &&
                  (book.currentPage < book.totalPages || book.totalPages == 0),
            )
            .toList();
    active.sort((a, b) {
      final aDate = a.lastReadAt ?? a.updatedAt;
      final bDate = b.lastReadAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });
    return active;
  }

  Widget _buildBookSliver(
    AsyncValue<List<Book>> allBooksAsync,
    AsyncValue<List<Shelf>> shelvesAsync,
  ) {
    return allBooksAsync.when(
      loading:
          () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (err, stack) =>
              SliverFillRemaining(child: Center(child: Text('Error: $err'))),
      data: (allBooks) {
        return shelvesAsync.when(
          loading:
              () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
          data: (shelves) {
            List<Book> booksToShow;

            if (_isReadingNow) {
              booksToShow = _getReadingNowBooks(allBooks);
            } else if (_isAllBooks) {
              booksToShow = allBooks;
            } else {
              // Custom shelf — get books from provider
              String? resolvedShelfId = widget.shelfId;
              if (resolvedShelfId == null) {
                try {
                  resolvedShelfId =
                      shelves.firstWhere((s) => s.name == widget.shelfName).id;
                } catch (_) {}
              }

              if (resolvedShelfId != null) {
                final shelfBooksAsync = ref.watch(
                  booksInShelfProvider(resolvedShelfId),
                );

                // Local fallback for a smooth UI while loading
                final localBooks =
                    allBooks
                        .where(
                          (b) => b.shelfIds?.contains(resolvedShelfId) ?? false,
                        )
                        .toList();

                if (shelfBooksAsync.isLoading && localBooks.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (shelfBooksAsync.hasError && localBooks.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Error loading shelf books')),
                  );
                }
                // Prioritize fetched books, fallback to local ones if still fetching or if error
                booksToShow =
                    (shelfBooksAsync.value != null &&
                            shelfBooksAsync.value!.isNotEmpty)
                        ? shelfBooksAsync.value!
                        : localBooks;
              } else {
                booksToShow = [];
              }
            }

            final filteredBooks = _filterAndSortBooks(booksToShow);

            if (filteredBooks.isEmpty && _isAllBooks) {
              return const SliverFillRemaining(child: EmptyLibraryState());
            }

            if (filteredBooks.isEmpty && _isCustomShelf) {
              return SliverFillRemaining(
                child: EmptyShelfState(
                  shelfName: widget.shelfName,
                  shelfDescription: widget.description,
                  showShelfHeader: false,
                ),
              );
            }

            if (filteredBooks.isEmpty && _isReadingNow) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 80,
                        color: Color(0x33000000),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No books in progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0x66000000),
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start reading a book to see it here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0x4D000000),
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AllBooksList(
                    books: filteredBooks,
                    sortBy: _sortBy,
                    onSortPressed: _showSortOptions,
                    shelfName: widget.shelfName,
                    shelfDescription: widget.description,
                    isSelectionMode: _isSelectionMode,
                    selectedBookIds: _selectedBookIds,
                    onToggleSelection: _toggleSelectionMode,
                    showShelfHeader: false,
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBooksAsync = ref.watch(allBooksProvider);
    final shelvesAsync = ref.watch(allShelvesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (22 * scale).clamp(18.0, 26.0);

    return WillPopScope(
      onWillPop: () async {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return false;
        }
        if (_isSelectionMode) {
          _clearSelection();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F5),
        body: SafeArea(
          child: Column(
            children: [
              if (_isSelectionMode)
                SelectionToolbar(
                  selectedCount: _selectedBookIds.length,
                  isOnAllBooks: _isAllBooks || _isReadingNow,
                  onClose: _clearSelection,
                  onAddToShelf: _addSelectedBooksToShelf,
                  onDelete: _handleDelete,
                )
              else
                _buildShelfHeader(),

              const SizedBox(height: 8),

              LibrarySearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search in ${widget.shelfName}...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFFD97A73),
                  backgroundColor: Colors.white,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (widget.description != null &&
                          widget.description!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: (24 * scale).clamp(16.0, 24.0),
                              right: (24 * scale).clamp(16.0, 24.0),
                              top: (16 * scale).clamp(12.0, 16.0),
                              bottom: (4 * scale).clamp(2.0, 4.0),
                            ),
                            child: Text(
                              widget.description!,
                              style: TextStyle(
                                fontSize: titleSize,
                                color: Colors.black54,
                                fontFamily: 'SF-UI-Display',
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      _buildBookSliver(allBooksAsync, shelvesAsync),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShelfHeader() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (22 * scale).clamp(18.0, 26.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        (8 * scale).clamp(6.0, 8.0),
        (8 * scale).clamp(6.0, 8.0),
        (16 * scale).clamp(12.0, 16.0),
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: Colors.black87,
          ),
          // if (widget.shelfColor != null) ...[
          //   Container(
          //     width: 12,
          //     height: 12,
          //     decoration: BoxDecoration(
          //       color: widget.shelfColor,
          //       shape: BoxShape.circle,
          //     ),
          //   ),
          //   const SizedBox(width: 8),
          // ],
          Expanded(
            child: Text(
              widget.shelfName,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF-UI-Display',
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

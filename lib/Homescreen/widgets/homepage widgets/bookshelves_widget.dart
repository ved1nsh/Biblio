import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/shelf_provider.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/Homescreen/pages/library/widgets/book_details_sheet.dart';
import 'package:biblio/Homescreen/pages/library/shelf widgets/create_shelf_dialog.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/providers/book_provider.dart';

Color _colorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  if (hexColor.length == 8) {
    return Color(int.parse("0x$hexColor"));
  }
  // Return a default color if hex is invalid
  return Colors.grey;
}

IconData _getShelfIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('read') && lower.contains('to')) {
    return Icons.bookmark_outline;
  }
  if (lower.contains('top')) return Icons.emoji_events_outlined;
  if (lower.contains('own')) return Icons.menu_book_outlined;
  if (lower.contains('pdf') || lower.contains('library')) {
    return Icons.library_books_outlined;
  }
  if (lower.contains('fav')) return Icons.favorite_outline;
  return Icons.collections_bookmark_outlined;
}

class BookshelvesWidget extends ConsumerStatefulWidget {
  final VoidCallback? onShelfTap;

  const BookshelvesWidget({super.key, this.onShelfTap});

  @override
  ConsumerState<BookshelvesWidget> createState() => _BookshelvesWidgetState();
}

class _BookshelvesWidgetState extends ConsumerState<BookshelvesWidget> {
  int? expandedIndex = 0; // Default to expanding the first shelf

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final shelvesAsync = ref.watch(allShelvesProvider);
    final allBooksAsync = ref.watch(allBooksProvider);
    final allBooks = allBooksAsync.when(
      data: (books) => books,
      loading: () => [],
      error: (_, __) => [],
    );

    return shelvesAsync.when(
      loading:
          () => SizedBox(
            height: 100 * scale,
            child: const Center(child: CircularProgressIndicator()),
          ),
      error: (err, stack) {
        debugPrint('Error loading shelves: $err');
        return const SizedBox.shrink();
      },
      data: (shelves) {
        final sectionTitle = (18 * scale).clamp(16.0, 20.0);

        final customShelves =
            shelves.where((s) {
              final lower = s.name.toLowerCase();
              return lower != 'all books' && lower != 'reading now';
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookshelves',
              style: TextStyle(
                fontSize: sectionTitle,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF-UI-Display',
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12 * scale),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customShelves.length + 1, // +1 for New Shelf
              itemBuilder: (context, index) {
                if (index == customShelves.length) {
                  return _buildNewShelfCard(context, scale);
                }

                final shelf = customShelves[index];
                final isExpanded = expandedIndex == index;
                final shelfBooks =
                    (allBooks
                            .where(
                              (b) => b.shelfIds?.contains(shelf.id) ?? false,
                            )
                            .toList()
                        as List<Book>);

                return ExpandableShelfTile(
                  shelf: shelf,
                  books: shelfBooks,
                  isExpanded: isExpanded,
                  scale: scale,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        expandedIndex = null;
                      } else {
                        expandedIndex = index;
                      }
                    });
                  },
                  onViewShelf: () {
                    ref.read(selectedShelfProvider.notifier).state = shelf.name;
                    widget.onShelfTap?.call();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewShelfCard(BuildContext context, double scale) {
    final tileHeight = (70 * scale).roundToDouble();
    final iconSize = (24 * scale).clamp(22.0, 28.0);
    final nameSize = (16 * scale).clamp(14.0, 18.0);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const CreateShelfDialog(),
        );
      },
      child: Container(
        height: tileHeight,
        margin: EdgeInsets.only(bottom: 12 * scale),
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.add, color: Colors.grey[500], size: iconSize),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Text(
                'New Shelf',
                style: TextStyle(
                  fontSize: nameSize,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableShelfTile extends ConsumerStatefulWidget {
  final Shelf shelf;
  final List<Book> books;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onViewShelf;
  final double scale;

  const ExpandableShelfTile({
    super.key,
    required this.shelf,
    required this.books,
    required this.isExpanded,
    required this.onTap,
    required this.onViewShelf,
    required this.scale,
  });

  @override
  ConsumerState<ExpandableShelfTile> createState() =>
      _ExpandableShelfTileState();
}

class _ExpandableShelfTileState extends ConsumerState<ExpandableShelfTile> {
  @override
  Widget build(BuildContext context) {
    final shelfBooksAsync = ref.watch(booksInShelfProvider(widget.shelf.id));
    final books =
        (shelfBooksAsync.value != null && shelfBooksAsync.value!.isNotEmpty)
            ? shelfBooksAsync.value!
            : widget.books; // Use local books as a fallback

    final baseColor = _colorFromHex(widget.shelf.color);

    // Creating a modern, vibrant gradient based on the shelf color
    final hsl = HSLColor.fromColor(baseColor);
    final bgColor1 =
        hsl
            .withLightness((hsl.lightness - 0.1).clamp(0.2, 0.8))
            .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0))
            .toColor();
    final bgColor2 =
        hsl
            .withHue((hsl.hue + 45) % 360)
            .withLightness((hsl.lightness).clamp(0.2, 0.9))
            .withSaturation(0.9)
            .toColor();

    final collapsedHeight = (70 * widget.scale).roundToDouble();
    final iconSize = (24 * widget.scale).clamp(22.0, 28.0);
    final nameSize = (16 * widget.scale).clamp(14.0, 18.0);
    final coverWidth = (145 * widget.scale).clamp(125.0, 150.0);
    final coverHeight = coverWidth * 1.38;
    final expandedPadding = 16 * widget.scale;
    final headerGap = 20 * widget.scale;
    final coverLabelGap = 8 * widget.scale;
    final itemSpacing = 1 * widget.scale;
    final bookTitleHeight = (32 * widget.scale).clamp(26.0, 34.0);
    final listHeight = coverHeight + coverLabelGap + bookTitleHeight;
    final expandedHeight =
        expandedPadding * 2 +
        (34 * widget.scale).clamp(30.0, 40.0) +
        headerGap +
        listHeight;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        height: widget.isExpanded ? expandedHeight : collapsedHeight,
        margin: EdgeInsets.only(bottom: 12 * widget.scale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors:
                widget.isExpanded
                    ? [bgColor1, bgColor2]
                    : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border:
              widget.isExpanded ? null : Border.all(color: Colors.grey[300]!),
          boxShadow:
              widget.isExpanded
                  ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Collapsed content
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: collapsedHeight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: widget.isExpanded ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: widget.isExpanded,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * widget.scale,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            _getShelfIcon(widget.shelf.name),
                            color: baseColor,
                            size: iconSize,
                          ),
                          SizedBox(width: 16 * widget.scale),
                          Expanded(
                            child: Text(
                              widget.shelf.name,
                              style: TextStyle(
                                fontSize: nameSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontFamily: 'SF-UI-Display',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Expanded content
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: expandedHeight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: widget.isExpanded ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !widget.isExpanded,
                    child: Padding(
                      padding: EdgeInsets.all(expandedPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shelf.name,
                            style: TextStyle(
                              fontSize: (26 * widget.scale).clamp(22.0, 28.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SF-UI-Display',
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: headerGap),
                          SizedBox(
                            height: listHeight,
                            child:
                                shelfBooksAsync.isLoading &&
                                        widget.books.isEmpty
                                    ? Center(
                                      child: SizedBox(
                                        width: 24 * widget.scale,
                                        height: 24 * widget.scale,
                                        child: CircularProgressIndicator(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                    : books.isEmpty
                                    ? Center(
                                      child: Text(
                                        'Add books to this shelf to see them here',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontFamily: 'SF-UI-Display',
                                          fontSize: 14 * widget.scale,
                                        ),
                                      ),
                                    )
                                    : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: books.length + 1,
                                      separatorBuilder:
                                          (_, __) =>
                                              SizedBox(width: itemSpacing),
                                      itemBuilder: (context, index) {
                                        if (index == books.length) {
                                          return GestureDetector(
                                            onTap: widget.onViewShelf,
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: SizedBox(
                                                width: coverWidth,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: coverHeight,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .arrow_forward,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                size:
                                                                    28 *
                                                                    widget
                                                                        .scale,
                                                              ),
                                                              SizedBox(
                                                                height:
                                                                    8 *
                                                                    widget
                                                                        .scale,
                                                              ),
                                                              Text(
                                                                'View\nShelf',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: (14 *
                                                                          widget
                                                                              .scale)
                                                                      .clamp(
                                                                        12.0,
                                                                        16.0,
                                                                      ),
                                                                  fontFamily:
                                                                      'SF-UI-Display',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: coverLabelGap,
                                                    ),
                                                    SizedBox(
                                                      height: bookTitleHeight,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        final book = books[index];
                                        return GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder:
                                                  (context) => BookDetailsSheet(
                                                    book: book,
                                                    currentShelf:
                                                        widget.shelf.name,
                                                  ),
                                            );
                                          },
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: SizedBox(
                                              width: coverWidth,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: coverHeight,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                            blurRadius: 12,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  6,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                              ),
                                                          child:
                                                              book.coverUrl !=
                                                                          null &&
                                                                      book
                                                                          .coverUrl!
                                                                          .isNotEmpty
                                                                  ? Image.network(
                                                                    book.coverUrl!,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                    errorBuilder:
                                                                        (
                                                                          _,
                                                                          __,
                                                                          ___,
                                                                        ) => Icon(
                                                                          Icons
                                                                              .menu_book,
                                                                          color: Colors.white.withOpacity(
                                                                            0.5,
                                                                          ),
                                                                          size:
                                                                              32 *
                                                                              widget.scale,
                                                                        ),
                                                                  )
                                                                  : Icon(
                                                                    Icons
                                                                        .menu_book,
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                                    size:
                                                                        32 *
                                                                        widget
                                                                            .scale,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: coverLabelGap,
                                                  ),
                                                  SizedBox(
                                                    height: bookTitleHeight,
                                                    child: Text(
                                                      book.title,
                                                      maxLines: 2,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: (12 *
                                                                widget.scale)
                                                            .clamp(10.0, 14.0),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily:
                                                            'SF-UI-Display',
                                                        height: 1.2,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

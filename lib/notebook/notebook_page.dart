import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/notebook_service.dart';
import '../epub_viewer/quote_dialog/save_quote_dialog.dart';
import '../epub_viewer/controllers/epub_theme_controller.dart';

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage>
    with AutomaticKeepAliveClientMixin {
  final NotebookService _notebookService = NotebookService();

  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedBookId;

  // ✅ Track if this is the first load or a refresh
  bool _hasLoadedOnce = false;

  /// Distinct books derived from loaded quotes
  List<Map<String, String>> get _bookFilters {
    final seen = <String>{};
    final books = <Map<String, String>>[];
    for (final q in _quotes) {
      final id = q['book_id'] as String? ?? '';
      final title = q['book_title'] as String? ?? '';
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        books.add({'id': id, 'title': title});
      }
    }
    books.sort((a, b) => a['title']!.compareTo(b['title']!));
    return books;
  }

  /// Quotes after applying search + book filter
  List<Map<String, dynamic>> get _filteredQuotes {
    var result = _quotes;
    if (_selectedBookId != null) {
      result = result.where((q) => q['book_id'] == _selectedBookId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result =
          result.where((q) {
            final text = (q['quote_text'] as String? ?? '').toLowerCase();
            final author = (q['author_name'] as String? ?? '').toLowerCase();
            return text.contains(query) || author.contains(query);
          }).toList();
    }
    return result;
  }

  @override
  bool get wantKeepAlive => false; // Don't cache stale data

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ✅ Fires every time this page becomes active (e.g. navigating back to it)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedOnce && mounted) {
      _loadQuotes();
    }
  }

  Future<void> _loadQuotes() async {
    if (!mounted) return;

    // ✅ Only show full loading spinner on first load,
    // pull-to-refresh uses its own indicator
    if (!_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }

    try {
      final quotes = await _notebookService.getAllQuotes();
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    } catch (e) {
      debugPrint('❌ NotebookPage: Failed to load quotes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  // ✅ Explicit refresh for pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadQuotes();
  }

  Future<void> _deleteQuote(String quoteId) async {
    final success = await _notebookService.deleteQuote(quoteId);
    if (success) {
      setState(() {
        _quotes.removeWhere((q) => q['id'] == quoteId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Quote deleted',
              style: TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _openEditQuote(Map<String, dynamic> quote) {
    HapticFeedback.mediumImpact();

    final themeController = EpubThemeController();

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => SaveQuoteDialog(
              quoteText: _stripQuoteMarks(quote['quote_text'] ?? ''),
              bookTitle: quote['book_title'] ?? '',
              authorName: quote['author_name'] ?? '',
              themeController: themeController,
              editMode: true,
              quoteId: quote['id'],
              bookId: quote['book_id'],
              initialFontFamily: quote['font_family'] ?? 'NeueMontreal',
              initialFontSize: (quote['font_size'] as num?)?.toDouble() ?? 24,
              initialIsBold: quote['is_bold'] ?? false,
              initialIsItalic: quote['is_italic'] ?? false,
              initialTextAlign: quote['text_align'] ?? 'left',
              initialCardAlignment:
                  quote['card_alignment'] ?? 'center', // ✅ Add this
              initialLineHeight:
                  (quote['line_height'] as num?)?.toDouble() ?? 1.5,
              initialLetterSpacing:
                  (quote['letter_spacing'] as num?)?.toDouble() ?? 0,
              initialBackgroundColor: quote['background_color'] ?? '#F5E6D3',
              initialTextColor: quote['text_color'] ?? '#000000',
              initialShowAuthor: quote['show_author'] ?? true,
              initialShowBookTitle: quote['show_book_title'] ?? true,
              initialShowUsername: quote['show_username'] ?? false,
              initialAspectRatio:
                  (quote['aspect_ratio'] as num?)?.toDouble() ?? 1.0,
              initialMetadataAlign: quote['metadata_align'] ?? 'bottomLeft',
              initialCardTheme: quote['card_theme'] ?? 'default',
              bookCoverUrl: quote['book_cover_url'] as String?,
              onSave: () {
                _loadQuotes();
              },
            ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  String _stripQuoteMarks(String text) {
    return text
        .replaceAll('\u201C', '')
        .replaceAll('\u201D', '')
        .replaceAll('"', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final appBarTopPad = (15 * scale).clamp(12.0, 15.0);
    final titleSize = (32 * scale).clamp(26.0, 32.0);
    final searchPadH = (20 * scale).clamp(16.0, 20.0);
    final searchGap = (12 * scale).clamp(10.0, 12.0);
    final filterHeight = (38 * scale).clamp(32.0, 38.0);
    final filterPadH = (20 * scale).clamp(16.0, 20.0);

    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _searchFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F5),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header styled like StreakHeader
              Padding(
                padding: EdgeInsets.only(top: appBarTopPad),
                child: AppBar(
                  backgroundColor: const Color(0xFFFCF9F5),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'My Notebook',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
              ),

              SizedBox(height: (8 * scale).clamp(6.0, 8.0)),

              // ─── Search Bar ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: searchPadH),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'SF-UI-Display',
                      color: Color(0xFF2D2D2D),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search quotes...',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Book Filter Chips ──────────────────────────────
              if (_quotes.isNotEmpty && _bookFilters.length > 1) ...[
                SizedBox(height: searchGap),
                SizedBox(
                  height: filterHeight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: filterPadH),
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: _selectedBookId == null,
                        onTap: () => setState(() => _selectedBookId = null),
                      ),
                      ..._bookFilters.map(
                        (book) => _buildFilterChip(
                          label: book['title']!,
                          isSelected: _selectedBookId == book['id'],
                          onTap:
                              () =>
                                  setState(() => _selectedBookId = book['id']),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: (8 * scale).clamp(6.0, 8.0)),

              // Content
              Expanded(child: _buildQuotesGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotesGrid() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final emptyIconSize = (80 * scale).clamp(66.0, 80.0);
    final emptyTitleSize = (18 * scale).clamp(15.0, 18.0);
    final emptyBodySize = (14 * scale).clamp(12.0, 14.0);
    final searchEmptyIconSize = (64 * scale).clamp(54.0, 64.0);
    final searchEmptyTitle = (17 * scale).clamp(14.0, 17.0);
    final searchEmptyBody = (13 * scale).clamp(11.0, 13.0);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB85C38)),
        ),
      );
    }

    if (_quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: emptyIconSize,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No quotes saved yet',
              style: TextStyle(
                fontSize: emptyTitleSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start reading and save your\nfavourite quotes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: emptyBodySize,
                color: Colors.grey.shade400,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredQuotes;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: searchEmptyIconSize,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              'No matching quotes',
              style: TextStyle(
                fontSize: searchEmptyTitle,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search or filter',
              style: TextStyle(
                fontSize: searchEmptyBody,
                color: Colors.grey.shade400,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Wrap with RefreshIndicator for pull-to-refresh
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFB85C38),
      backgroundColor: Colors.white,
      displacement: 40,
      child: _buildMasonryGrid(filtered),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final chipPadH = (14 * scale).clamp(10.0, 14.0);
    final chipFont = (13 * scale).clamp(11.0, 13.0);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: chipPadH, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD97757) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFFD97757) : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xFFD97757).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: chipFont,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(List<Map<String, dynamic>> quotes) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final gridPadH = (16 * scale).clamp(12.0, 16.0);
    final gridGap = (12 * scale).clamp(8.0, 12.0);
    final bottomSpacer = (120 * scale).clamp(96.0, 120.0);

    final leftColumn = <Map<String, dynamic>>[];
    final rightColumn = <Map<String, dynamic>>[];

    for (int i = 0; i < quotes.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(quotes[i]);
      } else {
        rightColumn.add(quotes[i]);
      }
    }

    // ✅ Use CustomScrollView + SliverToBoxAdapter so RefreshIndicator
    // can detect the scroll position properly
    return CustomScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(), // ✅ needed for pull-to-refresh even when list is short
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gridPadH),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children:
                        leftColumn
                            .map((q) => _buildStyledQuoteCard(q))
                            .toList(),
                  ),
                ),
                SizedBox(width: gridGap),
                Expanded(
                  child: Column(
                    children:
                        rightColumn
                            .map((q) => _buildStyledQuoteCard(q))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ✅ Bottom padding so last card isn't clipped
        SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
      ],
    );
  }

  Widget _buildStyledQuoteCard(Map<String, dynamic> quote) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final cardMarginBottom = (12 * scale).clamp(10.0, 12.0);
    final cardPad = (12 * scale).clamp(10.0, 12.0);

    final bgColor = _hexToColor(quote['background_color'] ?? '#F5E6D3');
    final txtColor = _hexToColor(quote['text_color'] ?? '#000000');
    final fontFamily = quote['font_family'] ?? 'NeueMontreal';
    final fontSize = (quote['font_size'] as num?)?.toDouble() ?? 16;
    final isBold = quote['is_bold'] ?? false;
    final isItalic = quote['is_italic'] ?? false;
    final textAlign = _alignFromString(quote['text_align'] ?? 'left');
    final lineHeight = (quote['line_height'] as num?)?.toDouble() ?? 1.5;
    final letterSpacing = (quote['letter_spacing'] as num?)?.toDouble() ?? 0;
    final showAuthor = quote['show_author'] ?? true;
    final showBookTitle = quote['show_book_title'] ?? true;
    final authorName = quote['author_name'] ?? '';
    final bookTitle = quote['book_title'] ?? '';
    final metadataAlignment = _cardAlignmentFromString(
      quote['metadata_align'] ?? 'bottomLeft',
    );
    final quoteText = quote['quote_text'] ?? '';
    final aspectRatio = (quote['aspect_ratio'] as num?)?.toDouble() ?? 1.0;
    final cardAlignment = _cardAlignmentFromString(
      quote['card_alignment'] ?? 'center',
    ); // ✅ Read from DB
    final cardTheme = quote['card_theme'] ?? 'default';
    final isBelieverTheme = cardTheme == 'believer';
    final bookCoverUrl = quote['book_cover_url'] as String?;

    // Scale font proportionally to card size
    final cardFontSize = (fontSize * 0.55).clamp(10.0, 15.0);

    // Compute max lines based on aspect ratio to prevent overflow
    final maxLines = aspectRatio > 1.2 ? 8 : 5;

    return GestureDetector(
      onTap: () => _openEditQuote(quote),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteSheet(quote['id']);
      },
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          margin: EdgeInsets.only(bottom: cardMarginBottom),
          padding: EdgeInsets.all(cardPad),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Quote text positioned by cardAlignment
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isBelieverTheme ? 36 : 0,
                    bottom: isBelieverTheme ? 28 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: _crossAxisFromTextAlign(textAlign),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cardAlignment == Alignment.bottomLeft ||
                          cardAlignment == Alignment.bottomRight ||
                          cardAlignment == Alignment.bottomCenter ||
                          cardAlignment == Alignment.center ||
                          cardAlignment == Alignment.centerLeft ||
                          cardAlignment == Alignment.centerRight)
                        const Spacer(),

                      Flexible(
                        child: Text(
                          quoteText,
                          textAlign: textAlign,
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: cardFontSize,
                            fontWeight:
                                isBold ? FontWeight.w700 : FontWeight.w400,
                            fontStyle:
                                isItalic ? FontStyle.italic : FontStyle.normal,
                            height: lineHeight.clamp(1.2, 1.5),
                            letterSpacing: letterSpacing.clamp(-0.5, 0.5),
                            color: txtColor,
                          ),
                        ),
                      ),

                      if (cardAlignment == Alignment.topLeft ||
                          cardAlignment == Alignment.topRight ||
                          cardAlignment == Alignment.topCenter ||
                          cardAlignment == Alignment.center ||
                          cardAlignment == Alignment.centerLeft ||
                          cardAlignment == Alignment.centerRight)
                        const Spacer(),
                    ],
                  ),
                ),
              ),

              // Metadata positioned independently
              if (!isBelieverTheme &&
                  ((showAuthor && authorName.isNotEmpty) ||
                      (showBookTitle && bookTitle.isNotEmpty)))
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildCombinedMetadata(
                    showAuthor: showAuthor,
                    showBookTitle: showBookTitle,
                    authorName: authorName,
                    bookTitle: bookTitle,
                    metadataAlignment: metadataAlignment,
                    fontFamily: fontFamily,
                    fontSize: cardFontSize,
                    color: txtColor,
                  ),
                ),

              if (isBelieverTheme)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient:
                              bookCoverUrl == null
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0B253A),
                                      Color(0xFF111111),
                                    ],
                                  )
                                  : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            bookCoverUrl != null
                                ? Image.network(
                                  bookCoverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF0B253A),
                                              Color(0xFF111111),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.menu_book_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                )
                                : const Icon(
                                  Icons.menu_book_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'SF-UI-Display',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            if (authorName.isNotEmpty)
                              Text(
                                authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'SF-UI-Display',
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (isBelieverTheme)
                const Positioned(
                  left: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 11,
                        color: Colors.black,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Biblio',
                        style: TextStyle(
                          fontFamily: 'SF-UI-Display',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteSheet(String quoteId) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final sheetPadH = (24 * scale).clamp(16.0, 24.0);
    final deleteIconSize = (48 * scale).clamp(40.0, 48.0);
    final titleSize = (18 * scale).clamp(15.0, 18.0);
    final bodySize = (14 * scale).clamp(12.0, 14.0);
    final buttonPadV = (14 * scale).clamp(11.0, 14.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.fromLTRB(
              sheetPadH,
              24,
              sheetPadH,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  Icons.delete_outline_rounded,
                  size: deleteIconSize,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete this quote?',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: bodySize,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: buttonPadV),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteQuote(quoteId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: buttonPadV),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFFF5E6D3);
  }

  TextAlign _alignFromString(String value) {
    switch (value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  CrossAxisAlignment _crossAxisFromTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  Widget _buildCombinedMetadata({
    required bool showAuthor,
    required bool showBookTitle,
    required String authorName,
    required String bookTitle,
    required Alignment metadataAlignment,
    required String fontFamily,
    required double fontSize,
    required Color color,
  }) {
    final hasBookAndAuthor =
        showBookTitle &&
        showAuthor &&
        bookTitle.isNotEmpty &&
        authorName.isNotEmpty;
    final hasOnlyBook =
        showBookTitle && bookTitle.isNotEmpty && !hasBookAndAuthor;
    final hasOnlyAuthor =
        showAuthor && authorName.isNotEmpty && !hasBookAndAuthor;

    final metadataTextAlign =
        metadataAlignment.x < 0
            ? TextAlign.left
            : metadataAlignment.x > 0
            ? TextAlign.right
            : TextAlign.center;

    final metaFontSize = fontSize * 0.7;

    if (hasBookAndAuthor) {
      return RichText(
        textAlign: metadataTextAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            fontSize: metaFontSize,
            fontFamily: 'SF-UI-Display',
            color: color.withOpacity(0.6),
            letterSpacing: 0.2,
          ),
          children: [
            const TextSpan(text: 'In '),
            TextSpan(
              text: bookTitle,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const TextSpan(text: ', by '),
            TextSpan(
              text: authorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (hasOnlyBook) {
      return Text(
        bookTitle,
        textAlign: metadataTextAlign,
        style: TextStyle(
          fontSize: metaFontSize,
          fontFamily: 'SF-UI-Display',
          fontStyle: FontStyle.italic,
          color: color.withOpacity(0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (hasOnlyAuthor) {
      return Text(
        '— $authorName',
        textAlign: metadataTextAlign,
        style: TextStyle(
          fontSize: metaFontSize,
          fontFamily: 'SF-UI-Display',
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return const SizedBox.shrink();
  }

  // ✅ Add this helper method
  Alignment _cardAlignmentFromString(String value) {
    switch (value) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }
}

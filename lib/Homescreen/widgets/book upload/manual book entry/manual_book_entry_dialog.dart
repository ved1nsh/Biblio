import 'package:biblio/Homescreen/widgets/book%20upload/manual%20book%20entry/book_search_card.dart';
import 'package:biblio/Homescreen/widgets/book%20upload/manual%20book%20entry/book_success_sheet.dart';
import 'package:biblio/Homescreen/widgets/book%20upload/manual%20book%20entry/search_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/services/google_books_service.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:typed_data';

class ManualBookEntryDialog extends ConsumerStatefulWidget {
  const ManualBookEntryDialog({super.key});

  @override
  ConsumerState<ManualBookEntryDialog> createState() =>
      _ManualBookEntryDialogState();
}

class _ManualBookEntryDialogState extends ConsumerState<ManualBookEntryDialog> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleBooksService _googleBooksService = GoogleBooksService();

  List<BookSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isManualSearch = true;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchBooks(query);
    });
  }

  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _googleBooksService.searchBooks(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  String _getHighResolutionCoverUrl(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) return '';

    return coverUrl
        .replaceAll('zoom=1', 'zoom=0')
        .replaceAll('&edge=curl', '')
        .replaceAll('thumbnail', 'small');
  }

  Future<Uint8List> _downloadCover(String? coverUrl) async {
    if (coverUrl == null || coverUrl.isEmpty) {
      return Uint8List(0);
    }

    try {
      final highResUrl = _getHighResolutionCoverUrl(coverUrl);
      final response = await http.get(Uri.parse(highResUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading cover: $e');
    }

    return Uint8List(0);
  }

  Future<void> _handleBookSelection(BookSearchResult book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFD97A73)),
          ),
    );

    try {
      final coverBytes = await _downloadCover(book.coverUrl);

      // Upload cover to Supabase Storage
      final bookService = ref.read(bookServiceProvider);
      String? coverUrl;
      // Create book in Supabase first to get the bookId
      final savedBook = await bookService.createBook(
        title: book.title,
        author: book.authorNames,
        coverUrl: null,
        totalPages: book.pageCount ?? 0,
        isManualEntry: true,
      );

      if (coverBytes.isNotEmpty) {
        coverUrl = await bookService.uploadBookCover(
          bookId: savedBook.id,
          imageBytes: coverBytes,
        );
        // Update the book with the coverUrl
        await bookService.updateBook(bookId: savedBook.id, coverUrl: coverUrl);
      }

      ref.invalidate(allBooksProvider);

      if (!mounted) return;

      Navigator.of(context).pop();
      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => BookSuccessSheet(book: savedBook),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding book: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final scale = (screenWidth / 393).clamp(0.85, 1.0);
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF9F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(scale),
              _buildSearchToggle(),
              _buildSearchBar(),
              Expanded(child: _buildResultsList(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(double scale) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Add Book',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (20 * scale).clamp(16.0, 20.0),
                fontWeight: FontWeight.w700,
                fontFamily: 'SF-UI-Display',
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Manual Search',
              isSelected: _isManualSearch,
              onTap: () => setState(() => _isManualSearch = true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildToggleButton(
              label: 'Scan Barcode',
              isSelected: !_isManualSearch,
              onTap: () {
                setState(() => _isManualSearch = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Barcode scanning coming soon!'),
                    backgroundColor: Color(0xFFD97A73),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA8B5A8) : const Color(0xFFE8EDE8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF-UI-Display',
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by title or author...',
          hintStyle: TextStyle(
            fontFamily: 'SF-UI-Display',
            color: Colors.black.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          filled: true,
          fillColor: const Color(0xFFE8EDE8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontFamily: 'SF-UI-Display', fontSize: 16),
      ),
    );
  }

  Widget _buildResultsList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD97A73)),
      );
    }

    if (_searchController.text.isEmpty) {
      return const SearchEmptyState(
        icon: Icons.search,
        title: 'Search for a book',
        subtitle: 'Enter a title or author name',
      );
    }

    if (_searchResults.isEmpty) {
      return const SearchEmptyState(
        icon: Icons.search_off,
        title: 'No books found',
        subtitle: 'Try a different search term',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return BookSearchCard(
          book: book,
          coverUrl: _getHighResolutionCoverUrl(book.coverUrl),
          onTap: () => _handleBookSelection(book),
        );
      },
    );
  }
}

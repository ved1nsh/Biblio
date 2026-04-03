// This dialog lets users search for book cover using Google Books API
// Shows search results with covers and lets user pick one

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:biblio/core/services/google_books_service.dart';
import 'package:http/http.dart' as http;

class BookSearchDialog extends StatefulWidget {
  final String initialQuery;

  const BookSearchDialog({super.key, required this.initialQuery});

  @override
  State<BookSearchDialog> createState() => _BookSearchDialogState();
}

class _BookSearchDialogState extends State<BookSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleBooksService _booksService = GoogleBooksService();

  List<BookSearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    try {
      final results = await _booksService.searchBooks(
        _searchController.text.trim(),
      );
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isSearching = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<Uint8List?> _downloadCover(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading cover: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerSize = (20 * scale).clamp(16.0, 20.0);
    final padAll = (24 * scale).clamp(16.0, 24.0);
    final gap24 = (24 * scale).clamp(18.0, 24.0);

    return Container(
      padding: EdgeInsets.all(padAll),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Search for Book Cover',
                  style: TextStyle(fontSize: headerSize, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter book title or author',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _performSearch,
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),

          SizedBox(height: gap24),

          // Results
          Expanded(child: _buildResultsSection()),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final iconLarge = (64 * scale).roundToDouble();
    final iconMedium = (56 * scale).roundToDouble();
    final padH24 = (24 * scale).clamp(16.0, 24.0);

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: iconLarge, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Search for your book above',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padH24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: iconMedium, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Search failed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip and continue without cover'),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: iconLarge, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No books found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip and use default cover'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final book = _results[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(BookSearchResult book) {
    return GestureDetector(
      onTap: () async {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        // Download cover
        Uint8List? coverBytes;
        if (book.coverUrl != null) {
          coverBytes = await _downloadCover(book.coverUrl!);
        }

        if (!mounted) return;
        Navigator.pop(context); // Pop loading

        // Return selected book with cover
        Navigator.pop(context, {
          'title': book.title,
          'author': book.authorNames,
          'coverBytes': coverBytes,
          'coverUrl': book.coverUrl,
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    book.coverUrl != null
                        ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.book,
                                size: 48,
                                color: Colors.grey,
                              ),
                        )
                        : const Center(
                          child: Icon(Icons.book, size: 48, color: Colors.grey),
                        ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),

          // Author
          Text(
            book.authorNames,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

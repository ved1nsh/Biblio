import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleBooksService {
  // Replace with your actual API key
  static const String _apiKey = 'AIzaSyABXbwSgkVcjrg6i_1wxoNk17oDkKPZjqo';
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  /// Google Books API returns http:// thumbnail URLs which are blocked by
  /// iOS ATS and Android Network Security Config. This upgrades them to
  /// https:// and improves resolution from zoom=1 (thumbnail) to zoom=0
  /// (larger cover image).
  static String _fixCoverUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    // Upgrade http → https
    var url = rawUrl.replaceFirst('http://', 'https://');
    // zoom=1 is a small thumbnail; zoom=0 gives the full front-cover image
    url = url.replaceFirst('zoom=1', 'zoom=0');
    // Remove the ugly curl edge effect
    url = url.replaceFirst('&edge=curl', '');
    return url;
  }

  Future<List<BookSearchResult>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl?q=${Uri.encodeQueryComponent(query)}&key=$_apiKey&maxResults=20',
    );

    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 15),
          onTimeout:
              () =>
                  throw Exception(
                    'Request timed out. Check your internet connection.',
                  ),
        );

    if (response.statusCode != 200) {
      // Surface the actual error message from Google instead of silently failing
      try {
        final errorData = json.decode(response.body);
        final message = errorData['error']?['message'] as String?;
        throw Exception(
          message ?? 'Google Books API error (${response.statusCode})',
        );
      } catch (_) {
        throw Exception('Google Books API error (${response.statusCode})');
      }
    }

    final data = json.decode(response.body);
    final items = data['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return [];

    return items.map((item) {
      final volumeInfo = item['volumeInfo'] as Map<String, dynamic>;
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;

      // Prefer the highest resolution available
      final rawCoverUrl =
          imageLinks?['extraLarge'] as String? ??
          imageLinks?['large'] as String? ??
          imageLinks?['medium'] as String? ??
          imageLinks?['small'] as String? ??
          imageLinks?['thumbnail'] as String? ??
          imageLinks?['smallThumbnail'] as String?;

      final coverUrl =
          rawCoverUrl != null && rawCoverUrl.isNotEmpty
              ? _fixCoverUrl(rawCoverUrl)
              : null;

      return BookSearchResult(
        title: volumeInfo['title'] as String? ?? 'Unknown Title',
        authors:
            (volumeInfo['authors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['Unknown Author'],
        coverUrl: coverUrl,
        publishedYear: volumeInfo['publishedDate'] as String?,
        isbn: _extractISBN(volumeInfo['industryIdentifiers'] as List<dynamic>?),
        pageCount: volumeInfo['pageCount'] as int?,
      );
    }).toList();
  }

  String? _extractISBN(List<dynamic>? identifiers) {
    if (identifiers == null) return null;

    for (var identifier in identifiers) {
      final type = identifier['type'] as String?;
      if (type == 'ISBN_13' || type == 'ISBN_10') {
        return identifier['identifier'] as String?;
      }
    }
    return null;
  }
}

class BookSearchResult {
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? publishedYear;
  final String? isbn;
  final int? pageCount;

  BookSearchResult({
    required this.title,
    required this.authors,
    this.coverUrl,
    this.publishedYear,
    this.isbn,
    this.pageCount,
  });

  String get authorNames => authors.join(', ');
}

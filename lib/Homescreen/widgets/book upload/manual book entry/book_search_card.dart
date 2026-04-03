import 'package:flutter/material.dart';
import 'package:biblio/core/services/google_books_service.dart';

class BookSearchCard extends StatelessWidget {
  final BookSearchResult book;
  final String coverUrl;
  final VoidCallback onTap;

  const BookSearchCard({
    super.key,
    required this.book,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCover(scale),
            const SizedBox(width: 12),
            _buildBookInfo(scale),
            _buildAddButton(scale),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(double scale) {
    return Container(
      width: (60 * scale).clamp(50.0, 60.0),
      height: (90 * scale).clamp(70.0, 90.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child:
          coverUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                ),
              )
              : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFD97A73).withValues(alpha: 0.3),
      ),
      child: const Center(
        child: Icon(Icons.menu_book, color: Color(0xFFD97A73), size: 32),
      ),
    );
  }

  Widget _buildBookInfo(double scale) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: TextStyle(
              fontSize: (16 * scale).clamp(13.0, 16.0),
              fontWeight: FontWeight.w600,
              fontFamily: 'SF-UI-Display',
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            book.authorNames,
            style: TextStyle(
              fontSize: (14 * scale).clamp(11.0, 14.0),
              fontFamily: 'SF-UI-Display',
              color: Colors.black.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(double scale) {
    return Container(
      width: (40 * scale).clamp(32.0, 40.0),
      height: (40 * scale).clamp(32.0, 40.0),
      decoration: BoxDecoration(
        color: const Color(0xFFA8B5A8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.add,
        color: Colors.white,
        size: (20 * scale).roundToDouble(),
      ),
    );
  }
}

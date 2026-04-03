import 'package:flutter/material.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/reading_session/constants/reading_session_colors.dart';

class PhysicalBookCard extends StatelessWidget {
  final Book book;

  const PhysicalBookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final progress =
        book.totalPages > 0 ? book.currentPage / book.totalPages : 0.0;

    return Container(
      padding: EdgeInsets.all((16 * scale).clamp(12.0, 16.0)),
      decoration: BoxDecoration(
        color: ReadingSessionColors.bookCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 48, 48, 48).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(context),
          SizedBox(width: (16 * scale).clamp(12.0, 16.0)),
          Expanded(
            child: SizedBox(
              height: (130 * scale).clamp(110.0, 130.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      book.title,
                      style: TextStyle(
                        fontSize: (22 * scale).clamp(18.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: ReadingSessionColors.bookTitleColor,
                        fontFamily: 'SF-UI-Display',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: (2 * scale).clamp(2.0, 2.0)),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: (13 * scale).clamp(11.0, 13.0),
                      color: ReadingSessionColors.bookAuthorColor,
                      fontFamily: 'SF-UI-Display',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Progress bar
                  _buildProgressBar(context, progress),
                  SizedBox(height: (6 * scale).clamp(4.0, 6.0)),
                  // Page info row
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: (14 * scale).clamp(12.0, 14.0),
                        color: ReadingSessionColors.progressFillColor,
                      ),
                      SizedBox(width: (4 * scale).clamp(3.0, 4.0)),
                      Text(
                        'Start: Pg ${book.currentPage}',
                        style: TextStyle(
                          fontSize: (12 * scale).clamp(10.0, 12.0),
                          fontWeight: FontWeight.w500,
                          color: ReadingSessionColors.bookPageColor,
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      SizedBox(width: (8 * scale).clamp(6.0, 8.0)),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: (12 * scale).clamp(10.0, 12.0),
                          color: ReadingSessionColors.bookPageColor,
                        ),
                      ),
                      SizedBox(width: (8 * scale).clamp(6.0, 8.0)),
                      Icon(
                        Icons.menu_book,
                        size: (14 * scale).clamp(12.0, 14.0),
                        color: ReadingSessionColors.bookPageColor,
                      ),
                      SizedBox(width: (4 * scale).clamp(3.0, 4.0)),
                      Text(
                        'Total: ${book.totalPages} Pgs',
                        style: TextStyle(
                          fontSize: (12 * scale).clamp(10.0, 12.0),
                          fontWeight: FontWeight.w500,
                          color: ReadingSessionColors.bookPageColor,
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final coverWidth = (90 * scale).clamp(76.0, 90.0).roundToDouble();
    final coverHeight = (coverWidth * 1.45).roundToDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child:
          book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? Image.network(
                book.coverUrl!,
                width: coverWidth,
                height: coverHeight,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: coverWidth,
                    height: coverHeight,
                    color: Colors.grey[300],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: coverWidth,
                      height: coverHeight,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),
              )
              : Container(
                width: coverWidth,
                height: coverHeight,
                color: Colors.grey[300],
                child: const Icon(Icons.book, color: Colors.grey),
              ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final percentText = '${(progress * 100).toInt()}% completed';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            percentText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ReadingSessionColors.progressTextColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: (8 * scale).clamp(6.0, 8.0),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: ReadingSessionColors.progressTrackColor,
              valueColor: const AlwaysStoppedAnimation(
                ReadingSessionColors.progressFillColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

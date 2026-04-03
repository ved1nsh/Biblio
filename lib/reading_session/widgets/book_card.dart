import 'package:flutter/material.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/services/reading_preferences_service.dart';
import '../constants/reading_session_colors.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final double readPercent;

  const BookCard({super.key, required this.book, this.readPercent = 0.35});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final coverWidth = (80 * scale).roundToDouble().clamp(60.0, 90.0);
    final coverHeight = coverWidth * 1.65;
    final titleSize = (22 * scale).clamp(18.0, 28.0);
    final authorSize = (12 * scale).clamp(11.0, 13.0);
    final progressTextSize = (14 * scale).clamp(12.0, 16.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((14 * scale).clamp(12.0, 16.0)),
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
          _buildCover(coverWidth, coverHeight),
          SizedBox(width: (14 * scale).clamp(10.0, 16.0)),
          Expanded(
            child: SizedBox(
              height: coverHeight,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        book.title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: ReadingSessionColors.bookTitleColor,
                          fontFamily: 'SF-UI-Display',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: authorSize,
                        color: ReadingSessionColors.bookAuthorColor,
                        fontFamily: 'SF-UI-Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),
                    _buildProgressBar(progressTextSize),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child:
          book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? Image.network(
                book.coverUrl!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: width,
                    height: height,
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
                      width: width,
                      height: height,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),
              )
              : Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.book, color: Colors.grey),
              ),
    );
  }

  Widget _buildProgressBar(double progressTextSize) {
    return FutureBuilder<double>(
      future: _getProgress(),
      builder: (context, snapshot) {
        final progress =
            snapshot.data != null ? (snapshot.data! / 100) : readPercent;

        return LayoutBuilder(
          builder: (context, constraints) {
            final percentText = '${(progress * 100).toInt()}% completed';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: constraints.maxWidth,
                  alignment: Alignment.centerRight,
                  child: Text(
                    percentText,
                    style: TextStyle(
                      fontSize: progressTextSize,
                      fontWeight: FontWeight.w600,
                      color: ReadingSessionColors.progressTextColor,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: constraints.maxWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            ReadingSessionColors.progressTrackColor,
                        valueColor: const AlwaysStoppedAnimation(
                          ReadingSessionColors.progressFillColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<double> _getProgress() async {
    try {
      final progress = await ReadingPreferencesService().getProgressPercent(
        book.id,
      );
      return progress;
    } catch (e) {
      return readPercent * 100;
    }
  }
}

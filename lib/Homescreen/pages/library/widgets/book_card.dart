import 'package:flutter/material.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/services/reading_preferences_service.dart'; // NEW: Add this import
import 'book_details_sheet.dart';
import 'package:flutter/services.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(String) onToggleSelection;
  final String currentShelf;

  const BookCard({
    super.key,
    required this.book,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onToggleSelection,
    this.currentShelf = 'All Books',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          onToggleSelection(book.id);
        } else {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.5),
            builder:
                (context) =>
                    BookDetailsSheet(book: book, currentShelf: currentShelf),
          );
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onToggleSelection(book.id);
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isSelected
                            ? Border.all(
                              color: const Color(0xFFD97A73),
                              width: 3,
                            )
                            : null,
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
                        book.coverUrl != null && book.coverUrl!.isNotEmpty
                            ? Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: const Color(
                                      0xFFD97A73,
                                    ).withValues(alpha: 0.3),
                                    child: const Center(
                                      child: Icon(
                                        Icons.menu_book,
                                        color: Color(0xFFD97A73),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                            )
                            : Container(
                              color: const Color(
                                0xFFD97A73,
                              ).withValues(alpha: 0.3),
                              child: const Center(
                                child: Icon(
                                  Icons.menu_book,
                                  color: Color(0xFFD97A73),
                                  size: 40,
                                ),
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // NEW: Progress bar (only show if progress > 0)
              FutureBuilder<double>(
                future: _getProgress(),
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? 0.0;

                  if (progress > 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97A73),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black.withValues(alpha: 0.5),
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Book title
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),

              // Author name
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          // Selection checkbox overlay
          if (isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: (24 * scale).roundToDouble(),
                height: (24 * scale).roundToDouble(),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFFD97A73)
                          : Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFFD97A73)
                            : Colors.black.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: (16 * scale).roundToDouble(),
                        )
                        : null,
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Get progress from local storage
  Future<double> _getProgress() async {
    try {
      final progress = await ReadingPreferencesService().getProgressPercent(
        book.id,
      );
      return progress;
    } catch (e) {
      return 0.0;
    }
  }
}

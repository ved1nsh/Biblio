import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/book_model.dart';
import 'book_card.dart';

class AllBooksList extends ConsumerWidget {
  final List<Book> books;
  final String sortBy;
  final VoidCallback onSortPressed;
  final String shelfName;
  final String? shelfDescription;
  final bool isSelectionMode;
  final Set<String> selectedBookIds; // String IDs
  final Function(String) onToggleSelection;
  final VoidCallback? onManageShelvesPressed;
  final bool showShelfHeader;

  const AllBooksList({
    super.key,
    required this.books,
    required this.sortBy,
    required this.onSortPressed,
    required this.shelfName,
    this.shelfDescription,
    this.isSelectionMode = false,
    this.selectedBookIds = const <String>{},
    required this.onToggleSelection,
    this.onManageShelvesPressed,
    this.showShelfHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final padH = (24 * scale).clamp(18.0, 24.0);
    final shelfFontSize = (24 * scale).clamp(20.0, 24.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf name and manage shelves button
          if (showShelfHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    shelfName,
                    style: TextStyle(
                      fontSize: shelfFontSize,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (onManageShelvesPressed != null)
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      size: 24,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    onPressed: onManageShelvesPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shelfDescription != null &&
                    shelfDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    shelfDescription!,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Book count and sort button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              TextButton.icon(
                onPressed: onSortPressed,
                icon: Icon(
                  Icons.sort,
                  size: 18,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                label: Text(
                  _getSortLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Books grid - only change here: make cards taller by lowering childAspectRatio
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55, // reduced from 0.65 => taller cards
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(
                book: books[index],
                isSelectionMode: isSelectionMode,
                isSelected: selectedBookIds.contains(books[index].id),
                onToggleSelection: onToggleSelection,
                currentShelf: shelfName,
              );
            },
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (sortBy) {
      case 'title':
        return 'Title';
      case 'author':
        return 'Author';
      case 'date':
      default:
        return 'Recent';
    }
  }
}

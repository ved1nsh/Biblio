import 'package:flutter/material.dart';

// Shows toolbar at top during selection mode with close button, selected count, and action buttons
class SelectionToolbar extends StatelessWidget {
  final int selectedCount;
  final bool isOnAllBooks;
  final VoidCallback onClose;
  final VoidCallback onAddToShelf;
  final VoidCallback onDelete;

  const SelectionToolbar({
    super.key,
    required this.selectedCount,
    required this.isOnAllBooks,
    required this.onClose,
    required this.onAddToShelf,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final countFontSize = (18 * scale).clamp(14.0, 18.0);
    final padH = (24 * scale).clamp(18.0, 24.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 16),
      color: const Color(0xFFFCF9F5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              fontSize: countFontSize,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            color: Colors.brown.shade700,
            onPressed: onAddToShelf,
            tooltip: 'Add to shelf',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade700,
            onPressed: onDelete,
            tooltip: isOnAllBooks ? 'Delete books' : 'Remove from shelf',
          ),
        ],
      ),
    );
  }
}

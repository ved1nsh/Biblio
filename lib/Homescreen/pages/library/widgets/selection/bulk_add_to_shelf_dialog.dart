import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/shelf_provider.dart';
import 'package:biblio/core/providers/book_provider.dart';

class BulkAddToShelfDialog extends ConsumerStatefulWidget {
  final Set<String> selectedBookIds; // String IDs
  final VoidCallback onComplete;

  const BulkAddToShelfDialog({
    super.key,
    required this.selectedBookIds,
    required this.onComplete,
  });

  @override
  ConsumerState<BulkAddToShelfDialog> createState() =>
      _BulkAddToShelfDialogState();
}

class _BulkAddToShelfDialogState extends ConsumerState<BulkAddToShelfDialog> {
  final Set<String> _selectedShelfIds = {};
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _selectedShelfIds.clear();
  }

  void _toggleShelfSelection(String shelfId) {
    setState(() {
      if (_selectedShelfIds.contains(shelfId)) {
        _selectedShelfIds.remove(shelfId);
      } else {
        _selectedShelfIds.add(shelfId);
      }
    });
  }

  Future<void> _performAdd() async {
    final int booksCount = widget.selectedBookIds.length;
    final int shelvesCount = _selectedShelfIds.length;
    if (_selectedShelfIds.isEmpty || booksCount == 0) return;

    final selectedShelves = _selectedShelfIds.toList();
    final selectedBooks = widget.selectedBookIds.toList();

    setState(() => _isAdding = true);

    // Optimistic UI update: pop dialog and clear selection instantly
    widget.onComplete();
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$booksCount book(s) added to $shelvesCount shelf(s)'),
          backgroundColor: Colors.green,
        ),
      );
    }

    try {
      final shelfService = ref.read(shelfServiceProvider);

      // Parallelize all add operations
      final futures = <Future>[];
      for (final shelfId in selectedShelves) {
        for (final bookId in selectedBooks) {
          futures.add(
            shelfService.addBookToShelf(bookId: bookId, shelfId: shelfId),
          );
        }
      }
      await Future.wait(futures);

      // Invalidate all affected shelf providers
      for (final shelfId in selectedShelves) {
        ref.invalidate(booksInShelfProvider(shelfId));
      }
      ref.invalidate(allShelvesProvider);
      ref.invalidate(
        allBooksProvider,
      ); // Update books for local shelfIds mapping
    } catch (e) {
      debugPrint('Failed to add books to shelf: $e');
    }
  }

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    if (hex.length == 8) return Color(int.tryParse("0x$hex") ?? 0xFF9E9E9E);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headingSize = (18 * scale).clamp(14.0, 18.0);
    final padH = (24 * scale).clamp(18.0, 24.0);

    final shelvesAsync = ref.watch(allShelvesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF9F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: shelvesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error: $err')),
            data: (shelves) {
              return Column(
                children: [
                  // Centered heading only (removed book count)
                  Padding(
                    padding: EdgeInsets.fromLTRB(padH, 18, padH, 8),
                    child: Center(
                      child: Text(
                        'Add to Shelfs',
                        style: TextStyle(
                          fontSize: headingSize,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Shelves list with checkboxes
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 0,
                      ),
                      itemCount: shelves.length,
                      itemBuilder: (context, index) {
                        final shelf = shelves[index];
                        final isSelected = _selectedShelfIds.contains(shelf.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _toggleShelfSelection(shelf.id),
                          title: Text(
                            shelf.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'SF-UI-Display',
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          secondary: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseColor(shelf.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
                  ),

                  // Action buttons (Cancel / Add)
                  Padding(
                    padding: EdgeInsets.fromLTRB(padH, 12, padH, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'SF-UI-Display',
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                (_selectedShelfIds.isEmpty || _isAdding)
                                    ? null
                                    : _performAdd,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD97A73),
                              disabledBackgroundColor: const Color(
                                0xFFD97A73,
                              ).withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isAdding
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      'Add',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'SF-UI-Display',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

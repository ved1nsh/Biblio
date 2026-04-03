import 'package:biblio/Homescreen/pages/library/shelf%20widgets/create_shelf_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/shelf_provider.dart';

class AddToShelfDialog extends ConsumerStatefulWidget {
  final String bookId; // Supabase book IDs are String
  final String bookTitle;

  const AddToShelfDialog({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  ConsumerState<AddToShelfDialog> createState() => _AddToShelfDialogState();
}

class _AddToShelfDialogState extends ConsumerState<AddToShelfDialog> {
  Set<String> selectedShelfIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingShelves();
  }

  Future<void> _loadExistingShelves() async {
    // Get shelves that contain this book using Supabase provider
    final shelves = await ref.read(
      shelvesForBookProvider(widget.bookId).future,
    );
    setState(() {
      selectedShelfIds = shelves.map((shelf) => shelf.id).toSet();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (22 * scale).clamp(16.0, 22.0);
    final padAll = (24 * scale).clamp(18.0, 24.0);

    final shelvesAsync = ref.watch(allShelvesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(padAll),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add to Shelf',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.bookTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Shelf list
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFFD97A73)),
              ),
            )
          else
            shelvesAsync.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFD97A73),
                      ),
                    ),
                  ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (shelves) {
                if (shelves.isEmpty) {
                  return _buildEmptyState();
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: shelves.length,
                    itemBuilder: (context, index) {
                      final shelf = shelves[index];
                      final isSelected = selectedShelfIds.contains(shelf.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedShelfIds.add(shelf.id);
                            } else {
                              selectedShelfIds.remove(shelf.id);
                            }
                          });
                        },
                        title: Text(
                          shelf.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle:
                            shelf.description != null
                                ? Text(
                                  shelf.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'SF-UI-Display',
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                )
                                : null,
                        secondary: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(shelf.color.replaceFirst('#', '0xFF')),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        activeColor: const Color(0xFFD97A73),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Create new shelf button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCreateShelfDialog();
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create New Shelf'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD97A73),
              side: const BorderSide(color: Color(0xFFD97A73)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : _saveShelves,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97A73),
                disabledBackgroundColor: const Color(
                  0xFFD97A73,
                ).withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 64,
            color: Colors.black.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No shelves yet',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shelf to organize books',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'SF-UI-Display',
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveShelves() async {
    setState(() => isLoading = true);

    try {
      final shelfService = ref.read(shelfServiceProvider);

      // Get current shelves for this book from Supabase
      final currentShelves = await ref.read(
        shelvesForBookProvider(widget.bookId).future,
      );
      final currentShelfIds = currentShelves.map((s) => s.id).toSet();

      final addedShelfIds = <String>{};
      final removedShelfIds = <String>{};

      // Add to newly selected shelves (parallel)
      final addFutures = <Future>[];
      for (final shelfId in selectedShelfIds) {
        if (!currentShelfIds.contains(shelfId)) {
          addedShelfIds.add(shelfId);
          addFutures.add(
            shelfService.addBookToShelf(
              bookId: widget.bookId,
              shelfId: shelfId,
            ),
          );
        }
      }

      // Remove from unselected shelves (parallel)
      final removeFutures = <Future>[];
      for (final shelfId in currentShelfIds) {
        if (!selectedShelfIds.contains(shelfId)) {
          removedShelfIds.add(shelfId);
          removeFutures.add(
            shelfService.removeBookFromShelf(
              bookId: widget.bookId,
              shelfId: shelfId,
            ),
          );
        }
      }

      await Future.wait([...addFutures, ...removeFutures]);

      // Refresh all affected providers
      for (final shelfId in {...addedShelfIds, ...removedShelfIds}) {
        ref.invalidate(booksInShelfProvider(shelfId));
      }
      ref.invalidate(allShelvesProvider);
      ref.invalidate(shelvesForBookProvider(widget.bookId));

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shelves updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update shelves: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateShelfDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateShelfDialog(),
    );
  }
}

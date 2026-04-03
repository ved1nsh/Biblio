import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/providers/shelf_provider.dart';
import 'package:biblio/Homescreen/pages/library/shelf%20widgets/edit_shelf_dialog.dart';

// Manages shelf-specific actions: show options menu, edit shelf, and delete shelf with confirmation
class ShelfActions {
  static void showShelfOptions(
    BuildContext context,
    WidgetRef ref,
    Shelf shelf,
    Function(String) onShelfDeleted,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFCF9F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Shelf name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(shelf.color.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          shelf.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Edit option
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.black87),
                  title: const Text(
                    'Edit Shelf',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => EditShelfDialog(shelf: shelf),
                    );
                  },
                ),

                // Delete option
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete Shelf',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDeleteConfirmation(context, ref, shelf, onShelfDeleted);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Shelf shelf,
    Function(String) onShelfDeleted,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Shelf?',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${shelf.name}"? Books in this shelf will not be deleted.',
              style: const TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  // Notify parent to switch shelf if needed
                  onShelfDeleted(shelf.name);

                  // Wait for UI to update
                  await Future.delayed(const Duration(milliseconds: 100));

                  final shelfService = ref.read(shelfServiceProvider);
                  await shelfService.deleteShelf(shelf.id);
                  ref.invalidate(allShelvesProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${shelf.name} deleted'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

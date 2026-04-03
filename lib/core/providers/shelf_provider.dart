import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:biblio/core/services/supabase_shelf_service.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/models/book_model.dart';

// Service provider
final shelfServiceProvider = Provider<SupabaseShelfService>((ref) {
  return SupabaseShelfService();
});

// All shelves provider
final allShelvesProvider = FutureProvider<List<Shelf>>((ref) async {
  final service = ref.watch(shelfServiceProvider);
  return await service.getAllShelves();
});

// Books in shelf provider (THIS IS WHAT YOU NEED)
final booksInShelfProvider = FutureProvider.family<List<Book>, String>((
  ref,
  shelfId,
) async {
  final service = ref.watch(shelfServiceProvider);
  return await service.getBooksInShelf(shelfId);
});

// Shelves for book provider
final shelvesForBookProvider = FutureProvider.family<List<Shelf>, String>((
  ref,
  bookId,
) async {
  final service = ref.watch(shelfServiceProvider);
  return await service.getShelvesForBook(bookId);
});

// Selected shelf provider (for cross-widget communication)
final selectedShelfProvider = StateProvider<String>((ref) => 'All Books');

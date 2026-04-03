import 'package:biblio/core/models/book_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:biblio/core/services/supabase_book_service.dart';

// Notifier for currently reading book
class CurrentlyReadingNotifier extends StateNotifier<Book?> {
  CurrentlyReadingNotifier() : super(null);

  void setBook(Book book) {
    state = book;
  }

  void clearBook() {
    state = null;
  }
}

final currentlyReadingProvider =
    StateNotifierProvider<CurrentlyReadingNotifier, Book?>((ref) {
      return CurrentlyReadingNotifier();
    });

// Provider for Supabase book service
final bookServiceProvider = Provider<SupabaseBookService>((ref) {
  return SupabaseBookService();
});

// Provider for all books from Supabase
final allBooksProvider = FutureProvider<List<Book>>((ref) async {
  final service = ref.watch(bookServiceProvider);
  return await service.getAllBooks();
});

// Provider for books by status (e.g., missing files)
final booksByStatusProvider = FutureProvider.family<List<Book>, String>((
  ref,
  status,
) async {
  final service = ref.watch(bookServiceProvider);
  return await service.getBooksByStatus(status);
});

// Provider for searching books
final searchBooksProvider = FutureProvider.family<List<Book>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final service = ref.watch(bookServiceProvider);
  return await service.searchBooks(query);
});

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/services/achievement_service.dart';

class SupabaseShelfService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _achievementService = AchievementService();

  String get _currentUserId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  // ============================================
  // SHELF CRUD OPERATIONS
  // ============================================

  // Create a new shelf
  Future<Shelf> createShelf({
    required String name,
    String? description,
    required String color,
    int orderIndex = 0,
  }) async {
    try {
      final userId = _currentUserId;

      final response =
          await _supabase
              .from('shelves')
              .insert({
                'user_id': userId,
                'name': name,
                'description': description,
                'color': color,
                'order_index': orderIndex,
              })
              .select()
              .single();

      final shelf = Shelf.fromJson(response);

      // ✅ Achievement hooks — fire-and-forget (non-blocking)
      Future(() async {
        try {
          final allShelves = await _supabase
              .from('shelves')
              .select('id')
              .eq('user_id', userId);

          final count = (allShelves as List).length;

          await _achievementService.checkAndUpdateAchievement(
            'librarian',
            count,
          );

          debugPrint('✅ Shelf achievements checked (count: $count)');
        } catch (e) {
          debugPrint('⚠️ Achievement check failed (non-critical): $e');
        }
      });

      return shelf;
    } catch (e) {
      throw Exception('Failed to create shelf: $e');
    }
  }

  // Get all shelves for current user
  Future<List<Shelf>> getAllShelves() async {
    try {
      final userId = _currentUserId;

      final response = await _supabase
          .from('shelves')
          .select()
          .eq('user_id', userId)
          .order('order_index', ascending: true);

      return (response as List).map((json) => Shelf.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch shelves: $e');
    }
  }

  // Update shelf details
  Future<Shelf> updateShelf({
    required String shelfId,
    String? name,
    String? description,
    String? color,
    int? orderIndex,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (color != null) updateData['color'] = color;
      if (orderIndex != null) updateData['order_index'] = orderIndex;

      final response =
          await _supabase
              .from('shelves')
              .update(updateData)
              .eq('id', shelfId)
              .select()
              .single();

      return Shelf.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update shelf: $e');
    }
  }

  // Delete a shelf
  Future<void> deleteShelf(String shelfId) async {
    try {
      await _supabase.from('shelves').delete().eq('id', shelfId);
    } catch (e) {
      throw Exception('Failed to delete shelf: $e');
    }
  }

  // ============================================
  // SHELF-BOOK RELATIONSHIP OPERATIONS
  // ============================================

  // Add book to shelf
  Future<void> addBookToShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      await _supabase.from('shelf_books').insert({
        'shelf_id': shelfId,
        'book_id': bookId,
      });
    } catch (e) {
      throw Exception('Failed to add book to shelf: $e');
    }
  }

  // Remove book from shelf
  Future<void> removeBookFromShelf({
    required String bookId,
    required String shelfId,
  }) async {
    await _supabase
        .from('shelf_books')
        .delete()
        .eq('book_id', bookId)
        .eq('shelf_id', shelfId);
  }

  // Get all books in a shelf
  Future<List<Book>> getBooksInShelf(String shelfId) async {
    try {
      final response = await _supabase
          .from('shelf_books')
          .select('book_id, books(*)')
          .eq('shelf_id', shelfId);

      return (response as List)
          .map((item) => Book.fromJson(item['books']))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch books in shelf: $e');
    }
  }

  // Get all shelves containing a specific book
  Future<List<Shelf>> getShelvesForBook(String bookId) async {
    try {
      final response = await _supabase
          .from('shelf_books')
          .select('shelf_id, shelves(*)')
          .eq('book_id', bookId);

      return (response as List)
          .map((item) => Shelf.fromJson(item['shelves']))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shelves for book: $e');
    }
  }
}

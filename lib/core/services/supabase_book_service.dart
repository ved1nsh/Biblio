import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/services/achievement_service.dart';
import 'package:biblio/core/services/xp_service.dart';

class SupabaseBookService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _achievementService = AchievementService();
  final _xpService = XpService();

  // Get current user ID
  String get _currentUserId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  // ============================================
  // STORAGE OPERATIONS (Book Covers)
  // ============================================

  // Upload book cover to Storage bucket
  // Returns: Public URL of uploaded image
  Future<String> uploadBookCover({
    required String bookId,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  }) async {
    try {
      final userId = _currentUserId;

      // File path: user_id/book_id.jpg
      final filePath = '$userId/$bookId.$fileExtension';

      // Upload to bucket
      await _supabase.storage
          .from('book_covers')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true, // Replace if exists
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('book_covers')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload book cover: $e');
    }
  }

  // Delete book cover from Storage
  Future<void> deleteBookCover(String bookId) async {
    try {
      final userId = _currentUserId;
      final filePath = '$userId/$bookId.jpg';

      await _supabase.storage.from('book_covers').remove([filePath]);
    } catch (e) {
      // Don't throw error if file doesn't exist
    }
  }

  // ============================================
  // CRUD OPERATIONS (Books)
  // ============================================

  // Create a new book
  Future<Book> createBook({
    required String title,
    required String author,
    String? coverUrl,
    String? filePath,
    int totalPages = 0,
    bool isManualEntry = false,
    String? notes,
    String fileStatus = 'available',
    String? fileType,
    String? originalFileName,
  }) async {
    try {
      final userId = _currentUserId;

      final response =
          await _supabase
              .from('books')
              .insert({
                'user_id': userId,
                'title': title,
                'author': author,
                'cover_url': coverUrl,
                'file_path': filePath,
                'total_pages': totalPages,
                'current_page': 0,
                'is_manual_entry': isManualEntry,
                'is_started_reading': false,
                'notes': notes,
                'file_status': fileStatus,
                'file_type': fileType,
                'original_file_name': originalFileName,
              })
              .select()
              .single();

      // ✅ Achievement hooks after successful creation
      try {
        // Ensure profile exists before any gamification logic
        final profileCheck =
            await _supabase
                .from('user_profiles')
                .select('id')
                .eq('user_id', userId)
                .maybeSingle();

        if (profileCheck == null) {
          // Auto-create profile for this user
          await _supabase.from('user_profiles').insert({
            'user_id': userId,
            'total_xp': 0,
            'current_level': 1,
            'streak_savers_available': 1,
            'daily_reading_goal_minutes': 30,
          });
          debugPrint('✅ Auto-created user profile during book creation');

          // Initialize achievement records
          await _achievementService.initializeUserAchievements();
        }

        final allBooks = await _supabase
            .from('books')
            .select('id')
            .eq('user_id', userId);

        final bookCount = (allBooks as List).length;

        // the_architect: Add books to your library (target: 3)
        await _achievementService.checkAndUpdateAchievement(
          'the_architect',
          bookCount,
        );
      } catch (e) {
        debugPrint('⚠️ Achievement check failed (non-critical): $e');
      }

      return Book.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  // Get all books for current user
  Future<List<Book>> getAllBooks() async {
    try {
      final userId = _currentUserId;

      final response = await _supabase
          .from('books')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  // Get a single book by ID
  Future<Book?> getBookById(String bookId) async {
    try {
      final userId = _currentUserId;

      final response =
          await _supabase
              .from('books')
              .select()
              .eq('id', bookId)
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) return null;
      return Book.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch book: $e');
    }
  }

  // Update book details
  Future<Book> updateBook({
    required String bookId,
    String? title,
    String? author,
    String? coverUrl,
    String? filePath,
    int? currentPage,
    int? totalPages,
    bool? isStartedReading,
    String? notes,
    String? fileStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (author != null) updateData['author'] = author;
      if (coverUrl != null) updateData['cover_url'] = coverUrl;
      if (filePath != null) updateData['file_path'] = filePath;
      if (currentPage != null) updateData['current_page'] = currentPage;
      if (totalPages != null) updateData['total_pages'] = totalPages;
      if (isStartedReading != null) {
        updateData['is_started_reading'] = isStartedReading;
      }
      if (notes != null) updateData['notes'] = notes;
      if (fileStatus != null) updateData['file_status'] = fileStatus;

      final response =
          await _supabase
              .from('books')
              .update(updateData)
              .eq('id', bookId)
              .select()
              .single();

      return Book.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Update reading progress
  Future<void> updateReadingProgress({
    required String bookId,
    required int currentPage,
    bool? isStartedReading,
  }) async {
    try {
      await _supabase
          .from('books')
          .update({
            'current_page': currentPage,
            if (isStartedReading != null)
              'is_started_reading': isStartedReading,
          })
          .eq('id', bookId);
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Delete a book (and its cover)
  Future<void> deleteBook(String bookId) async {
    try {
      // Delete cover from storage
      await deleteBookCover(bookId);

      // Delete book from database
      await _supabase.from('books').delete().eq('id', bookId);
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Delete a book from everywhere (shelves and database)
  Future<void> deleteBookEverywhere(String bookId) async {
    // Delete from shelf_books first
    await _supabase.from('shelf_books').delete().eq('book_id', bookId);
    // Then delete from books (and cover if needed)
    await deleteBook(bookId);
  }

  // Get books by file status (e.g., 'missing')
  Future<List<Book>> getBooksByStatus(String status) async {
    try {
      final userId = _currentUserId;

      final response = await _supabase
          .from('books')
          .select()
          .eq('user_id', userId)
          .eq('file_status', status)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch books by status: $e');
    }
  }

  // Search books by title or author
  Future<List<Book>> searchBooks(String query) async {
    try {
      final userId = _currentUserId;

      final response = await _supabase
          .from('books')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,author.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  /// Mark book as finished
  Future<void> markBookFinished(String bookId) async {
    try {
      final userId = _currentUserId;

      // Update book as finished
      await _supabase
          .from('books')
          .update({
            'is_finished': true,
            'finished_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookId)
          .eq('user_id', userId);

      // Award XP for finishing book
      await _xpService.awardXP(
        amount: 150,
        reason: 'Finished a book',
        sourceType: 'book_finish',
        sourceId: bookId,
      );

      // Count total finished books
      final finishedBooks = await _supabase
          .from('books')
          .select('id')
          .eq('user_id', userId)
          .eq('is_finished', true);

      final count = (finishedBooks as List).length;

      // Check achievements
      await _achievementService.checkAndUpdateAchievement(
        'the_finisher',
        count,
      );
      await _achievementService.checkAndUpdateAchievement('bookworm', count);
      await _achievementService.checkAndUpdateAchievement(
        'serial_reader',
        count,
      );

      debugPrint('✅ Book finished, achievements checked (count: $count)');
    } catch (e) {
      debugPrint('❌ Error marking book finished: $e');
    }
  }
}

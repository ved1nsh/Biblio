import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/services/achievement_service.dart';
import 'package:biblio/core/services/xp_service.dart';

class NotebookService {
  final _supabase = Supabase.instance.client;
  final _achievementService = AchievementService();
  final _xpService = XpService();

  // Save a quote to notebook (FULL STYLE, with safe defaults)
  Future<bool> saveQuote({
    required String bookId,
    required String quoteText,
    String? bookTitle,
    String? authorName,
    String fontFamily = 'SF-UI-Display',
    double fontSize = 16,
    bool isBold = false,
    bool isItalic = false,
    String textAlign = 'left',
    String cardAlignment = 'center',
    double lineHeight = 1.5,
    double letterSpacing = 0,
    String backgroundColor = '#FFFFFF',
    String textColor = '#000000',
    bool showAuthor = true,
    bool showBookTitle = true,
    bool showUsername = false,
    double aspectRatio = 1.0,
    String metadataAlign = 'left',
    String cardTheme = 'default',
    String? bookCoverUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      await _supabase.from('user_notebook').insert({
        'user_id': userId,
        'book_id': bookId,
        'quote_text': quoteText,
        'book_title': bookTitle,
        'author_name': authorName,
        'font_family': fontFamily,
        'font_size': fontSize,
        'is_bold': isBold,
        'is_italic': isItalic,
        'text_align': textAlign,
        'card_alignment': cardAlignment,
        'line_height': lineHeight,
        'letter_spacing': letterSpacing,
        'background_color': backgroundColor,
        'text_color': textColor,
        'show_author': showAuthor,
        'show_book_title': showBookTitle,
        'show_username': showUsername,
        'aspect_ratio': aspectRatio,
        'metadata_align': metadataAlign,
        'card_theme': cardTheme,
        if (bookCoverUrl != null) 'book_cover_url': bookCoverUrl,
      });

      // ✅ Achievement hooks after successful save
      try {
        await _xpService.awardXP(
          amount: 5,
          reason: 'Saved a quote',
          sourceType: 'quote_save',
        );

        // Count total quotes
        final allQuotes = await _supabase
            .from('user_notebook')
            .select('id')
            .eq('user_id', userId);

        final count = (allQuotes as List).length;

        await _achievementService.checkAndUpdateAchievement(
          'quote_collector',
          count,
        );
        await _achievementService.checkAndUpdateAchievement(
          'golden_line',
          count,
        );

        debugPrint('✅ Quote achievements checked (count: $count)');
      } catch (e) {
        debugPrint('⚠️ Achievement check failed (non-critical): $e');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error saving quote: $e');
      return false;
    }
  }

  // ✅ ADD this new method - doesn't break existing code
  Future<bool> updateQuote({
    required String quoteId,
    required String quoteText,
    required String bookTitle,
    required String authorName,
    required String fontFamily,
    required double fontSize,
    required bool isBold,
    required bool isItalic,
    required String textAlign,
    required String cardAlignment,
    required double lineHeight,
    required double letterSpacing,
    required String backgroundColor,
    required String textColor,
    required bool showAuthor,
    required bool showBookTitle,
    required bool showUsername,
    required double aspectRatio,
    String metadataAlign = 'left',
    String cardTheme = 'default',
    String? bookCoverUrl,
    String? bookId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final payload = {
        'quote_text': quoteText,
        'book_title': bookTitle,
        'author_name': authorName,
        'font_family': fontFamily,
        'font_size': fontSize,
        'is_bold': isBold,
        'is_italic': isItalic,
        'text_align': textAlign,
        'card_alignment': cardAlignment,
        'line_height': lineHeight,
        'letter_spacing': letterSpacing,
        'background_color': backgroundColor,
        'text_color': textColor,
        'show_author': showAuthor,
        'show_book_title': showBookTitle,
        'show_username': showUsername,
        'aspect_ratio': aspectRatio,
        'metadata_align': metadataAlign,
        'card_theme': cardTheme,
        if (bookCoverUrl != null) 'book_cover_url': bookCoverUrl,
      };

      // 1) Normal update
      final updated = await _supabase
          .from('user_notebook')
          .update(payload)
          .eq('id', quoteId)
          .select('id');

      final updatedRows = List<Map<String, dynamic>>.from(updated);
      if (updatedRows.isNotEmpty) {
        debugPrint('✅ Quote updated: $quoteId');
        return true;
      }

      // 2) Fallback rewrite: delete + insert
      final existing = await _supabase
          .from('user_notebook')
          .select('book_id')
          .eq('id', quoteId)
          .limit(1);

      final existingRows = List<Map<String, dynamic>>.from(existing);
      if (existingRows.isEmpty) {
        debugPrint('❌ updateQuote: row not found for id=$quoteId');
        return false;
      }

      final resolvedBookId =
          (bookId != null && bookId.isNotEmpty)
              ? bookId
              : (existingRows.first['book_id']?.toString() ?? 'unknown');

      final deleted = await _supabase
          .from('user_notebook')
          .delete()
          .eq('id', quoteId)
          .select('id');

      final deletedRows = List<Map<String, dynamic>>.from(deleted);
      if (deletedRows.isEmpty) {
        debugPrint('❌ updateQuote: delete failed for id=$quoteId');
        return false;
      }

      await _supabase.from('user_notebook').insert({
        'user_id': userId,
        'book_id': resolvedBookId,
        ...payload,
      });

      debugPrint('✅ Quote rewritten: $quoteId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating quote: $e');
      return false;
    }
  }

  // Get all saved QUOTES from notebook (excludes journal notes)
  Future<List<Map<String, dynamic>>> getAllQuotes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_notebook')
          .select()
          .eq('user_id', userId)
          .not('quote_text', 'is', null)
          .neq('quote_text', '')
          .order('created_at', ascending: false);

      debugPrint('✅ Fetched ${response.length} quotes from notebook');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching quotes: $e');
      return [];
    }
  }

  // Get quotes for a specific book (UNCHANGED)
  Future<List<Map<String, dynamic>>> getQuotesByBook(String bookId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_notebook')
          .select()
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching quotes for book: $e');
      return [];
    }
  }

  // Delete a quote (UNCHANGED)
  Future<bool> deleteQuote(String quoteId) async {
    try {
      await _supabase.from('user_notebook').delete().eq('id', quoteId);

      debugPrint('✅ Quote deleted: $quoteId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting quote: $e');
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HighlightsService {
  final _supabase = Supabase.instance.client;

  // Save a highlight to Supabase
  Future<bool> saveHighlight({
    required String bookId,
    required String highlightedText,
    required String cfiRange,
    required String cfiStart, // ✅ NEW: precise start point
    String highlightColor = '#FFB74D',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      await _supabase.from('user_highlights').insert({
        'user_id': userId,
        'book_id': bookId,
        'highlighted_text': highlightedText,
        'cfi_range': cfiRange,
        'cfi_start': cfiStart, // ✅ NEW: store the start point
        'highlight_color': highlightColor,
      });

      debugPrint('✅ Highlight saved: $highlightedText');
      debugPrint('   CFI Range: $cfiRange');
      debugPrint('   CFI Start: $cfiStart'); // ✅ NEW log
      return true;
    } catch (e) {
      debugPrint('❌ Error saving highlight: $e');
      return false;
    }
  }

  // Get all highlights for a specific book
  Future<List<Map<String, dynamic>>> getHighlightsByBook(String bookId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_highlights')
          .select()
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .order('created_at', ascending: true);

      debugPrint('✅ Fetched ${response.length} highlights for book: $bookId');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching highlights: $e');
      return [];
    }
  }

  // Delete a highlight
  Future<bool> deleteHighlight(String highlightId) async {
    try {
      await _supabase.from('user_highlights').delete().eq('id', highlightId);

      debugPrint('✅ Highlight deleted: $highlightId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting highlight: $e');
      return false;
    }
  }

  // Get all highlights across all books (for a future "All Highlights" page)
  Future<List<Map<String, dynamic>>> getAllHighlights() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_highlights')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching all highlights: $e');
      return [];
    }
  }
}

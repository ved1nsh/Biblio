import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

/// Handles uploading scanned quote images to Supabase Storage
/// and saving a reference in the user_notebook table.
class ImageQuoteService {
  final _supabase = Supabase.instance.client;

  /// The Supabase Storage bucket name for scanned quote images.
  static const _bucketName = 'scanned-quotes';

  String get _currentUserId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    return userId;
  }

  /// Uploads the image to Supabase Storage and saves a record
  /// in user_notebook with the image URL.
  ///
  /// Returns `true` on success.
  Future<bool> saveImageQuote({
    required String imagePath,
    required String bookId,
    String? bookTitle,
    String? authorName,
    String? bookCoverUrl,
  }) async {
    try {
      final userId = _currentUserId;

      // 1) Upload image to Supabase Storage
      final file = File(imagePath);
      final ext = p.extension(imagePath).replaceAll('.', '');
      final storagePath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from(_bucketName)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2) Get the public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      // 3) Save to user_notebook with image_url (store the image URL in
      //    quote_text prefixed with [IMAGE] so the notebook knows it's an image)
      await _supabase.from('user_notebook').insert({
        'user_id': userId,
        'book_id': bookId,
        'quote_text': '[IMAGE]$publicUrl',
        'book_title': bookTitle,
        'author_name': authorName,
        'font_family': 'SF-UI-Display',
        'font_size': 16,
        'is_bold': false,
        'is_italic': false,
        'text_align': 'left',
        'card_alignment': 'center',
        'line_height': 1.5,
        'letter_spacing': 0,
        'background_color': '#FFFFFF',
        'text_color': '#000000',
        'show_author': true,
        'show_book_title': true,
        'show_username': false,
        'aspect_ratio': 1.0,
        'metadata_align': 'left',
        'card_theme': 'default',
        if (bookCoverUrl != null) 'book_cover_url': bookCoverUrl,
      });

      debugPrint('✅ Image quote saved: $publicUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving image quote: $e');
      return false;
    }
  }
}

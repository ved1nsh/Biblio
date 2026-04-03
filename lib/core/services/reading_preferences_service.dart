import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingPreferencesService {
  static final ReadingPreferencesService _instance =
      ReadingPreferencesService._internal();
  factory ReadingPreferencesService() => _instance;
  ReadingPreferencesService._internal();

  static const String _keyPrefix = 'book_settings_';

  // Save all book data (CFI, progress, theme settings)
  Future<void> saveBookSettings({
    required String bookId,
    required String? cfi,
    required double progress,
    required Map<String, dynamic> themeSettings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$bookId';

    final existing = await loadBookSettings(bookId) ?? {};

    final data = <String, dynamic>{
      ...existing,
      ...themeSettings,
      'current_cfi': cfi ?? existing['current_cfi'],
      'progress_percent': progress,
    };

    await prefs.setString(key, jsonEncode(data));
  }

  // Load book settings (returns null if not found)
  Future<Map<String, dynamic>?> loadBookSettings(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$bookId';

    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // Get current CFI for a book
  Future<String?> getCurrentCfi(String bookId) async {
    final settings = await loadBookSettings(bookId);
    return settings?['current_cfi'] as String?;
  }

  // Get progress percent for a book
  Future<double> getProgressPercent(String bookId) async {
    final settings = await loadBookSettings(bookId);
    return settings?['progress_percent'] as double? ?? 0.0;
  }

  // Get theme settings for a book
  Future<Map<String, dynamic>> getThemeSettings(String bookId) async {
    final settings = await loadBookSettings(bookId);
    if (settings == null) {
      return _getDefaultThemeSettings();
    }

    return {
      'font_family': settings['font_family'] ?? 'Bookerly',
      'font_size': settings['font_size'] ?? 18,
      'line_height': settings['line_height'] ?? 1.5,
      'letter_spacing': settings['letter_spacing'] ?? 0.0,
      'text_align': settings['text_align'] ?? 'left',
      'is_dark_mode': settings['is_dark_mode'] ?? false,
    };
  }

  // Clear settings for a specific book
  Future<void> clearBookSettings(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$bookId';
    await prefs.remove(key);
  }

  // Clear all book settings (for logout/reset)
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Map<String, dynamic> _getDefaultThemeSettings() {
    return {
      'font_family': 'Bookerly',
      'font_size': 18,
      'line_height': 1.5,
      'letter_spacing': 0.0,
      'text_align': 'left',
      'is_dark_mode': false,
    };
  }
}

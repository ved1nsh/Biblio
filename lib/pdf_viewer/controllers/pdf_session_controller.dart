import 'dart:async';
import 'package:flutter/material.dart';
import 'package:biblio/core/services/reading_preferences_service.dart';
import 'package:biblio/core/services/supabase_stats_service.dart';
import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';

/// Manages PDF reading session state: auto-save, progress tracking,
/// and session persistence to Supabase. Modeled after EpubSessionController
/// but uses page numbers instead of CFI strings.
class PdfSessionController {
  final String bookId;
  final String bookTitle;
  final ReadingTimerController timerController;

  Timer? _autoSaveTimer;

  /// Last saved page (from SharedPreferences restore)
  int savedPage = 0;

  /// Last tracked page during this session
  int lastTrackedPage = 0;

  /// Total pages in the PDF
  int totalPages = 0;

  bool hasLoadedSettings = false;
  int _persistedSessionSeconds = 0;
  Future<void> _pendingSave = Future.value();

  PdfSessionController({
    required this.bookId,
    required this.bookTitle,
    required this.timerController,
  });

  /// Queue an auto-save with 2-second debounce.
  /// Called whenever the page changes.
  void queueAutoSave({
    required int currentPage,
    required double progress,
    required bool isDarkMode,
  }) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () async {
      savedPage = currentPage;

      await ReadingPreferencesService().saveBookSettings(
        bookId: bookId,
        cfi: 'pdf-page-$currentPage',
        progress: progress,
        themeSettings: {
          'is_dark_mode': isDarkMode,
          'current_page': currentPage,
        },
      );

      debugPrint('💾 PDF Auto-saved page: $currentPage');
    });
  }

  /// Save the full reading session to Supabase (called on back-press after mood dialog).
  Future<void> saveSession({
    required String mood,
    required bool isDarkMode,
  }) async {
    _pendingSave = _pendingSave.then((_) async {
      final sessionData = timerController.getSessionData();
      final newSessionSeconds = sessionData.duration - _persistedSessionSeconds;

      final pageToSave = lastTrackedPage > 0 ? lastTrackedPage : savedPage;
      final progressToSave = sessionData.progress;

      debugPrint('🔵 SAVING PDF SESSION:');
      debugPrint('   Book: $bookTitle');
      debugPrint('   Duration: ${sessionData.duration} seconds');
      debugPrint('   New Duration To Persist: $newSessionSeconds seconds');
      debugPrint('   Page: $pageToSave / $totalPages');
      debugPrint('   Progress Gained: ${sessionData.progressGained}');
      debugPrint('   Mood: $mood');

      try {
        if (newSessionSeconds > 0) {
          await SupabaseStatsService().saveReadingSession(
            bookId: bookId,
            bookTitle: bookTitle,
            durationSeconds: newSessionSeconds,
            progressGained: sessionData.progressGained,
            moodEmoji: mood,
          );

          debugPrint('✅ Supabase stats saved');

          await SupabaseStatsService().updateBookProgress(
            bookId: bookId,
            cfi: 'pdf-page-$pageToSave',
            progressPercent: progressToSave,
            readSeconds: newSessionSeconds,
          );

          debugPrint('✅ Book progress updated');
          _persistedSessionSeconds = sessionData.duration;
        } else {
          debugPrint('ℹ️ No new reading time to persist');
        }

        await ReadingPreferencesService().saveBookSettings(
          bookId: bookId,
          cfi: 'pdf-page-$pageToSave',
          progress: progressToSave,
          themeSettings: {
            'is_dark_mode': isDarkMode,
            'current_page': pageToSave,
          },
        );

        debugPrint('✅ PDF session saved successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ ERROR SAVING PDF SESSION: $e');
        debugPrint('Stack trace: $stackTrace');

        // Fallback: at least save locally
        await ReadingPreferencesService().saveBookSettings(
          bookId: bookId,
          cfi: 'pdf-page-$pageToSave',
          progress: progressToSave,
          themeSettings: {
            'is_dark_mode': isDarkMode,
            'current_page': pageToSave,
          },
        );
      }
    });

    await _pendingSave;
  }

  /// Emergency save on app crash/background
  Future<void> saveSessionOnCrash({required bool isDarkMode}) async {
    await saveSession(mood: '😐', isDarkMode: isDarkMode);
  }

  void dispose() {
    _autoSaveTimer?.cancel();
  }
}

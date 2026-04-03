import 'dart:async';
import 'package:flutter/material.dart';
import 'package:biblio/core/services/reading_preferences_service.dart';
import 'package:biblio/core/services/supabase_stats_service.dart';
import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';

class EpubSessionController {
  final String bookId;
  final String bookTitle;
  final ReadingTimerController timerController;

  Timer? _autoSaveTimer;
  String? savedCfi;
  String? lastTrackedCfi;
  bool hasLoadedSettings = false;
  bool hasJumpedToSavedPosition = false;
  bool hasRestoredHighlights =
      false; // ✅ NEW flag to track if highlights have been restored
  int _persistedSessionSeconds = 0;
  Future<void> _pendingSave = Future.value();
  EpubSessionController({
    required this.bookId,
    required this.bookTitle,
    required this.timerController,
  });

  void queueAutoSave({
    required String? cfi,
    required double progress,
    required Map<String, dynamic> themeSettings,
  }) {
    if (cfi == null) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () async {
      savedCfi = cfi;

      await ReadingPreferencesService().saveBookSettings(
        bookId: bookId,
        cfi: cfi,
        progress: progress,
        themeSettings: themeSettings,
      );

      debugPrint('💾 Auto-saved CFI: $cfi');
    });
  }

  Future<void> saveSession({
    required String mood,
    required Map<String, dynamic> themeSettings,
  }) async {
    _pendingSave = _pendingSave.then((_) async {
      final sessionData = timerController.getSessionData();
      final newSessionSeconds = sessionData.duration - _persistedSessionSeconds;

      final cfiToSave = lastTrackedCfi ?? sessionData.cfi ?? savedCfi;
      final progressToSave = sessionData.progress;

      debugPrint('🔵 SAVING SESSION:');
      debugPrint('   Book: $bookTitle');
      debugPrint('   Duration: ${sessionData.duration} seconds');
      debugPrint('   New Duration To Persist: $newSessionSeconds seconds');
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
            cfi: cfiToSave,
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
          cfi: cfiToSave,
          progress: progressToSave,
          themeSettings: themeSettings,
        );

        debugPrint('✅ Session saved successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ ERROR SAVING SESSION: $e');
        debugPrint('Stack trace: $stackTrace');

        await ReadingPreferencesService().saveBookSettings(
          bookId: bookId,
          cfi: cfiToSave,
          progress: progressToSave,
          themeSettings: themeSettings,
        );
      }
    });

    await _pendingSave;
  }

  Future<void> saveSessionOnCrash({
    required Map<String, dynamic> themeSettings,
  }) async {
    await saveSession(mood: '😐', themeSettings: themeSettings);
  }

  void dispose() {
    _autoSaveTimer?.cancel();
  }
}

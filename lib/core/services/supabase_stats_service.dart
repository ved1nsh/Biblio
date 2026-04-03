import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_reading_stats_model.dart';
import 'package:biblio/core/services/achievement_service.dart';
import 'package:biblio/core/services/xp_service.dart';
import 'package:biblio/core/services/notification_service.dart';

class SupabaseStatsService {
  static final SupabaseStatsService _instance =
      SupabaseStatsService._internal();
  factory SupabaseStatsService() => _instance;
  SupabaseStatsService._internal();

  final _supabase = Supabase.instance.client;
  final _achievementService = AchievementService();
  final _xpService = XpService();
  final _notificationService = NotificationService();

  // Save a reading session - updates daily stats and book progress
  Future<void> saveReadingSession({
    required String bookId,
    required String bookTitle,
    required int durationSeconds,
    required double progressGained,
    String? moodEmoji,
  }) async {
    debugPrint('🔵 saveReadingSession called');

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    debugPrint('   User ID: $userId');
    debugPrint('   Date: $todayStr');
    debugPrint('   Duration: $durationSeconds seconds');

    // Create book entry for this session
    final bookEntry = {
      'book_id': bookId,
      'book_title': bookTitle,
      'duration_seconds': durationSeconds,
      'progress_gained': progressGained,
      'mood_emoji': moodEmoji,
    };

    debugPrint('   Book entry: $bookEntry');

    // Check if today's stats exist
    final existing =
        await _supabase
            .from('daily_reading_stats')
            .select()
            .eq('user_id', userId)
            .eq('date', todayStr)
            .maybeSingle();

    debugPrint('   Existing row: ${existing != null ? "FOUND" : "NOT FOUND"}');

    if (existing != null) {
      // Update existing row
      final currentBooksRead = List<Map<String, dynamic>>.from(
        existing['books_read'] as List<dynamic>,
      );
      currentBooksRead.add(bookEntry);

      final oldTotal = existing['total_seconds'] as int;
      final newTotal = oldTotal + durationSeconds;

      debugPrint('   Updating: $oldTotal → $newTotal seconds');

      await _supabase
          .from('daily_reading_stats')
          .update({
            'total_seconds': newTotal,
            'books_read': currentBooksRead,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);

      debugPrint('✅ Updated existing row');
    } else {
      // Insert new row for today
      debugPrint('   Creating new row for today');

      await _supabase.from('daily_reading_stats').insert({
        'user_id': userId,
        'date': todayStr,
        'total_seconds': durationSeconds,
        'books_read': [bookEntry],
      });

      debugPrint('✅ Inserted new row');
    }

    // Run achievements after the core write completes, without blocking exit.
    unawaited(
      _checkReadingAchievements(
        userId: userId,
        todayStr: todayStr,
        durationSeconds: durationSeconds,
      ).catchError((e) {
        debugPrint('⚠️ Achievement check failed (non-critical): $e');
      }),
    );
  }

  /// Check all reading-related achievements after a session
  Future<void> _checkReadingAchievements({
    required String userId,
    required String todayStr,
    required int durationSeconds,
  }) async {
    // 1. Check Deep Focus (1 hour single session)
    if (durationSeconds >= 3600) {
      await _achievementService.checkAndUpdateAchievement('deep_focus', 1);
    }

    // 2. Get today's total reading time
    final todayStats =
        await _supabase
            .from('daily_reading_stats')
            .select('total_seconds')
            .eq('user_id', userId)
            .eq('date', todayStr)
            .maybeSingle();

    final todayTotalSeconds = todayStats?['total_seconds'] as int? ?? 0;

    // 3. Check daily goal
    final profile = await _xpService.getUserProfile();
    final dailyGoalMinutes = profile?.dailyReadingGoalMinutes ?? 30;
    final dailyGoalSeconds = dailyGoalMinutes * 60;

    if (todayTotalSeconds >= dailyGoalSeconds) {
      final awarded = await _xpService.awardDailyGoalXP();
      if (awarded) {
        await _notificationService.sendDailyGoalAchievedNotification();
        debugPrint('✅ Daily goal XP awarded');
      }
    }

    // 4. Check streak achievements
    final currentStreak = await getCurrentStreak();
    await _achievementService.checkAndUpdateAchievement('spark', currentStreak);
    await _achievementService.checkAndUpdateAchievement(
      'on_fire',
      currentStreak,
    );
    await _achievementService.checkAndUpdateAchievement(
      'committed',
      currentStreak,
    );
    await _achievementService.checkAndUpdateAchievement(
      'centurion',
      currentStreak,
    );

    // 5. Check consecutive daily goal achievements
    final consecutiveDays = await _getConsecutiveDailyGoalDays(
      userId,
      dailyGoalSeconds,
    );
    await _achievementService.checkAndUpdateAchievement(
      'week_warrior',
      consecutiveDays,
    );
    await _achievementService.checkAndUpdateAchievement(
      'month_master',
      consecutiveDays,
    );

    // 6. Broken streak is now handled on the streak page UI
    // (StreakSaverScreen checks and offers restore)

    debugPrint('✅ Reading achievements checked');
  }

  /// Get consecutive days meeting daily goal
  Future<int> _getConsecutiveDailyGoalDays(
    String userId,
    int dailyGoalSeconds,
  ) async {
    try {
      final today = DateTime.now();
      final last60Days = today.subtract(const Duration(days: 60));
      final last60DaysStr = last60Days.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date, total_seconds')
          .eq('user_id', userId)
          .gte('date', last60DaysStr)
          .order('date', ascending: false);

      final records = List<Map<String, dynamic>>.from(response);
      if (records.isEmpty) return 0;

      int consecutive = 0;
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      for (final record in records) {
        final date = DateTime.parse(record['date'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final totalSeconds = record['total_seconds'] as int? ?? 0;

        if (normalizedDate.isAtSameMomentAs(checkDate)) {
          if (totalSeconds >= dailyGoalSeconds) {
            consecutive++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else if (normalizedDate.isBefore(checkDate)) {
          break;
        }
      }

      return consecutive;
    } catch (e) {
      debugPrint('❌ Error calculating consecutive goal days: $e');
      return 0;
    }
  }

  // Update book progress (CFI, progress %, total time)
  Future<void> updateBookProgress({
    required String bookId,
    required String? cfi,
    required double progressPercent,
    required int readSeconds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get current total_read_seconds
    final book =
        await _supabase
            .from('books')
            .select('total_read_seconds')
            .eq('id', bookId)
            .eq('user_id', userId)
            .single();

    final currentTotal = book['total_read_seconds'] as int? ?? 0;

    await _supabase
        .from('books')
        .update({
          'current_cfi': cfi,
          'progress_percent': progressPercent,
          'total_read_seconds': currentTotal + readSeconds,
          'last_read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookId)
        .eq('user_id', userId);
  }

  // Get daily stats for a specific date
  Future<DailyReadingStats?> getDailyStats(DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final dateString = date.toIso8601String().split('T')[0];

    final data =
        await _supabase
            .from('daily_reading_stats')
            .select()
            .eq('user_id', userId)
            .eq('date', dateString)
            .maybeSingle();

    if (data == null) return null;
    return DailyReadingStats.fromJson(data);
  }

  // Get heatmap data (date range of daily stats)
  Future<List<DailyReadingStats>> getHeatmapData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final startString = startDate.toIso8601String().split('T')[0];
    final endString = endDate.toIso8601String().split('T')[0];

    final data = await _supabase
        .from('daily_reading_stats')
        .select()
        .eq('user_id', userId)
        .gte('date', startString)
        .lte('date', endString)
        .order('date', ascending: false);

    return (data as List<dynamic>)
        .map((item) => DailyReadingStats.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Get current reading streak (consecutive days with reading)
  Future<int> getCurrentStreak() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get last 365 days
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final stats = await getHeatmapData(
      startDate: oneYearAgo,
      endDate: DateTime.now(),
    );

    if (stats.isEmpty) return 0;

    // Calculate streak (consecutive days from today backwards)
    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (final stat in stats) {
      final statDate = stat.date;
      final daysDiff = currentDate.difference(statDate).inDays;

      if (daysDiff == streak) {
        // Consecutive day found
        if (stat.totalSeconds > 0) {
          streak++;
          currentDate = statDate;
        } else {
          break; // No reading on this day, streak ends
        }
      } else {
        break; // Gap in dates, streak ends
      }
    }

    return streak;
  }

  // Get total reading time for all books
  Future<int> getTotalReadingTime() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final result = await _supabase
        .from('books')
        .select('total_read_seconds')
        .eq('user_id', userId);

    int total = 0;
    for (final book in result) {
      total += (book['total_read_seconds'] as int?) ?? 0;
    }

    return total;
  }

  // Get reading time for today
  Future<int> getTodayReadingTime() async {
    final today = DateTime.now();
    final stats = await getDailyStats(today);
    return stats?.totalSeconds ?? 0;
  }
}

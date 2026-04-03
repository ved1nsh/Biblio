import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakService {
  final _supabase = Supabase.instance.client;

  /// Calculate current streak (consecutive days with reading activity)
  /// ✅ Fixed: Doesn't count today if no reading yet
  Future<int> calculateCurrentStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final today = _getToday();
      final todayStr = _getTodayString();

      debugPrint('📊 Calculating streak for: $todayStr');

      // Fetch all reading dates ordered by date descending
      final response = await _supabase
          .from('daily_reading_stats')
          .select('date, total_seconds')
          .eq('user_id', userId)
          .gt('total_seconds', 0)
          .lte('date', todayStr)
          .order('date', ascending: false);

      final records = List<Map<String, dynamic>>.from(response);
      if (records.isEmpty) {
        debugPrint('   No reading history found');
        return 0;
      }

      // Parse dates and create a set for quick lookup
      final readingDatesSet =
          records
              .map((r) => DateTime.parse(r['date'] as String))
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet();

      debugPrint('   Found ${readingDatesSet.length} days with reading');

      // ✅ FIX: Start from today if read today, otherwise start from yesterday
      DateTime checkDate;
      if (readingDatesSet.contains(today)) {
        debugPrint('   ✅ Read today, starting from today');
        checkDate = today;
      } else {
        debugPrint('   ⏳ Not read today yet, starting from yesterday');
        checkDate = today.subtract(const Duration(days: 1));
      }

      // Count consecutive days backwards
      int streak = 0;
      while (readingDatesSet.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      debugPrint('✅ Current streak: $streak days');
      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating streak: $e');
      return 0;
    }
  }

  /// Get total reading time for today
  Future<int> getTodayReadingSeconds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user ID');
        return 0;
      }

      final today = _getTodayString();

      debugPrint('🔵 FETCHING today\'s reading:');
      debugPrint('   User ID: $userId');
      debugPrint('   Date: $today');

      final response =
          await _supabase
              .from('daily_reading_stats')
              .select('total_seconds')
              .eq('user_id', userId)
              .eq('date', today)
              .maybeSingle();

      debugPrint('   Response: $response');

      if (response == null) {
        debugPrint('   No data found for today');
        return 0;
      }

      final seconds = response['total_seconds'] as int? ?? 0;
      debugPrint('✅ Found: $seconds seconds');

      return seconds;
    } catch (e) {
      debugPrint('❌ Error fetching today\'s reading: $e');
      return 0;
    }
  }

  /// Get longest streak ever
  Future<int> getLongestStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date')
          .eq('user_id', userId)
          .gt('total_seconds', 0)
          .order('date', ascending: true);

      final records = List<Map<String, dynamic>>.from(response);
      if (records.isEmpty) return 0;

      final dates =
          records.map((r) => DateTime.parse(r['date'] as String)).toList();

      int maxStreak = 0;
      int currentStreak = 1;

      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;

        if (diff == 1) {
          currentStreak++;
        } else {
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
          currentStreak = 1;
        }
      }

      maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;

      debugPrint('✅ Longest streak: $maxStreak days');
      return maxStreak;
    } catch (e) {
      debugPrint('❌ Error calculating longest streak: $e');
      return 0;
    }
  }

  // Helper: Get today's date as YYYY-MM-DD string
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Helper: Get today as DateTime (normalized to midnight)
  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Helper: Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get dates with reading activity within a date range
  Future<Set<DateTime>> getReadingDaysInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final startStr =
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date')
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .gt('total_seconds', 0);

      final records = List<Map<String, dynamic>>.from(response);
      return records.map((r) {
        final d = DateTime.parse(r['date'] as String);
        return DateTime(d.year, d.month, d.day);
      }).toSet();
    } catch (e) {
      debugPrint('❌ Error fetching reading days in range: $e');
      return {};
    }
  }

  /// Get days where streak saver was used (filled with minimal reading)
  /// These are identified by daily_reading_stats entries with total_seconds <= 60
  /// and empty books_read array
  Future<Set<DateTime>> getStreakSaverDays({int months = 4}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months + 1, 1);
      final startStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date, total_seconds, books_read')
          .eq('user_id', userId)
          .gte('date', startStr)
          .order('date', ascending: true);

      final records = List<Map<String, dynamic>>.from(response);
      final Set<DateTime> saverDays = {};

      for (final record in records) {
        final totalSeconds = record['total_seconds'] as int? ?? 0;
        final booksRead = record['books_read'] as List<dynamic>? ?? [];

        // Streak saver days have exactly 60 seconds and empty books_read
        if (totalSeconds == 60 && booksRead.isEmpty) {
          final date = DateTime.parse(record['date'] as String);
          saverDays.add(DateTime(date.year, date.month, date.day));
        }
      }

      debugPrint('✅ Streak saver days: ${saverDays.length}');
      return saverDays;
    } catch (e) {
      debugPrint('❌ Error fetching streak saver days: $e');
      return {};
    }
  }

  /// Fetch reading data for the last N months (for heatmap)
  Future<Map<DateTime, int>> getReadingHeatmapData({int months = 3}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months + 1, 1);
      final startStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date, total_seconds')
          .eq('user_id', userId)
          .gte('date', startStr)
          .order('date', ascending: true);

      final records = List<Map<String, dynamic>>.from(response);
      final Map<DateTime, int> heatmapData = {};

      for (final record in records) {
        final date = DateTime.parse(record['date'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final totalSeconds = record['total_seconds'] as int? ?? 0;
        heatmapData[normalizedDate] = totalSeconds;
      }

      debugPrint('✅ Heatmap data loaded: ${heatmapData.length} days');
      return heatmapData;
    } catch (e) {
      debugPrint('❌ Error fetching heatmap data: $e');
      return {};
    }
  }

  /// Get total all-time reading seconds from daily_reading_stats
  Future<int> getTotalAllTimeSeconds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('daily_reading_stats')
          .select('total_seconds')
          .eq('user_id', userId);

      final records = List<Map<String, dynamic>>.from(response);
      int total = 0;
      for (final r in records) {
        total += (r['total_seconds'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      debugPrint('❌ Error fetching all-time reading: $e');
      return 0;
    }
  }

  /// Get number of days with reading
  Future<int> getTotalDaysRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date')
          .eq('user_id', userId)
          .gt('total_seconds', 0);

      return List<Map<String, dynamic>>.from(response).length;
    } catch (e) {
      debugPrint('❌ Error fetching total days read: $e');
      return 0;
    }
  }

  /// Get detailed reading data for a specific day (books_read array from daily_reading_stats)
  Future<Map<String, dynamic>?> getDayReadingDetails(DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response =
          await _supabase
              .from('daily_reading_stats')
              .select('total_seconds, books_read')
              .eq('user_id', userId)
              .eq('date', dateStr)
              .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Error fetching day reading details: $e');
      return null;
    }
  }

  /// Calculate current goal streak (consecutive days where reading >= goalMinutes)
  Future<int> calculateGoalStreak({required int goalMinutes}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final today = _getToday();
      final todayStr = _getTodayString();
      final goalSeconds = goalMinutes * 60;

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date, total_seconds')
          .eq('user_id', userId)
          .gte('total_seconds', goalSeconds)
          .lte('date', todayStr)
          .order('date', ascending: false);

      final records = List<Map<String, dynamic>>.from(response);
      if (records.isEmpty) return 0;

      final goalDatesSet =
          records
              .map((r) => DateTime.parse(r['date'] as String))
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet();

      DateTime checkDate;
      if (goalDatesSet.contains(today)) {
        checkDate = today;
      } else {
        checkDate = today.subtract(const Duration(days: 1));
      }

      int streak = 0;
      while (goalDatesSet.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      debugPrint('✅ Goal streak ($goalMinutes min): $streak days');
      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating goal streak: $e');
      return 0;
    }
  }

  /// Get longest goal streak ever (consecutive days where reading >= goalMinutes)
  Future<int> getLongestGoalStreak({required int goalMinutes}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final goalSeconds = goalMinutes * 60;

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date')
          .eq('user_id', userId)
          .gte('total_seconds', goalSeconds)
          .order('date', ascending: true);

      final records = List<Map<String, dynamic>>.from(response);
      if (records.isEmpty) return 0;

      final dates =
          records.map((r) => DateTime.parse(r['date'] as String)).toList();

      int maxStreak = 0;
      int currentStreak = 1;

      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
          currentStreak = 1;
        }
      }

      maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      return maxStreak;
    } catch (e) {
      debugPrint('❌ Error calculating longest goal streak: $e');
      return 0;
    }
  }

  /// Get days in range where reading goal was achieved
  Future<Set<DateTime>> getGoalAchievedDaysInRange(
    DateTime start,
    DateTime end, {
    required int goalMinutes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final goalSeconds = goalMinutes * 60;
      final startStr =
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date')
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .gte('total_seconds', goalSeconds);

      final records = List<Map<String, dynamic>>.from(response);
      return records.map((r) {
        final d = DateTime.parse(r['date'] as String);
        return DateTime(d.year, d.month, d.day);
      }).toSet();
    } catch (e) {
      debugPrint('❌ Error fetching goal achieved days: $e');
      return {};
    }
  }

  /// Get per-book reading stats (title + total_read_seconds) from books table
  Future<List<Map<String, dynamic>>> getPerBookReadingTime() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('books')
          .select('title, total_read_seconds, author, cover_url')
          .eq('user_id', userId)
          .gt('total_read_seconds', 0)
          .order('total_read_seconds', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching per-book reading time: $e');
      return [];
    }
  }
}

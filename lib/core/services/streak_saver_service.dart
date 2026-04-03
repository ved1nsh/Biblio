import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/services/xp_service.dart';

class StreakSaverService {
  final _supabase = Supabase.instance.client;
  final _xpService = XpService();

  // ─── Check if streak is broken ──────────────────────────────────────────

  /// Returns a map with keys:
  ///   is_broken      : bool
  ///   last_read_date : DateTime  (only when broken)
  ///   missed_days    : int       (number of gap days, only when broken)
  ///   streak_lost    : int       (the streak that was broken)
  ///   can_restore    : bool      (true if within 3 missed days)
  Future<Map<String, dynamic>?> checkBrokenStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final today = DateTime.now();
      final todayNorm = DateTime(today.year, today.month, today.day);

      // Find the most recent day with reading
      final response =
          await _supabase
              .from('daily_reading_stats')
              .select('date')
              .eq('user_id', userId)
              .gt('total_seconds', 0)
              .order('date', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) {
        // No reading history at all
        return {'is_broken': false};
      }

      final lastReadDate = DateTime.parse(response['date'] as String);
      final lastReadNorm = DateTime(
        lastReadDate.year,
        lastReadDate.month,
        lastReadDate.day,
      );
      final gapDays = todayNorm.difference(lastReadNorm).inDays;

      // If user read today or yesterday, there's no break
      if (gapDays <= 1) {
        return {'is_broken': false};
      }

      // Gap of 2+ days → at least 1 full missed day
      final streakCount = await _getStreakEndingOn(lastReadNorm);
      if (streakCount <= 0) {
        return {'is_broken': false};
      }

      final missedDays = gapDays - 1; // days between last read and today

      debugPrint(
        '⚠️ Streak broken: lost $streakCount-day streak, '
        'missed $missedDays day(s)',
      );

      return {
        'is_broken': true,
        'last_read_date': lastReadNorm,
        'missed_days': missedDays,
        'streak_lost': streakCount,
        'can_restore': missedDays <= 3,
      };
    } catch (e) {
      debugPrint('❌ Error checking broken streak: $e');
      return null;
    }
  }

  // ─── Count consecutive streak ending on a given date ────────────────────

  Future<int> _getStreakEndingOn(DateTime endDate) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final endStr = _dateStr(endDate);

      final response = await _supabase
          .from('daily_reading_stats')
          .select('date')
          .eq('user_id', userId)
          .lte('date', endStr)
          .gt('total_seconds', 0)
          .order('date', ascending: false);

      final records = List<Map<String, dynamic>>.from(response);
      if (records.isEmpty) return 0;

      final dates =
          records.map((r) {
            final d = DateTime.parse(r['date'] as String);
            return DateTime(d.year, d.month, d.day);
          }).toList();

      int streak = 0;
      DateTime checkDate = endDate;

      for (final date in dates) {
        if (date == checkDate) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(checkDate)) {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('❌ _getStreakEndingOn error: $e');
      return 0;
    }
  }

  // ─── Restore broken streak ─────────────────────────────────────────────

  /// Fills all missed gap days with a minimal reading record (60 s)
  /// and deducts either a free saver or 100 XP.
  Future<bool> restoreStreak(bool useFreeStreak) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final brokenInfo = await checkBrokenStreak();
      if (brokenInfo == null || brokenInfo['is_broken'] != true) return false;
      if (brokenInfo['can_restore'] != true) return false;

      final lastReadDate = brokenInfo['last_read_date'] as DateTime;
      final missedDays = brokenInfo['missed_days'] as int;
      if (missedDays <= 0) return false;

      final profile = await _xpService.getUserProfile();
      if (profile == null) return false;

      // Deduct resource
      if (useFreeStreak) {
        if (profile.streakSaversAvailable <= 0) {
          debugPrint('❌ No free streak savers available');
          return false;
        }
        await _supabase
            .from('user_profiles')
            .update({
              'streak_savers_available': profile.streakSaversAvailable - 1,
            })
            .eq('user_id', userId);
      } else {
        final success = await _xpService.deductXP(
          amount: 100,
          reason: 'Streak restoration',
        );
        if (!success) {
          debugPrint('❌ Insufficient XP');
          return false;
        }
      }

      // Fill every missed day
      final today = DateTime.now();
      final todayNorm = DateTime(today.year, today.month, today.day);

      for (int i = 1; i <= missedDays; i++) {
        final fillDate = lastReadDate.add(Duration(days: i));
        if (fillDate.isBefore(todayNorm)) {
          await _supabase.from('daily_reading_stats').upsert({
            'user_id': userId,
            'date': _dateStr(fillDate),
            'total_seconds': 60,
            'books_read': [],
          });
        }
      }

      // Log the save (best-effort, table may not exist yet)
      try {
        await _supabase.from('streak_saves').insert({
          'user_id': userId,
          'date_saved': _dateStr(DateTime.now()),
          'xp_cost': useFreeStreak ? 0 : 100,
          'method_used': useFreeStreak ? 'free_saver' : 'xp_purchase',
        });
      } catch (_) {}

      debugPrint(
        '✅ Streak restored (filled $missedDays day(s)) '
        'using ${useFreeStreak ? "free saver" : "100 XP"}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ restoreStreak error: $e');
      return false;
    }
  }

  // ─── Get available streak savers ────────────────────────────────────────

  Future<int> getAvailableSavers() async {
    try {
      final profile = await _xpService.getUserProfile();
      return profile?.streakSaversAvailable ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

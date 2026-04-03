import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/achievement_model.dart';
import 'package:biblio/core/services/xp_service.dart';
import 'package:biblio/core/services/streak_service.dart';

class AchievementService {
  final _supabase = Supabase.instance.client;
  final _xpService = XpService();
  final _streakService = StreakService();

  /// ✅ NEW: Check all achievements against current user data
  Future<void> checkAllAchievementsRetroactively() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      debugPrint('🔍 Checking achievements retroactively...');

      // Get user stats
      final booksAdded = await _getBooksAddedCount();
      final booksRead = await _getCompletedBooksCount();
      final shelves = await _getShelvesCount();
      final highlights = await _getHighlightsCount();
      final currentStreak = await _getCurrentStreak();

      // Check library achievements (books added)
      await checkAndUpdateAchievement(
        'the_architect',
        booksAdded,
      ); // 3 books added

      // Check reading achievements (books finished)
      await checkAndUpdateAchievement('the_finisher', booksRead); // 1 book
      await checkAndUpdateAchievement('bookworm', booksRead); // 5 books
      await checkAndUpdateAchievement('serial_reader', booksRead); // 10 books

      // Check shelf achievements
      await checkAndUpdateAchievement('librarian', shelves); // 5 shelves

      // Check quote achievements
      await checkAndUpdateAchievement(
        'quote_collector',
        highlights,
      ); // 10 highlights
      await checkAndUpdateAchievement(
        'golden_line',
        highlights,
      ); // 50 highlights

      // Check streak achievements
      await checkAndUpdateAchievement('spark', currentStreak); // 3 days
      await checkAndUpdateAchievement('on_fire', currentStreak); // 7 days
      await checkAndUpdateAchievement('committed', currentStreak); // 30 days
      await checkAndUpdateAchievement('centurion', currentStreak); // 100 days

      debugPrint('✅ Retroactive achievement check complete!');
    } catch (e) {
      debugPrint('❌ Error checking achievements retroactively: $e');
    }
  }

  /// Get total books added to library
  Future<int> _getBooksAddedCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('books')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting books added count: $e');
      return 0;
    }
  }

  /// Get completed books count (is_finished = true)
  Future<int> _getCompletedBooksCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('books')
          .select('id')
          .eq('user_id', userId)
          .eq('is_finished', true);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting completed books count: $e');
      return 0;
    }
  }

  /// Get shelves count
  Future<int> _getShelvesCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('shelves')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting shelves count: $e');
      return 0;
    }
  }

  /// Get highlights/quotes count (user_highlights + user_notebook)
  Future<int> _getHighlightsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Count from user_highlights
      final highlights = await _supabase
          .from('user_highlights')
          .select('id')
          .eq('user_id', userId);

      // Also count from user_notebook (quotes)
      final notebook = await _supabase
          .from('user_notebook')
          .select('id')
          .eq('user_id', userId);

      return (highlights as List).length + (notebook as List).length;
    } catch (e) {
      debugPrint('❌ Error getting highlights count: $e');
      return 0;
    }
  }

  /// Get current streak (calculated from daily_reading_stats)
  Future<int> _getCurrentStreak() async {
    try {
      return await _streakService.calculateCurrentStreak();
    } catch (e) {
      debugPrint('❌ Error getting current streak: $e');
      return 0;
    }
  }

  /// Check and update achievement progress, unlock if target met
  Future<void> checkAndUpdateAchievement(
    String achievementId,
    int newProgress,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      // Get or create user achievement record
      var userAchievement = await _getUserAchievement(achievementId);

      if (userAchievement == null) {
        // Create new record
        await _supabase.from('user_achievements').insert({
          'user_id': userId,
          'achievement_id': achievementId,
          'current_progress': newProgress,
          'is_unlocked': false,
        });
        userAchievement = await _getUserAchievement(achievementId);
      }

      if (userAchievement == null || userAchievement.isUnlocked) {
        return; // Already unlocked or error
      }

      // Update progress
      final updatedProgress =
          newProgress > userAchievement.currentProgress
              ? newProgress
              : userAchievement.currentProgress;

      await _supabase
          .from('user_achievements')
          .update({'current_progress': updatedProgress})
          .eq('user_id', userId)
          .eq('achievement_id', achievementId);

      // Check if target met
      final achievement = await _getAchievement(achievementId);
      if (achievement == null) {
        debugPrint('⏭️ Achievement definition missing for: $achievementId');
        return;
      }

      if (updatedProgress >= achievement.targetValue) {
        await _unlockAchievement(achievementId, achievement);
      }
    } catch (e) {
      debugPrint('❌ Error checking achievement: $e');
    }
  }

  /// Unlock achievement, award XP, send notification
  Future<void> _unlockAchievement(
    String achievementId,
    Achievement achievement,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Only one caller should be able to flip this row to unlocked.
      final unlockedRow =
          await _supabase
              .from('user_achievements')
              .update({
                'is_unlocked': true,
                'unlocked_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .eq('achievement_id', achievementId)
              .eq('is_unlocked', false)
              .select('id')
              .maybeSingle();

      if (unlockedRow == null) {
        debugPrint('⏭️ Achievement already unlocked: ${achievement.title}');
        return;
      }

      // Award XP
      await _xpService.awardXP(
        amount: achievement.xpReward,
        reason: 'Achievement unlocked: ${achievement.title}',
        sourceType: 'achievement',
        sourceId: achievementId,
      );

      // Send notification
      await _sendAchievementNotification(achievement);

      debugPrint('🏆 Achievement unlocked: ${achievement.title}');
    } catch (e) {
      debugPrint('❌ Error unlocking achievement: $e');
    }
  }

  /// Send achievement notification
  Future<void> _sendAchievementNotification(Achievement achievement) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'type': 'achievement',
        'title': 'Achievement Unlocked! 🏆',
        'message': '${achievement.title} - +${achievement.xpReward} XP',
        'data': {
          'achievement_id': achievement.id,
          'xp_reward': achievement.xpReward,
        },
        'is_read': false,
        'requires_action': false,
      });

      debugPrint('✅ Achievement notification sent');
    } catch (e) {
      debugPrint('❌ Error sending achievement notification: $e');
    }
  }

  /// Get user achievement record
  Future<UserAchievement?> _getUserAchievement(String achievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response =
          await _supabase
              .from('user_achievements')
              .select('*, achievements(*)')
              .eq('user_id', userId)
              .eq('achievement_id', achievementId)
              .maybeSingle();

      if (response == null) return null;

      return UserAchievement.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error fetching user achievement: $e');
      return null;
    }
  }

  /// Get achievement definition
  Future<Achievement?> _getAchievement(String achievementId) async {
    try {
      final response =
          await _supabase
              .from('achievements')
              .select()
              .eq('id', achievementId)
              .maybeSingle();

      if (response == null) return null;

      return Achievement.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error fetching achievement: $e');
      return null;
    }
  }

  /// Get all unlocked achievements
  Future<List<UserAchievement>> getUnlockedAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .eq('is_unlocked', true)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((item) => UserAchievement.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching unlocked achievements: $e');
      return [];
    }
  }

  /// Get all locked achievements
  Future<List<UserAchievement>> getLockedAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get all achievements
      final allAchievements = await _supabase.from('achievements').select();

      // Get user's achievements
      final userAchievements = await _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', userId);

      final userAchievementMap = {
        for (var ua in userAchievements) ua['achievement_id']: ua,
      };

      // Build locked list
      final locked = <UserAchievement>[];

      for (var achievement in allAchievements) {
        final achievementId = achievement['id'] as String;
        final userAch = userAchievementMap[achievementId];

        if (userAch == null || userAch['is_unlocked'] == false) {
          // Create or use existing record
          locked.add(
            UserAchievement(
              id: userAch?['id'] ?? '',
              userId: userId,
              achievementId: achievementId,
              currentProgress: userAch?['current_progress'] ?? 0,
              isUnlocked: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              achievement: Achievement.fromMap(achievement),
            ),
          );
        }
      }

      return locked;
    } catch (e) {
      debugPrint('❌ Error fetching locked achievements: $e');
      return [];
    }
  }

  /// Mark achievement as viewed (prevent confetti replay)
  Future<void> markAchievementViewed(String achievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_achievements')
          .update({'viewed_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('achievement_id', achievementId);

      debugPrint('✅ Achievement marked as viewed');
    } catch (e) {
      debugPrint('❌ Error marking achievement viewed: $e');
    }
  }

  /// Mark confetti as shown for user achievement (uses viewed_at column)
  Future<void> markConfettiShown(String userAchievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_achievements')
          .update({'viewed_at': DateTime.now().toIso8601String()})
          .eq('id', userAchievementId)
          .eq('user_id', userId);

      debugPrint('✅ Confetti marked as shown for achievement');
    } catch (e) {
      debugPrint('❌ Error marking confetti shown: $e');
    }
  }

  /// Get achievement progress
  Future<Map<String, int>> getAchievementProgress(String achievementId) async {
    try {
      final userAchievement = await _getUserAchievement(achievementId);
      final achievement = await _getAchievement(achievementId);

      if (userAchievement == null || achievement == null) {
        return {'current': 0, 'target': 1};
      }

      return {
        'current': userAchievement.currentProgress,
        'target': achievement.targetValue,
      };
    } catch (e) {
      debugPrint('❌ Error getting achievement progress: $e');
      return {'current': 0, 'target': 1};
    }
  }

  /// Initialize all achievements for a user (creates missing rows)
  Future<void> initializeUserAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get all achievements from the master table
      final achievements = await _supabase.from('achievements').select('id');

      // Get existing user achievement records
      final existingRecords = await _supabase
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);

      final existingIds =
          (existingRecords as List)
              .map((r) => r['achievement_id'] as String)
              .toSet();

      // Find missing achievement IDs
      final allIds =
          (achievements as List).map((a) => a['id'] as String).toList();
      final missingIds =
          allIds.where((id) => !existingIds.contains(id)).toList();

      if (missingIds.isEmpty) {
        debugPrint(
          '✅ All ${allIds.length} achievements already initialized for user',
        );
        return;
      }

      // Batch insert missing achievements
      final inserts =
          missingIds
              .map(
                (id) => {
                  'user_id': userId,
                  'achievement_id': id,
                  'current_progress': 0,
                  'is_unlocked': false,
                },
              )
              .toList();

      await _supabase.from('user_achievements').insert(inserts);

      debugPrint(
        '✅ Initialized ${missingIds.length} missing achievements (total: ${allIds.length})',
      );
    } catch (e) {
      debugPrint('❌ Error initializing achievements: $e');
    }
  }
}

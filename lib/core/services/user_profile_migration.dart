import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/services/achievement_service.dart';

class UserProfileMigration {
  final _supabase = Supabase.instance.client;
  final _achievementService = AchievementService();

  /// Ensure user profile exists, create if not
  Future<void> ensureUserProfileExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      // Check if profile exists
      final existing =
          await _supabase
              .from('user_profiles')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (existing != null) {
        debugPrint('✅ User profile already exists');
        return;
      }

      // Create new profile with defaults
      await _supabase.from('user_profiles').insert({
        'user_id': userId,
        'total_xp': 0,
        'current_level': 1,
        'streak_savers_available': 1, // Free streak saver for new users
        'daily_reading_goal_minutes': 30, //
      });

      debugPrint('✅ User profile created with default values');

      // Initialize all achievements for new user
      await _achievementService.initializeUserAchievements();

      debugPrint('✅ User achievements initialized');
    } catch (e) {
      debugPrint('❌ Error ensuring user profile: $e');
    }
  }

  /// Reset user profile (for testing purposes)
  Future<void> resetUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Delete existing profile
      await _supabase.from('user_profiles').delete().eq('user_id', userId);

      // Delete all user achievements
      await _supabase.from('user_achievements').delete().eq('user_id', userId);

      // Delete all XP transactions
      await _supabase.from('xp_transactions').delete().eq('user_id', userId);

      // Delete all notifications
      await _supabase.from('user_notifications').delete().eq('user_id', userId);

      // Delete all streak saves
      await _supabase.from('streak_saves').delete().eq('user_id', userId);

      debugPrint('✅ User profile reset complete');

      // Re-create profile
      await ensureUserProfileExists();
    } catch (e) {
      debugPrint('❌ Error resetting user profile: $e');
    }
  }
}

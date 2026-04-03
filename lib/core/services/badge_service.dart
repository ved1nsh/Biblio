import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/achievement_model.dart';

class BadgeService {
  final _supabase = Supabase.instance.client;

  /// Set user's display badge
  Future<void> setDisplayBadge(String achievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      // Verify achievement is unlocked
      final userAchievement = await _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .eq('is_unlocked', true)
          .maybeSingle();

      if (userAchievement == null) {
        debugPrint('❌ Achievement not unlocked or not found');
        return;
      }

      // Update profile
      await _supabase.from('user_profiles').update({
        'selected_badge_id': achievementId,
      }).eq('user_id', userId);

      debugPrint('✅ Display badge set to: $achievementId');
    } catch (e) {
      debugPrint('❌ Error setting display badge: $e');
    }
  }

  /// Get user's display badge
  Future<Achievement?> getDisplayBadge() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await _supabase
          .from('user_profiles')
          .select('selected_badge_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null || profile['selected_badge_id'] == null) {
        return null;
      }

      final achievementId = profile['selected_badge_id'] as String;

      // Fetch achievement details
      final achievement = await _supabase
          .from('achievements')
          .select()
          .eq('id', achievementId)
          .maybeSingle();

      if (achievement == null) return null;

      return Achievement.fromMap(achievement);
    } catch (e) {
      debugPrint('❌ Error fetching display badge: $e');
      return null;
    }
  }

  /// Get selectable badges (unlocked achievements)
  Future<List<Achievement>> getSelectableBadges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_achievements')
          .select('achievement_id, achievements(*)')
          .eq('user_id', userId)
          .eq('is_unlocked', true);

      return (response as List)
          .map(
            (item) =>
                Achievement.fromMap(item['achievements'] as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching selectable badges: $e');
      return [];
    }
  }

  /// Clear display badge
  Future<void> clearDisplayBadge() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_profiles').update({
        'selected_badge_id': null,
      }).eq('user_id', userId);

      debugPrint('✅ Display badge cleared');
    } catch (e) {
      debugPrint('❌ Error clearing display badge: $e');
    }
  }
}
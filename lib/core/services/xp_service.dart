import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/user_profile_model.dart';

class XpService {
  final _supabase = Supabase.instance.client;
  static final Set<String> _inFlightAwardKeys = <String>{};

  /// Award XP to user and log transaction
  Future<bool> awardXP({
    required int amount,
    required String reason,
    required String sourceType,
    String? sourceId,
  }) async {
    final dedupeKey = _buildAwardDedupeKey(
      sourceType: sourceType,
      sourceId: sourceId,
    );

    if (dedupeKey != null && !_inFlightAwardKeys.add(dedupeKey)) {
      debugPrint('⏭️ Skipping duplicate in-flight XP award: $dedupeKey');
      return false;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      if (dedupeKey != null) {
        final alreadyAwarded = await _hasExistingAward(
          userId: userId,
          sourceType: sourceType,
          sourceId: sourceId,
        );

        if (alreadyAwarded) {
          debugPrint('⏭️ Skipping duplicate XP award: $dedupeKey');
          return false;
        }
      }

      // Get current profile
      final profile = await getUserProfile();
      if (profile == null) {
        debugPrint('❌ User profile not found');
        return false;
      }

      final oldLevel = profile.currentLevel;
      final newTotalXP = profile.totalXp + amount;
      final newLevel = calculateLevel(newTotalXP);

      // Update profile
      await _supabase
          .from('user_profiles')
          .update({'total_xp': newTotalXP, 'current_level': newLevel})
          .eq('user_id', userId);

      // Log transaction
      await _supabase.from('xp_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'source_type': sourceType,
        'source_id': sourceId,
      });

      debugPrint('✅ Awarded $amount XP for: $reason');

      // Check for level up
      if (newLevel > oldLevel) {
        debugPrint('🎉 Level up! $oldLevel → $newLevel');
        await _sendLevelUpNotification(newLevel, newTotalXP);
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error awarding XP: $e');
      return false;
    } finally {
      if (dedupeKey != null) {
        _inFlightAwardKeys.remove(dedupeKey);
      }
    }
  }

  /// Deduct XP (e.g., for streak restoration)
  Future<bool> deductXP({required int amount, required String reason}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final profile = await getUserProfile();
      if (profile == null || profile.totalXp < amount) {
        debugPrint('❌ Insufficient XP');
        return false;
      }

      final newTotalXP = profile.totalXp - amount;
      final newLevel = calculateLevel(newTotalXP);

      await _supabase
          .from('user_profiles')
          .update({'total_xp': newTotalXP, 'current_level': newLevel})
          .eq('user_id', userId);

      // Log negative transaction
      await _supabase.from('xp_transactions').insert({
        'user_id': userId,
        'amount': -amount,
        'reason': reason,
        'source_type': 'deduction',
      });

      debugPrint('✅ Deducted $amount XP for: $reason');
      return true;
    } catch (e) {
      debugPrint('❌ Error deducting XP: $e');
      return false;
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response =
          await _supabase
              .from('user_profiles')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) return null;

      return UserProfile.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      return null;
    }
  }

  /// Get total XP
  Future<int> getUserXP() async {
    final profile = await getUserProfile();
    return profile?.totalXp ?? 0;
  }

  /// Get current level
  Future<int> getUserLevel() async {
    final profile = await getUserProfile();
    return profile?.currentLevel ?? 1;
  }

  /// Calculate level from XP (Level = XP / 100 + 1)
  int calculateLevel(int totalXp) {
    return (totalXp ~/ 100) + 1;
  }

  /// Get XP required for next level
  int getXPForNextLevel(int currentLevel) {
    return currentLevel * 100;
  }

  /// Get XP progress for current level
  Future<Map<String, int>> getXPProgress() async {
    final profile = await getUserProfile();
    if (profile == null) {
      return {'current': 0, 'min': 0, 'max': 100};
    }

    final currentXP = profile.totalXp;
    final level = profile.currentLevel;
    final levelMinXP = (level - 1) * 100;
    final levelMaxXP = level * 100;

    return {'current': currentXP, 'min': levelMinXP, 'max': levelMaxXP};
  }

  /// Check if user can afford streak save (100 XP)
  Future<bool> canAffordStreakSave() async {
    final profile = await getUserProfile();
    if (profile == null) return false;

    return profile.streakSaversAvailable > 0 || profile.totalXp >= 100;
  }

  /// Award daily goal XP (15 XP)
  Future<bool> awardDailyGoalXP() async {
    final today = DateTime.now();
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    return await awardXP(
      amount: 15,
      reason: 'Daily reading goal achieved',
      sourceType: 'daily_goal',
      sourceId: todayKey,
    );
  }

  /// Update the daily reading goal
  Future<bool> updateDailyReadingGoal(int minutes) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('user_profiles')
          .update({'daily_reading_goal_minutes': minutes})
          .eq('user_id', userId);

      debugPrint('✅ Daily reading goal updated to $minutes min');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating daily reading goal: $e');
      return false;
    }
  }

  /// Check if a username is available (case-insensitive)
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _supabase.rpc(
        'is_username_available',
        params: {'requested_username': username},
      );
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error checking username: $e');
      return false;
    }
  }

  /// Claim a username atomically
  Future<bool> claimUsername(String username) async {
    try {
      final result = await _supabase.rpc(
        'claim_username',
        params: {'requested_username': username},
      );
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error claiming username: $e');
      return false;
    }
  }

  /// Change username for an existing account
  Future<bool> changeUsername(String username) async {
    try {
      final result = await _supabase.rpc(
        'change_username',
        params: {'requested_username': username},
      );
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error changing username: $e');
      return false;
    }
  }

  /// Fetch XP transaction history (most recent first)
  Future<List<Map<String, dynamic>>> getXpTransactions({int limit = 50}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('xp_transactions')
          .select('amount, reason, source_type, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching XP transactions: $e');
      return [];
    }
  }

  String? _buildAwardDedupeKey({required String sourceType, String? sourceId}) {
    switch (sourceType) {
      case 'achievement':
      case 'book_finish':
      case 'daily_goal':
        return sourceId == null ? null : '$sourceType:$sourceId';
      default:
        return null;
    }
  }

  Future<bool> _hasExistingAward({
    required String userId,
    required String sourceType,
    String? sourceId,
  }) async {
    if (sourceId == null) return false;

    final existing =
        await _supabase
            .from('xp_transactions')
            .select('id')
            .eq('user_id', userId)
            .eq('source_type', sourceType)
            .eq('source_id', sourceId)
            .maybeSingle();

    return existing != null;
  }

  /// Send level up notification
  Future<void> _sendLevelUpNotification(int newLevel, int newXP) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'type': 'level_up',
        'title': 'Level Up! 🎉',
        'message': 'You reached Level $newLevel! Keep reading!',
        'data': {'level': newLevel, 'xp': newXP},
        'is_read': false,
        'requires_action': false,
      });

      debugPrint('✅ Level up notification sent');
    } catch (e) {
      debugPrint('❌ Error sending level up notification: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/notification_model.dart';
import 'package:biblio/core/models/achievement_model.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  /// Send achievement notification
  Future<void> sendAchievementNotification(Achievement achievement) async {
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

  /// Send level up notification
  Future<void> sendLevelUpNotification(int newLevel, int newXP) async {
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

  /// Send streak broken notification
  Future<void> sendStreakBrokenNotification(int streakLost) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'type': 'streak_broken',
        'title': 'Streak Broken 💔',
        'message':
            'Your $streakLost-day streak ended. Restore it now or start fresh!',
        'data': {
          'streak_lost': streakLost,
          'broken_date': yesterday.toIso8601String(),
        },
        'is_read': false,
        'requires_action': true,
      });

      debugPrint('✅ Streak broken notification sent');
    } catch (e) {
      debugPrint('❌ Error sending streak broken notification: $e');
    }
  }

  /// Send daily goal achieved notification
  Future<void> sendDailyGoalAchievedNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'type': 'daily_goal',
        'title': 'Daily Goal Achieved! 🎯',
        'message': 'You hit your reading goal today! +15 XP',
        'data': {'xp_earned': 15},
        'is_read': false,
        'requires_action': false,
      });

      debugPrint('✅ Daily goal notification sent');
    } catch (e) {
      debugPrint('❌ Error sending daily goal notification: $e');
    }
  }

  /// Get unread notifications
  Future<List<UserNotification>> getUnreadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => UserNotification.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching unread notifications: $e');
      return [];
    }
  }

  /// Get all notifications
  Future<List<UserNotification>> getAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((item) => UserNotification.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('user_notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);

      debugPrint('✅ Notification marked as read');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true}).eq('user_id', userId);

      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);

      debugPrint('✅ Notification deleted');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  /// Real-time notification stream
  Stream<List<UserNotification>> notificationStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    // ✅ Fixed: removed primaryKey argument
    return _supabase
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((item) => UserNotification.fromMap(item)).toList(),
        );
  }
}
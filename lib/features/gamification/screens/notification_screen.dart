import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/notification_provider.dart';
import 'package:biblio/core/models/notification_model.dart';
import 'package:biblio/core/services/notification_service.dart';
import 'package:biblio/core/services/streak_saver_service.dart';
import 'package:biblio/features/gamification/widgets/streak_saver_dialog.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const Color _bg = Color(0xFFFCF9F5);
  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _accent = Color(0xFFD97757);

  final _notificationService = NotificationService();
  final _streakSaverService = StreakSaverService();

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(allNotificationsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final topPad = (15 * scale).clamp(12.0, 15.0);
    final titleSize = (32 * scale).clamp(26.0, 32.0);
    final backIconSize = (22 * scale).clamp(18.0, 22.0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + topPad),
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: AppBar(
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: backIconSize,
                color: _textDark,
              ),
            ),
            title: Text(
              'Notifications',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            actions: [
              notificationsAsync.maybeWhen(
                data: (list) {
                  final hasUnread = list.any((n) => !n.isRead);
                  if (!hasUnread) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: _markAllAsRead,
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: (13 * scale).clamp(11.0, 13.0),
                        fontWeight: FontWeight.w600,
                        color: _accent,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allNotificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        color: _accent,
        backgroundColor: Colors.white,
        child: notificationsAsync.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(
                  color: _accent,
                  strokeWidth: 2,
                ),
              ),
          error: (error, _) => _buildErrorState(error),
          data: (notifications) {
            if (notifications.isEmpty) return _buildEmptyState();

            final grouped = _groupByDate(notifications);
            final screenWidth = MediaQuery.sizeOf(context).width;
            final scale = (screenWidth / 393).clamp(0.85, 1.0);
            final padH = (20 * scale).clamp(16.0, 20.0);

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(padH, 8, padH, 120),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final entry = grouped.entries.elementAt(index);
                return _buildDateGroup(entry.key, entry.value, scale);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateGroup(
    String dateLabel,
    List<UserNotification> items,
    double scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: (16 * scale).clamp(12.0, 16.0),
            bottom: (8 * scale).clamp(6.0, 8.0),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: (12 * scale).clamp(10.0, 12.0),
              fontWeight: FontWeight.w700,
              color: _textGrey,
              letterSpacing: 0.6,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
        ...items.map(
          (n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNotificationCard(n, scale),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(UserNotification notification, double scale) {
    final color = _typeColor(notification.type);
    final icon = _typeIcon(notification.type);
    final iconBoxSize = (42 * scale).clamp(36.0, 42.0);
    final iconSize = (20 * scale).clamp(17.0, 20.0);
    final titleSize = (15 * scale).clamp(13.0, 15.0);
    final messageSize = (13 * scale).clamp(11.0, 13.0);
    final timeSize = (11 * scale).clamp(9.0, 11.0);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: const Color(0xFFE53935),
          size: (20 * scale).clamp(17.0, 20.0),
        ),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: EdgeInsets.all((14 * scale).clamp(12.0, 14.0)),
          decoration: BoxDecoration(
            color:
                notification.isRead
                    ? Colors.white
                    : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  notification.isRead
                      ? const Color(0xFFF0ECE6)
                      : color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(width: (12 * scale).clamp(10.0, 12.0)),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                              color: _textDark,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 6, top: 2),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: messageSize,
                        color: _textGrey,
                        fontFamily: 'SF-UI-Display',
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: timeSize + 1,
                          color: _textGrey.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatTimeAgo(notification.createdAt),
                          style: TextStyle(
                            fontSize: timeSize,
                            color: _textGrey.withValues(alpha: 0.8),
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                        if (notification.requiresAction) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Action needed',
                              style: TextStyle(
                                fontSize: timeSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97757),
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: (80 * scale).clamp(66.0, 80.0),
            height: (80 * scale).clamp(66.0, 80.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECE6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: (40 * scale).clamp(33.0, 40.0),
              color: _textGrey.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: (20 * scale).clamp(16.0, 20.0),
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: (14 * scale).clamp(12.0, 14.0),
              color: _textGrey,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all((24 * scale).clamp(18.0, 24.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: (52 * scale).clamp(44.0, 52.0),
              color: _textGrey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load notifications',
              style: TextStyle(
                fontSize: (16 * scale).clamp(14.0, 16.0),
                fontWeight: FontWeight.w600,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => ref.invalidate(allNotificationsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: (14 * scale).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _handleNotificationTap(UserNotification notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      ref.invalidate(allNotificationsProvider);
      ref.invalidate(unreadCountProvider);
    }

    switch (notification.type) {
      case 'streak_broken':
        await _handleStreakBroken(notification);
        break;
      default:
        break;
    }
  }

  Future<void> _handleStreakBroken(UserNotification notification) async {
    final brokenInfo = await _streakSaverService.checkBrokenStreak();
    if (brokenInfo == null || brokenInfo['is_broken'] != true) return;

    final brokenDateStr = brokenInfo['broken_date'] as String?;
    final streakLost = brokenInfo['streak_lost'] as int?;
    if (brokenDateStr == null || streakLost == null) return;

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => StreakSaverDialog(
            brokenDate: DateTime.parse(brokenDateStr),
            streakLost: streakLost,
          ),
    );

    if (result == true) ref.invalidate(allNotificationsProvider);
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.lightImpact();
    try {
      await _notificationService.markAllAsRead();
      ref.invalidate(allNotificationsProvider);
      ref.invalidate(unreadCountProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      ref.invalidate(allNotificationsProvider);
      ref.invalidate(unreadCountProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Map<String, List<UserNotification>> _groupByDate(
    List<UserNotification> notifications,
  ) {
    final grouped = <String, List<UserNotification>>{};
    for (final n in notifications) {
      grouped.putIfAbsent(_dateLabel(n.createdAt), () => []).add(n);
    }
    return grouped;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'achievement_unlocked':
        return Icons.emoji_events_rounded;
      case 'streak_broken':
        return Icons.local_fire_department_rounded;
      case 'daily_goal_achieved':
        return Icons.flag_rounded;
      case 'streak_milestone':
        return Icons.whatshot_rounded;
      case 'level_up':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'achievement_unlocked':
        return const Color(0xFFEDAF2A);
      case 'streak_broken':
        return const Color(0xFFE53935);
      case 'daily_goal_achieved':
        return const Color(0xFF43A047);
      case 'streak_milestone':
        return const Color(0xFFD97757);
      case 'level_up':
        return const Color(0xFF7C5CBF);
      default:
        return const Color(0xFF5B8DEF);
    }
  }
}

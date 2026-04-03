import 'package:biblio/Homescreen/pages/streak/widgets/streak_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/streak_header.dart';
import 'widgets/daily_progress_card.dart';
import 'widgets/xp_level_card.dart';
import 'streak_details_screen.dart';
import 'goal_streak_details_screen.dart';
import 'package:biblio/core/services/streak_service.dart';
import 'package:biblio/features/gamification/screens/reading_stats_screen.dart';
import 'package:biblio/features/gamification/screens/streak_saver_screen.dart';
import 'package:biblio/core/providers/achievement_provider.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/features/gamification/screens/achievements_screen.dart';
import 'package:biblio/core/constants/achievement_icons.dart';
import 'package:biblio/core/models/achievement_model.dart';

class StreakPage extends ConsumerStatefulWidget {
  const StreakPage({super.key});

  @override
  ConsumerState<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends ConsumerState<StreakPage>
    with AutomaticKeepAliveClientMixin {
  final _streakService = StreakService();

  final Color _backgroundColor = const Color(0xFFFCF9F5);
  final Color _textDark = const Color(0xFF2D2D2D);

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _todayMinutes = 0;
  int _todaySeconds = 0;
  int _goalMinutes = 30;
  Set<DateTime> _weekReadDays = {};
  Set<DateTime> _streakSaverDays = {};
  int _goalStreak = 0;
  int _longestGoalStreak = 0;
  Set<DateTime> _weekGoalDays = {};
  bool _loadInProgress = false; // guard against concurrent loads

  @override
  bool get wantKeepAlive => false; // ✅ Don't cache - always rebuild

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    if (!mounted || _loadInProgress) return;
    _loadInProgress = true;

    try {
      // Compute current week range (Sat → Fri)
      final now = DateTime.now();
      final todayNorm = DateTime(now.year, now.month, now.day);
      final daysSinceSat = (now.weekday - 6 + 7) % 7;
      final weekStart = todayNorm.subtract(Duration(days: daysSinceSat));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final results = await Future.wait<int>([
        _streakService.calculateCurrentStreak(),
        _streakService.getLongestStreak(),
        _streakService.getTodayReadingSeconds(),
      ]).timeout(const Duration(seconds: 15), onTimeout: () => [0, 0, 0]);

      // Fetch this week's reading days + streak saver days
      Set<DateTime> weekDays = {};
      Set<DateTime> saverDays = {};
      try {
        final weekAndSaverResults = await Future.wait([
          _streakService
              .getReadingDaysInRange(weekStart, weekEnd)
              .timeout(const Duration(seconds: 10)),
          _streakService
              .getStreakSaverDays(months: 1)
              .timeout(const Duration(seconds: 10)),
        ]);
        weekDays = weekAndSaverResults[0];
        saverDays = weekAndSaverResults[1];
      } catch (_) {}

      int goal = 30;
      try {
        final profile = await ref
            .read(userProfileProvider.future)
            .timeout(const Duration(seconds: 10));
        goal = profile?.dailyReadingGoalMinutes ?? 30;
      } catch (_) {}

      // Fetch goal streak data
      int goalStreak = 0;
      int longestGoalStreak = 0;
      Set<DateTime> weekGoalDays = {};
      try {
        final goalResults = await Future.wait<int>([
          _streakService.calculateGoalStreak(goalMinutes: goal),
          _streakService.getLongestGoalStreak(goalMinutes: goal),
        ]).timeout(const Duration(seconds: 15), onTimeout: () => [0, 0]);
        goalStreak = goalResults[0];
        longestGoalStreak = goalResults[1];
        weekGoalDays = await _streakService
            .getGoalAchievedDaysInRange(weekStart, weekEnd, goalMinutes: goal)
            .timeout(const Duration(seconds: 10));
      } catch (_) {}

      if (mounted) {
        setState(() {
          _currentStreak = results[0];
          _longestStreak = results[1];
          final todaySeconds = results[2];
          _todayMinutes = todaySeconds ~/ 60;
          _todaySeconds = todaySeconds % 60;
          _goalMinutes = goal;
          _weekReadDays = weekDays;
          _streakSaverDays = saverDays;
          _goalStreak = goalStreak;
          _longestGoalStreak = longestGoalStreak;
          _weekGoalDays = weekGoalDays;
        });
      }
    } catch (e) {
      debugPrint('❌ _loadStreakData error: $e');
    } finally {
      _loadInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final padH = (20 * scale).clamp(16.0, 20.0);

    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final brokenAsync = ref.watch(brokenStreakProvider);
    final brokenDismissed = ref.watch(brokenStreakDismissedProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: StreakHeader(
        backgroundColor: _backgroundColor,
        titleColor: _textDark,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStreakData();
          ref.invalidate(unlockedAchievementsProvider);
          ref.invalidate(brokenStreakProvider);
        },
        color: const Color(0xFFD97757),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreakWidget(
                currentStreak: _currentStreak,
                longestStreak: _longestStreak,
                weekReadDays: _weekReadDays,
                streakSaverDays: _streakSaverDays,
                onSeeDetails: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => StreakDetailsScreen(
                            currentStreak: _currentStreak,
                            longestStreak: _longestStreak,
                            weekReadDays: _weekReadDays,
                          ),
                    ),
                  ).then((_) => _loadStreakData());
                },
                goalStreak: _goalStreak,
                longestGoalStreak: _longestGoalStreak,
                goalMinutes: _goalMinutes,
                weekGoalDays: _weekGoalDays,
                onSeeGoalDetails: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => GoalStreakDetailsScreen(
                            goalStreak: _goalStreak,
                            longestGoalStreak: _longestGoalStreak,
                            goalMinutes: _goalMinutes,
                          ),
                    ),
                  ).then((_) => _loadStreakData());
                },
              ),
              const SizedBox(height: 16),
              // Broken streak banner
              if (!brokenDismissed)
                brokenAsync.when(
                  data: (info) {
                    if (info != null && info['is_broken'] == true) {
                      return _buildBrokenStreakBanner(info);
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              DailyProgressCard(
                todayMinutes: _todayMinutes,
                todaySeconds: _todaySeconds,
                goalMinutes: _goalMinutes,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ReadingStatsScreen(
                            todaySeconds: _todayMinutes * 60 + _todaySeconds,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // XP & Level Card
              const XpLevelCard(),
              const SizedBox(height: 16),
              // Recent Badges
              unlockedAsync.when(
                data: (unlocked) => _buildRecentBadgesSection(unlocked),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              // const CurrentChallengesCard(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recent Badges ────────────────────────────────────────────────────────

  Widget _buildRecentBadgesSection(List<UserAchievement> unlocked) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerFontSize = (18 * scale).clamp(15.0, 18.0);
    final smallFontSize = (13 * scale).clamp(11.0, 13.0);

    final recent =
        unlocked
            .where((ua) => ua.isUnlocked && ua.achievement != null)
            .take(3)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Badges',
              style: TextStyle(
                fontSize: headerFontSize,
                fontWeight: FontWeight.w700,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97757),
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Start reading to unlock badges!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: smallFontSize,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          )
        else
          Row(
            children:
                recent
                    .map(
                      (ua) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: ua == recent.last ? 0 : 8,
                          ),
                          child: _buildBadgeMiniCard(ua),
                        ),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }

  Widget _buildBadgeMiniCard(UserAchievement ua) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final smallFontSize = (13 * scale).clamp(11.0, 13.0);
    final tinyFontSize = (12 * scale).clamp(10.0, 12.0);
    final microFontSize = (10 * scale).clamp(8.0, 10.0);
    final badgeIconSize = (38 * scale).clamp(30.0, 38.0);
    final badgeInnerIconSize = (20 * scale).clamp(16.0, 20.0);

    final achievement = ua.achievement!;
    final tierColor = _getTierColor(achievement.tier);
    final tierGradient = _getTierGradient(achievement.tier);
    final icon = AchievementIcons.getIcon(achievement.id);
    final unlockedText =
        ua.unlockedAt != null
            ? _formatUnlockedDate(ua.unlockedAt!)
            : 'Recently';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient top section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tierGradient[0].withValues(alpha: 0.18),
                  tierGradient[1].withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with circle bg
                Container(
                  width: badgeIconSize,
                  height: badgeIconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: tierGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: badgeInnerIconSize),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '+${achievement.xpReward} XP',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom info section
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: tinyFontSize,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      size: tinyFontSize + 2,
                      color: tierColor,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Unlocked $unlockedText',
                  style: TextStyle(
                    fontSize: microFontSize,
                    color: Colors.grey.shade500,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Broken streak banner ─────────────────────────────────────────────

  Widget _buildBrokenStreakBanner(Map<String, dynamic> info) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final bannerTitleSize = (16 * scale).clamp(13.0, 16.0);
    final bannerSubSize = (12 * scale).clamp(10.0, 12.0);
    final bannerBtnSize = (13 * scale).clamp(11.0, 13.0);
    final fireIconSize = (46 * scale).clamp(38.0, 46.0);
    final fireEmojiSize = (22 * scale).clamp(18.0, 22.0);

    final streakLost = info['streak_lost'] as int? ?? 0;
    final missedDays = info['missed_days'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StreakSaverScreen()),
          ).then((_) {
            // Refresh broken streak status after returning
            ref.invalidate(brokenStreakProvider);
            _loadStreakData();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Fire icon
              Container(
                width: fireIconSize,
                height: fireIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text('🔥', style: TextStyle(fontSize: fireEmojiSize)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Broken!',
                      style: TextStyle(
                        fontSize: bannerTitleSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your $streakLost-day streak ended · '
                      'Missed $missedDays day${missedDays > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: bannerSubSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Restore',
                  style: TextStyle(
                    fontSize: bannerBtnSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE53935),
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey.shade600;
      case 'gold':
        return Colors.amber.shade700;
      default:
        return Colors.blue;
    }
  }

  List<Color> _getTierGradient(String tier) {
    switch (tier) {
      case 'bronze':
        return [const Color(0xFFD7A574), const Color(0xFFA0522D)];
      case 'silver':
        return [const Color(0xFFB0BEC5), const Color(0xFF78909C)];
      case 'gold':
        return [const Color(0xFFFFD54F), const Color(0xFFFFA000)];
      default:
        return [const Color(0xFF90CAF9), const Color(0xFF42A5F5)];
    }
  }

  String _formatUnlockedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

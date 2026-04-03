import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/constants/level_config.dart';
import 'package:biblio/core/services/xp_service.dart';
import 'package:biblio/features/gamification/widgets/xp_progress_bar.dart';

class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  static const Color _bg = Color(0xFFFCF9F5);
  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);

  void _showXpHistory(BuildContext context) {
    HapticFeedback.lightImpact();
    final xpService = XpService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFCF9F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle + header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0CCC6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Text(
                              'XP History',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0EB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Last 50',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD97757),
                                  fontFamily: 'SF-UI-Display',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(
                          color: const Color(0xFFECE8E3),
                          height: 1,
                        ),
                      ],
                    ),
                  ),
                  // Transaction list
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: xpService.getXpTransactions(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD97757),
                              strokeWidth: 2,
                            ),
                          );
                        }

                        final transactions = snapshot.data ?? [];

                        if (transactions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No XP transactions yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _textGrey,
                                    fontFamily: 'SF-UI-Display',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start reading to earn XP',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textGrey,
                                    fontFamily: 'SF-UI-Display',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return _buildTransactionTile(tx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final int amount = (tx['amount'] as num?)?.toInt() ?? 0;
    final String reason = tx['reason'] as String? ?? 'XP awarded';
    final String sourceType = tx['source_type'] as String? ?? '';
    final String? createdAt = tx['created_at'] as String?;

    final bool isPositive = amount >= 0;
    final Color amountColor =
        isPositive ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final Color iconBg =
        isPositive
            ? const Color(0xFF43A047).withValues(alpha: 0.10)
            : const Color(0xFFE53935).withValues(alpha: 0.10);

    final IconData icon = _sourceIcon(sourceType);
    final String timeLabel = _formatTime(createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: amountColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                    fontFamily: 'SF-UI-Display',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textGrey,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isPositive ? '+' : ''}$amount XP',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ],
      ),
    );
  }

  IconData _sourceIcon(String sourceType) {
    switch (sourceType) {
      case 'daily_goal':
        return Icons.flag_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'deduction':
        return Icons.remove_circle_outline_rounded;
      case 'session':
      case 'reading_session':
        return Icons.auto_stories_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'level_up':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final profileAsync = ref.watch(userProfileProvider);
    final xpProgressAsync = ref.watch(xpProgressProvider);

    final appBarTitleSize = (32 * scale).clamp(26.0, 32.0);
    final sectionTitleSize = (18 * scale).clamp(15.0, 18.0);
    final padH = (20 * scale).clamp(16.0, 20.0);
    final topPad = (15 * scale).clamp(12.0, 15.0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 15),
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
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 22),
            ),
            title: Text(
              'Levels & Tags',
              style: TextStyle(
                fontSize: appBarTitleSize,
                fontWeight: FontWeight.w600,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showXpHistory(context),
                icon: Icon(
                  Icons.history_rounded,
                  size: (24 * scale).clamp(20.0, 24.0),
                  color: _textDark.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final profile = profileAsync.asData?.value;
            final level = profile?.currentLevel ?? 1;
            final totalXp = profile?.totalXp ?? 0;
            final info = LevelConfig.getInfo(level);
            final xpProgress =
                xpProgressAsync.whenData((p) => p).value ?? <String, int>{};
            final xpCurrent = xpProgress['current'] ?? 0;
            final xpMax = xpProgress['max'] ?? 100;
            final xpToNext = xpMax - xpCurrent;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Current Level Hero Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padH,
                      (16 * scale).clamp(12.0, 16.0),
                      padH,
                      0,
                    ),
                    child: _buildHeroCard(
                      context,
                      level,
                      info,
                      totalXp,
                      xpToNext,
                    ),
                  ),
                ),

                // Section title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padH,
                      (28 * scale).clamp(22.0, 28.0),
                      padH,
                      (14 * scale).clamp(10.0, 14.0),
                    ),
                    child: Text(
                      'All Levels',
                      style: TextStyle(
                        fontSize: sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ),
                ),

                // Tier list
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: padH),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tier = LevelConfig.allTiers[index];
                      final isCurrentTier = info.tag == tier.name;
                      final isPast = _isTierPast(tier, level);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: (12 * scale).clamp(8.0, 12.0),
                        ),
                        child: _buildTierCard(
                          context,
                          tier,
                          isCurrentTier,
                          isPast,
                          index,
                        ),
                      );
                    }, childCount: LevelConfig.allTiers.length),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(height: (40 * scale).clamp(32.0, 40.0)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Hero Card ────────────────────────────────────────────────────────────

  Widget _buildHeroCard(
    BuildContext context,
    int level,
    LevelInfo info,
    int totalXp,
    int xpToNext,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final iconContainerSize = (72 * scale).clamp(58.0, 72.0);
    final iconSize = (36 * scale).clamp(30.0, 36.0);
    final levelFontSize = (28 * scale).clamp(23.0, 28.0);
    final tagFontSize = (15 * scale).clamp(12.0, 15.0);
    final descFontSize = (13 * scale).clamp(11.0, 13.0);
    final xpLabelFontSize = (13 * scale).clamp(11.0, 13.0);
    final xpSubFontSize = (12 * scale).clamp(10.0, 12.0);
    final padAll = (24 * scale).clamp(18.0, 24.0);
    final xpBarGap = (20 * scale).clamp(14.0, 20.0);
    final levelGap = (14 * scale).clamp(10.0, 14.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: info.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: info.gradient[0].withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padAll),
        child: Column(
          children: [
            // Icon + Level
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .25),
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(height: levelGap),
            Text(
              'Level $level',
              style: TextStyle(
                fontSize: levelFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'SF-UI-Display',
                height: 1.1,
              ),
            ),
            SizedBox(height: (4 * scale).roundToDouble()),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (14 * scale).clamp(10.0, 14.0),
                vertical: (5 * scale).clamp(4.0, 5.0),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                info.tag,
                style: TextStyle(
                  fontSize: tagFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'SF-UI-Display',
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: (6 * scale).roundToDouble()),
            Text(
              info.description,
              style: TextStyle(
                fontSize: descFontSize,
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: xpBarGap),

            // XP bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalXp XP',
                      style: TextStyle(
                        fontSize: xpLabelFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                    Text(
                      '$xpToNext XP to next level',
                      style: TextStyle(
                        fontSize: xpSubFontSize,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (8 * scale).roundToDouble()),
                const XpProgressBar(
                  showLabel: false,
                  height: 8,
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tier Card ────────────────────────────────────────────────────────────

  Widget _buildTierCard(
    BuildContext context,
    LevelTier tier,
    bool isCurrent,
    bool isPast,
    int index,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final circleSize = (48 * scale).clamp(40.0, 48.0);
    final innerIconSize = (24 * scale).clamp(20.0, 24.0);
    final tierNameSize = (16 * scale).clamp(13.0, 16.0);
    final descSize = (12 * scale).clamp(10.0, 12.0);
    final rangeChipSize = (12 * scale).clamp(10.0, 12.0);
    final statusIconSize = (20 * scale).clamp(16.0, 20.0);
    final cardPad = (16 * scale).clamp(12.0, 16.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            isCurrent ? Border.all(color: tier.gradient[1], width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCurrent ? 0.08 : 0.04),
            blurRadius: isCurrent ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPad),
        child: Row(
          children: [
            // Gradient circle icon
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors:
                      isPast || isCurrent
                          ? tier.gradient
                          : [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(tier.icon, color: Colors.white, size: innerIconSize),
            ),
            SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.name,
                    style: TextStyle(
                      fontSize: tierNameSize,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? tier.gradient[1] : _textDark,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  SizedBox(height: (3 * scale).roundToDouble()),
                  Text(
                    tier.description,
                    style: TextStyle(
                      fontSize: descSize,
                      color: Colors.grey.shade500,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ],
              ),
            ),
            // Level range chip
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (10 * scale).clamp(8.0, 10.0),
                vertical: (5 * scale).clamp(4.0, 5.0),
              ),
              decoration: BoxDecoration(
                color:
                    isPast || isCurrent
                        ? tier.gradient[0].withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lv ${tier.levelRange}',
                style: TextStyle(
                  fontSize: rangeChipSize,
                  fontWeight: FontWeight.w700,
                  color:
                      isPast || isCurrent
                          ? tier.gradient[1]
                          : Colors.grey.shade400,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ),
            // Check or lock
            SizedBox(width: (8 * scale).roundToDouble()),
            Icon(
              isPast
                  ? Icons.check_circle_rounded
                  : isCurrent
                  ? Icons.radio_button_checked_rounded
                  : Icons.lock_outline_rounded,
              size: statusIconSize,
              color:
                  isPast
                      ? tier.gradient[1]
                      : isCurrent
                      ? tier.gradient[1]
                      : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  /// Check if a tier is below the user's current tier
  bool _isTierPast(LevelTier tier, int currentLevel) {
    final currentInfo = LevelConfig.getInfo(currentLevel);
    if (currentInfo.tag == tier.name) return false;
    // Past tiers appear before the current in the allTiers list
    for (final t in LevelConfig.allTiers) {
      if (t.name == currentInfo.tag) return false; // reached current first
      if (t.name == tier.name) return true; // found the tier before current
    }
    return false;
  }
}

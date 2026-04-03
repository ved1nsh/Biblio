import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:biblio/core/providers/achievement_provider.dart';
import 'package:biblio/core/models/achievement_model.dart';
import 'package:biblio/core/constants/achievement_icons.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFFCF9F5);
  static const _textDark = Color(0xFF2D2D2D);
  static const _textGrey = Color(0xFF8A8A8A);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Tier helpers ──────────────────────────────────────────────────────

  static Color tierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFA0522D);
      case 'silver':
        return const Color(0xFF78909C);
      case 'gold':
        return const Color(0xFFFFA000);
      default:
        return const Color(0xFF5B8DEF);
    }
  }

  static List<Color> tierGradient(String tier) {
    switch (tier) {
      case 'bronze':
        return const [Color(0xFFD7A574), Color(0xFFA0522D)];
      case 'silver':
        return const [Color(0xFFB0BEC5), Color(0xFF78909C)];
      case 'gold':
        return const [Color(0xFFFFD54F), Color(0xFFFFA000)];
      default:
        return const [Color(0xFF90CAF9), Color(0xFF42A5F5)];
    }
  }

  // ─── Build  ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final appBarTitleSize = (32 * scale).clamp(26.0, 32.0);
    final appBarIconSize = (20 * scale).clamp(17.0, 20.0);
    final tabFontSize = (14 * scale).clamp(12.0, 14.0);
    final tabMarginH = (20 * scale).clamp(16.0, 20.0);
    final tabMarginV = (8 * scale).clamp(6.0, 8.0);
    final tabPadding = (4 * scale).roundToDouble();

    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final lockedAsync = ref.watch(lockedAchievementsProvider);
    final unlockedCountAsync = ref.watch(unlockedCountProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 15),
        child: Padding(
          padding: EdgeInsets.only(top: (15 * scale).clamp(12.0, 15.0)),
          child: AppBar(
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textDark,
                size: appBarIconSize,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Achievements',
              style: TextStyle(
                color: _textDark,
                fontSize: appBarTitleSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: tabMarginH,
              vertical: tabMarginV,
            ),
            padding: EdgeInsets.all(tabPadding),
            decoration: BoxDecoration(
              color: const Color(0xFFECE8E3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _textDark,
              unselectedLabelColor: _textGrey,
              labelStyle: TextStyle(
                fontSize: tabFontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: tabFontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'SF-UI-Display',
              ),
              tabs: [
                Tab(
                  child: unlockedCountAsync.when(
                    data: (c) => Text('Unlocked ($c)'),
                    loading: () => const Text('Unlocked'),
                    error: (_, __) => const Text('Unlocked'),
                  ),
                ),
                const Tab(text: 'Locked'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Unlocked tab ─────────────────────────────────────
                RefreshIndicator(
                  onRefresh:
                      () async => ref.invalidate(unlockedAchievementsProvider),
                  color: const Color(0xFFD97757),
                  child: unlockedAsync.when(
                    data:
                        (list) =>
                            _buildGrid(list, unlocked: true, scale: scale),
                    loading: () => _buildGridSkeleton(scale),
                    error:
                        (e, _) => _errorView(
                          e,
                          scale,
                          () => ref.invalidate(unlockedAchievementsProvider),
                        ),
                  ),
                ),

                // ── Locked tab ───────────────────────────────────────
                RefreshIndicator(
                  onRefresh:
                      () async => ref.invalidate(lockedAchievementsProvider),
                  color: const Color(0xFFD97757),
                  child: lockedAsync.when(
                    data:
                        (list) =>
                            _buildGrid(list, unlocked: false, scale: scale),
                    loading: () => _buildGridSkeleton(scale),
                    error:
                        (e, _) => _errorView(
                          e,
                          scale,
                          () => ref.invalidate(lockedAchievementsProvider),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grid ──────────────────────────────────────────────────────────────

  Widget _buildGrid(
    List<UserAchievement> items, {
    required bool unlocked,
    required double scale,
  }) {
    final padH = (20 * scale).clamp(16.0, 20.0);
    final padBottom = (40 * scale).clamp(32.0, 40.0);
    final spacing = (14 * scale).clamp(10.0, 14.0);
    final childAspectRatio = (0.88 * scale).clamp(0.8, 0.88);
    if (items.isEmpty) {
      return _emptyView(unlocked, scale);
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        padH,
        (8 * scale).clamp(6.0, 8.0),
        padH,
        padBottom,
      ),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, i) {
        final ua = items[i];
        return _AchievementTile(ua: ua, onTap: () => _showExpandedCard(ua));
      },
    );
  }

  // ─── Expanded overlay with confetti ────────────────────────────────────

  void _showExpandedCard(UserAchievement ua) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'achievement',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, a1, a2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.elasticOut),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
      pageBuilder: (ctx, _, __) {
        return _ExpandedAchievementOverlay(ua: ua);
      },
    );
  }

  // ─── Empty / error / skeleton helpers ──────────────────────────────────

  Widget _emptyView(bool unlocked, double scale) {
    final iconSize = (64 * scale).clamp(52.0, 64.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final bodySize = (14 * scale).clamp(12.0, 14.0);
    return Center(
      child: Padding(
        padding: EdgeInsets.all((40 * scale).clamp(28.0, 40.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked
                  ? Icons.emoji_events_outlined
                  : Icons.celebration_rounded,
              size: iconSize,
              color: const Color(0xFFD0CCC6),
            ),
            SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
            Text(
              unlocked ? 'No Achievements Yet' : 'All Unlocked!',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: (8 * scale).roundToDouble()),
            Text(
              unlocked
                  ? 'Start reading to earn badges'
                  : 'You\'ve collected every achievement!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: bodySize,
                color: _textGrey,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(Object error, double scale, VoidCallback retry) {
    final iconSize = (48 * scale).clamp(40.0, 48.0);
    final titleSize = (16 * scale).clamp(14.0, 16.0);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: iconSize, color: _textGrey),
          SizedBox(height: (12 * scale).clamp(8.0, 12.0)),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: _textDark,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          SizedBox(height: (12 * scale).clamp(8.0, 12.0)),
          GestureDetector(
            onTap: retry,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: (24 * scale).clamp(18.0, 24.0),
                vertical: (10 * scale).clamp(8.0, 10.0),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFECE8E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSkeleton(double scale) {
    final padH = (20 * scale).clamp(16.0, 20.0);
    final padBottom = (40 * scale).clamp(32.0, 40.0);
    final spacing = (14 * scale).clamp(10.0, 14.0);
    final childAspectRatio = (0.88 * scale).clamp(0.8, 0.88);
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        padH,
        (8 * scale).clamp(6.0, 8.0),
        padH,
        padBottom,
      ),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder:
          (_, __) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFECE8E3),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Achievement tile (square card for the grid)
// ═══════════════════════════════════════════════════════════════════════════

class _AchievementTile extends StatelessWidget {
  final UserAchievement ua;
  final VoidCallback onTap;

  const _AchievementTile({required this.ua, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final borderRadius = (22 * scale).clamp(18.0, 22.0);
    final iconBadgeSize = (52 * scale).clamp(44.0, 52.0);
    final iconSize = (26 * scale).clamp(22.0, 26.0);
    final titleSize = (13 * scale).clamp(11.0, 13.0);
    final xpSize = (11 * scale).clamp(9.0, 11.0);
    final tierSize = (10 * scale).clamp(8.0, 10.0);
    final overlayIcon = (16 * scale).clamp(14.0, 16.0);
    final checkBoxSize = (20 * scale).clamp(17.0, 20.0);

    final a = ua.achievement;
    if (a == null) return const SizedBox.shrink();

    final unlocked = ua.isUnlocked;
    final tier = a.tier;
    final gradient = _AchievementsScreenState.tierGradient(tier);
    final icon = AchievementIcons.getIcon(a.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: (unlocked ? gradient[0] : Colors.black).withValues(
                alpha: unlocked ? 0.15 : 0.04,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient header strip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        unlocked
                            ? gradient
                            : const [Color(0xFFD0CCC6), Color(0xFFBDB8B2)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  (14 * scale).clamp(10.0, 14.0),
                  (20 * scale).clamp(16.0, 20.0),
                  (14 * scale).clamp(10.0, 14.0),
                  (14 * scale).clamp(10.0, 14.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon badge
                    Container(
                      width: iconBadgeSize,
                      height: iconBadgeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            unlocked
                                ? LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        color: unlocked ? null : const Color(0xFFECE8E3),
                        boxShadow:
                            unlocked
                                ? [
                                  BoxShadow(
                                    color: gradient[0].withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child: Icon(
                        icon,
                        color:
                            unlocked ? Colors.white : const Color(0xFFB0AAA4),
                        size: iconSize,
                      ),
                    ),
                    SizedBox(height: (12 * scale).clamp(8.0, 12.0)),

                    // Title
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color:
                            unlocked
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFB0AAA4),
                        fontFamily: 'SF-UI-Display',
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: (4 * scale).roundToDouble()),

                    // XP pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            unlocked
                                ? gradient[0].withValues(alpha: 0.12)
                                : const Color(0xFFF5F2EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${a.xpReward} XP',
                        style: TextStyle(
                          fontSize: xpSize,
                          fontWeight: FontWeight.w700,
                          color:
                              unlocked ? gradient[1] : const Color(0xFFB0AAA4),
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ),

                    // Progress bar for locked
                    if (!unlocked) ...[
                      SizedBox(height: (8 * scale).roundToDouble()),
                      _MiniProgress(
                        progress: ua.currentProgress,
                        target: a.targetValue,
                        color: _AchievementsScreenState.tierColor(tier),
                      ),
                    ],

                    // Tier label for unlocked
                    if (unlocked) ...[
                      SizedBox(height: (6 * scale).roundToDouble()),
                      Text(
                        AchievementIcons.getTierLabel(tier),
                        style: TextStyle(
                          fontSize: tierSize,
                          fontWeight: FontWeight.w600,
                          color: gradient[1],
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Lock overlay
            if (!unlocked)
              Positioned(
                top: (14 * scale).clamp(10.0, 14.0),
                right: (12 * scale).clamp(8.0, 12.0),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: overlayIcon,
                  color: const Color(0xFFD0CCC6),
                ),
              ),

            // Checkmark for unlocked
            if (unlocked)
              Positioned(
                top: (14 * scale).clamp(10.0, 14.0),
                right: (12 * scale).clamp(8.0, 12.0),
                child: Container(
                  width: checkBoxSize,
                  height: checkBoxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: gradient),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: (13 * scale).clamp(11.0, 13.0),
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mini progress bar for locked tiles
// ═══════════════════════════════════════════════════════════════════════════

class _MiniProgress extends StatelessWidget {
  final int progress;
  final int target;
  final Color color;

  const _MiniProgress({
    required this.progress,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final fraction = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: (4 * scale).clamp(3.0, 4.0),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: const Color(0xFFECE8E3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(height: (3 * scale).roundToDouble()),
        Text(
          '$progress / $target',
          style: TextStyle(
            fontSize: (9 * scale).clamp(8.0, 9.0),
            fontWeight: FontWeight.w600,
            color: Color(0xFFB0AAA4),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Expanded overlay (tapped card zooms into center + confetti)
// ═══════════════════════════════════════════════════════════════════════════

class _ExpandedAchievementOverlay extends StatefulWidget {
  final UserAchievement ua;
  const _ExpandedAchievementOverlay({required this.ua});

  @override
  State<_ExpandedAchievementOverlay> createState() =>
      _ExpandedAchievementOverlayState();
}

class _ExpandedAchievementOverlayState
    extends State<_ExpandedAchievementOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    if (widget.ua.isUnlocked) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final overlayWidth = (screenWidth * 0.82).clamp(280.0, 380.0);
    final cardPadH = (28 * scale).clamp(20.0, 28.0);
    final cardPadV = (32 * scale).clamp(24.0, 32.0);
    final iconBox = (88 * scale).clamp(72.0, 88.0);
    final iconSize = (44 * scale).clamp(36.0, 44.0);
    final tierSize = (10 * scale).clamp(8.0, 10.0);
    final titleSize = (22 * scale).clamp(18.0, 22.0);
    final bodySize = (14 * scale).clamp(12.0, 14.0);
    final xpSize = (16 * scale).clamp(14.0, 16.0);
    final closeHeight = (50 * scale).clamp(44.0, 50.0);
    final closeText = (16 * scale).clamp(14.0, 16.0);

    final a = widget.ua.achievement;
    if (a == null) return const SizedBox.shrink();

    final unlocked = widget.ua.isUnlocked;
    final tier = a.tier;
    final gradient = _AchievementsScreenState.tierGradient(tier);
    final icon = AchievementIcons.getIcon(a.id);

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const SizedBox.expand(),
          ),

          // Card
          Container(
            width: overlayWidth,
            padding: EdgeInsets.symmetric(
              horizontal: cardPadH,
              vertical: cardPadV,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF9F5),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (unlocked ? gradient[0] : Colors.black).withValues(
                    alpha: 0.2,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        unlocked
                            ? LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    color: unlocked ? null : const Color(0xFFECE8E3),
                    boxShadow:
                        unlocked
                            ? [
                              BoxShadow(
                                color: gradient[0].withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: unlocked ? Colors.white : const Color(0xFFB0AAA4),
                  ),
                ),
                SizedBox(height: (20 * scale).clamp(16.0, 20.0)),

                // Tier pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        unlocked ? LinearGradient(colors: gradient) : null,
                    color: unlocked ? null : const Color(0xFFECE8E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AchievementIcons.getTierLabel(tier).toUpperCase(),
                    style: TextStyle(
                      fontSize: tierSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: unlocked ? Colors.white : const Color(0xFFB0AAA4),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
                SizedBox(height: (16 * scale).clamp(12.0, 16.0)),

                // Title
                Text(
                  a.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                SizedBox(height: (8 * scale).roundToDouble()),

                // Description
                Text(
                  a.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodySize,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A8A8A),
                    fontFamily: 'SF-UI-Display',
                    height: 1.4,
                  ),
                ),
                SizedBox(height: (20 * scale).clamp(16.0, 20.0)),

                // XP reward
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: gradient[0].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '+${a.xpReward} XP',
                    style: TextStyle(
                      fontSize: xpSize,
                      fontWeight: FontWeight.w800,
                      color: gradient[1],
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),

                // Progress (locked)
                if (!unlocked) ...[
                  SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: (6 * scale).clamp(5.0, 6.0),
                      child: LinearProgressIndicator(
                        value:
                            a.targetValue > 0
                                ? (widget.ua.currentProgress / a.targetValue)
                                    .clamp(0.0, 1.0)
                                : 0,
                        backgroundColor: const Color(0xFFECE8E3),
                        valueColor: AlwaysStoppedAnimation<Color>(gradient[1]),
                      ),
                    ),
                  ),
                  SizedBox(height: (6 * scale).roundToDouble()),
                  Text(
                    '${widget.ua.currentProgress} / ${a.targetValue}',
                    style: TextStyle(
                      fontSize: (12 * scale).clamp(10.0, 12.0),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A8A8A),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ],

                // Unlocked date
                if (unlocked && widget.ua.unlockedAt != null) ...[
                  SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: gradient[1],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unlocked ${_formatDate(widget.ua.unlockedAt!)}',
                        style: TextStyle(
                          fontSize: (12 * scale).clamp(10.0, 12.0),
                          fontWeight: FontWeight.w500,
                          color: gradient[1],
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: (24 * scale).clamp(18.0, 24.0)),

                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: closeHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            unlocked
                                ? gradient
                                : [
                                  gradient[0].withValues(alpha: 0.25),
                                  gradient[1].withValues(alpha: 0.25),
                                ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        unlocked ? 'Awesome!' : 'Close',
                        style: TextStyle(
                          fontSize: closeText,
                          fontWeight: FontWeight.w700,
                          color: unlocked ? Colors.white : gradient[1],
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti from bottom-left corner
          if (unlocked)
            Positioned(
              bottom: 300,
              left: 0,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -pi / 4,
                emissionFrequency: 0.05,
                numberOfParticles: 18,
                maxBlastForce: 35,
                minBlastForce: 15,
                gravity: 0.2,
                colors: const [
                  Color(0xFFE53935),
                  Color(0xFF5B8DEF),
                  Color(0xFF4CAF50),
                  Color(0xFFFFD54F),
                  Color(0xFF7C5CBF),
                  Color(0xFFD97757),
                ],
              ),
            ),

          // Confetti from bottom-right corner
          if (unlocked)
            Positioned(
              bottom: 300,
              right: 0,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -(3 * pi / 4),
                emissionFrequency: 0.05,
                numberOfParticles: 18,
                maxBlastForce: 35,
                minBlastForce: 15,
                gravity: 0.2,
                colors: const [
                  Color(0xFFE53935),
                  Color(0xFF5B8DEF),
                  Color(0xFF4CAF50),
                  Color(0xFFFFD54F),
                  Color(0xFF7C5CBF),
                  Color(0xFFD97757),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

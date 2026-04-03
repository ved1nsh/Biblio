import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/constants/level_config.dart';
import 'package:biblio/features/gamification/screens/levels_screen.dart';

/// Expanded XP & Level card showing current level info, tag, XP bar, and
/// next-level progress. Tappable → navigates to LevelsScreen.
class XpLevelCard extends ConsumerWidget {
  const XpLevelCard({super.key});

  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final xpProgressAsync = ref.watch(xpProgressProvider);

    return profileAsync.when(
      data: (profile) {
        final level = profile?.currentLevel ?? 1;
        final totalXp = profile?.totalXp ?? 0;
        final info = LevelConfig.getInfo(level);

        return xpProgressAsync.when(
          data: (xpProgress) {
            final current = xpProgress['current'] ?? 0;
            final min = xpProgress['min'] ?? 0;
            final max = xpProgress['max'] ?? 100;
            final progressInLevel = current - min;
            final levelRange = max - min;
            final percentage =
                levelRange > 0 ? (progressInLevel / levelRange) : 0.0;
            final xpToNext = max - current;

            return _buildCard(
              context,
              level: level,
              info: info,
              totalXp: totalXp,
              xpToNext: xpToNext,
              percentage: percentage,
              progressInLevel: progressInLevel,
              levelRange: levelRange,
            );
          },
          loading: () => _buildLoadingCard(),
          error:
              (_, __) => _buildCard(
                context,
                level: 1,
                info: LevelConfig.getInfo(1),
                totalXp: 0,
                xpToNext: 100,
                percentage: 0,
                progressInLevel: 0,
                levelRange: 100,
              ),
        );
      },
      loading: () => _buildLoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required int level,
    required LevelInfo info,
    required int totalXp,
    required int xpToNext,
    required double percentage,
    required int progressInLevel,
    required int levelRange,
  }) {
    final gradientColors = info.gradient;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final badgeSize = (52 * scale).clamp(42.0, 52.0);
    final badgeFontSize = (22 * scale).clamp(18.0, 22.0);
    final padAll = (18 * scale).clamp(14.0, 18.0);
    final titleFontSize = (16 * scale).clamp(13.0, 16.0);
    final smallFontSize = (12 * scale).clamp(10.0, 12.0);
    final tinyFontSize = (11 * scale).clamp(9.0, 11.0);
    final chevronSize = (22 * scale).clamp(18.0, 22.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LevelsScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(padAll),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ─── Top Row: Level badge + info + arrow ─────────────
            Row(
              children: [
                // Level badge circle with gradient
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Level tag + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level $level',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tag pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gradientColors[0].withValues(alpha: 0.15),
                                  gradientColors[1].withValues(alpha: 0.10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              info.tag,
                              style: TextStyle(
                                fontSize: tinyFontSize,
                                fontWeight: FontWeight.w700,
                                color: gradientColors[1],
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: _textGrey,
                          fontFamily: 'SF-UI-Display',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _textGrey.withValues(alpha: 0.5),
                  size: chevronSize,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── XP Progress Bar ─────────────────────────────────
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progressInLevel / $levelRange XP',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w600,
                        color: _textGrey,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Custom progress bar with gradient fill
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          decoration: BoxDecoration(
                            color: gradientColors[0].withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Filled portion
                        FractionallySizedBox(
                          widthFactor: percentage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ─── Bottom stats row ────────────────────────────────
            Row(
              children: [
                // Total XP chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: gradientColors[0].withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: gradientColors[1],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalXp XP total',
                        style: TextStyle(
                          fontSize: tinyFontSize,
                          fontWeight: FontWeight.w600,
                          color: gradientColors[1],
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Next level info
                Text(
                  '$xpToNext XP to next level',
                  style: TextStyle(
                    fontSize: tinyFontSize,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B6CF6),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

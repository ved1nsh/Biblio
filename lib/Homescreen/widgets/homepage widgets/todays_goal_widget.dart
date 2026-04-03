import 'dart:math';

import 'package:biblio/core/providers/xp_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodaysGoalWidget extends ConsumerWidget {
  final VoidCallback? onStreakTap;
  final VoidCallback? onGoalTap;

  const TodaysGoalWidget({super.key, this.onStreakTap, this.onGoalTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    final todaySecondsAsync = ref.watch(todayReadingSecondsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final weekReadDaysAsync = ref.watch(currentWeekReadDaysProvider);

    final streak = streakAsync.whenOrNull(data: (value) => value) ?? 0;
    final todaySeconds =
        todaySecondsAsync.whenOrNull(data: (value) => value) ?? 0;
    final todayMinutes = todaySeconds ~/ 60;
    final remainingSeconds = max(0, todaySeconds % 60);
    final goalMinutes =
        profileAsync.whenOrNull(
          data: (profile) => profile?.dailyReadingGoalMinutes,
        ) ??
        30;

    final goalSeconds = goalMinutes * 60;
    final goalProgress =
        goalSeconds > 0 ? (todaySeconds / goalSeconds).clamp(0.0, 1.0) : 0.0;
    final isCompleted = goalProgress >= 1.0;
    final hasStarted = todaySeconds > 0;
    final remainingGoalMinutes = max(
      0,
      ((goalSeconds - todaySeconds) / 60).ceil(),
    );

    final supportingText = _buildSupportingText(
      streak: streak,
      hasStarted: hasStarted,
      isCompleted: isCompleted,
      remainingGoalMinutes: remainingGoalMinutes,
      goalMinutes: goalMinutes,
    );
    final progressPillText = _buildProgressPillText(
      hasStarted: hasStarted,
      isCompleted: isCompleted,
      remainingGoalMinutes: remainingGoalMinutes,
    );

    final weekReadDays =
        weekReadDaysAsync.whenOrNull(data: (value) => value) ?? {};
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    final daysSinceSaturday = (now.weekday - 6 + 7) % 7;
    final weekStart = todayNorm.subtract(Duration(days: daysSinceSaturday));
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final dayLabels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final cardRadius = 28.0;
    final topCardRadius = 22.0;
    final lowerCardRadius = 18.0;
    final outerMarginBottom = (20 * scale).clamp(16.0, 20.0);
    final outerPadH = (20 * scale).clamp(16.0, 20.0);
    final outerPadTop = (20 * scale).clamp(16.0, 20.0);
    final outerPadBottom = (18 * scale).clamp(14.0, 18.0);
    final glowSize = (132 * scale).clamp(112.0, 132.0);
    final glowTop = (32 * scale).clamp(24.0, 32.0);
    final iconPad = (9 * scale).clamp(7.0, 9.0);
    final headerGap = (12 * scale).clamp(10.0, 12.0);
    final titleBottomGap = (14 * scale).clamp(10.0, 14.0);
    final topCardPad = (18 * scale).clamp(14.0, 18.0);
    final topCardBottomPad = (16 * scale).clamp(12.0, 16.0);
    final goalBadgePadH = (12 * scale).clamp(10.0, 12.0);
    final goalBadgePadV = (10 * scale).clamp(8.0, 10.0);
    final sectionGap = (20 * scale).clamp(16.0, 20.0);
    final lowerCardPadH = (16 * scale).clamp(12.0, 16.0);
    final lowerCardPadV = (14 * scale).clamp(12.0, 14.0);
    final lowerTextGap = (16 * scale).clamp(12.0, 16.0);
    final segmentGap = (8 * scale).clamp(6.0, 8.0);
    final timeUnitGap = (5 * scale).clamp(4.0, 5.0);
    final timeSectionGap = (12 * scale).clamp(8.0, 12.0);
    final secUnitGap = (4 * scale).clamp(3.0, 4.0);
    final detailsGap = (16 * scale).clamp(12.0, 16.0);
    final chevronGap = (4 * scale).clamp(3.0, 4.0);

    final headerIconSize = (20 * scale).clamp(16.0, 20.0);
    final headerFontSize = (18 * scale).clamp(16.0, 18.0);
    final lowerHelperFontSize = (18 * scale).clamp(15.0, 18.0);
    final timeFontSize = (40 * scale).clamp(34.0, 40.0);
    final unitFontSize = (15 * scale).clamp(12.0, 15.0);
    final pillFontSize = (12 * scale).clamp(10.0, 12.0);
    final statFontSize = (14 * scale).clamp(12.0, 14.0);
    final weekCircleSize = (34 * scale).clamp(28.0, 34.0);
    final weekIconSize = (weekCircleSize * 0.5).clamp(14.0, 18.0);
    final weekLabelSize = (11 * scale).clamp(9.0, 11.0);
    final detailsFontSize = (14 * scale).clamp(12.0, 14.0);
    final progressBarHeight = 12.0;
    const cardGradientStart = Color(0xFFF7EBDD);
    const cardGradientMid = Color(0xFFF4E6D7);
    const cardGradientEnd = Color(0xFFF2E1CF);
    const cardShadow = Color(0xFFCCB299);
    const surfaceColor = Color(0xFFFDFBF7);
    const surfaceBorder = Color(0xFFF1E2D1);
    const primaryTextColor = Color(0xFF2D170F);
    const secondaryTextColor = Color(0xFF6C4A3A);
    const accentColor = Color(0xFFD38A72);
    const accentStrong = Color(0xFFC55B45);
    const accentSoft = Color(0xFFE5C2A4);
    const iconBackground = Color(0xFFE9CFB5);

    return GestureDetector(
      onTap: onGoalTap ?? onStreakTap,
      child: Container(
        margin: EdgeInsets.only(bottom: outerMarginBottom),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          gradient: const LinearGradient(
            colors: [
              cardGradientStart,
              cardGradientMid,
              Color(0xFFF1E0CE),
              cardGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: cardShadow.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: glowTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: glowSize,
                  height: glowSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF0DCC6).withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                outerPadH,
                outerPadTop,
                outerPadH,
                outerPadBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconPad),
                        decoration: BoxDecoration(
                          color: iconBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: accentStrong,
                          size: headerIconSize,
                        ),
                      ),
                      SizedBox(width: headerGap),
                      Expanded(
                        child: Text(
                          "Today's Reading",
                          style: TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SF-UI-Display',
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: (10 * scale).clamp(8.0, 10.0),
                            vertical: (6 * scale).clamp(5.0, 6.0),
                          ),
                          decoration: BoxDecoration(
                            color: accentSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Goal done',
                            style: TextStyle(
                              fontSize: pillFontSize,
                              fontWeight: FontWeight.w700,
                              color: accentStrong,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: titleBottomGap),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      topCardPad,
                      topCardPad,
                      topCardPad,
                      topCardBottomPad,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(topCardRadius),
                      border: Border.all(color: surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$todayMinutes',
                                      style: TextStyle(
                                        fontSize: timeFontSize,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'SF-UI-Display',
                                        color: primaryTextColor,
                                        height: 1,
                                      ),
                                    ),
                                    SizedBox(width: timeUnitGap),
                                    Text(
                                      'min',
                                      style: TextStyle(
                                        fontSize: unitFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryTextColor,
                                        fontFamily: 'SF-UI-Display',
                                      ),
                                    ),
                                    SizedBox(width: timeSectionGap),
                                    Text(
                                      remainingSeconds.toString().padLeft(
                                        2,
                                        '0',
                                      ),
                                      style: TextStyle(
                                        fontSize: timeFontSize * 0.48,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'SF-UI-Display',
                                        color: primaryTextColor,
                                        height: 1,
                                      ),
                                    ),
                                    SizedBox(width: secUnitGap),
                                    Text(
                                      'sec',
                                      style: TextStyle(
                                        fontSize: unitFontSize - 1,
                                        fontWeight: FontWeight.w500,
                                        color: secondaryTextColor,
                                        fontFamily: 'SF-UI-Display',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: headerGap),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: goalBadgePadH,
                                vertical: goalBadgePadV,
                              ),
                              decoration: BoxDecoration(
                                color: accentSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Goal',
                                    style: TextStyle(
                                      fontSize: pillFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                      fontFamily: 'SF-UI-Display',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$goalMinutes min',
                                    style: TextStyle(
                                      fontSize: statFontSize + 2,
                                      fontWeight: FontWeight.w700,
                                      color: accentStrong,
                                      fontFamily: 'SF-UI-Display',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: lowerTextGap),
                        Row(
                          children: List.generate(4, (index) {
                            final threshold = (index + 1) / 4;
                            final fill = ((goalProgress - index / 4) * 4).clamp(
                              0.0,
                              1.0,
                            );
                            final isActive = goalProgress >= threshold;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 3 ? 0 : segmentGap,
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: progressBarHeight,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2E2D5),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: fill,
                                      child: Container(
                                        height: progressBarHeight,
                                        decoration: BoxDecoration(
                                          color: accentStrong,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow:
                                              isActive
                                                  ? [
                                                    BoxShadow(
                                                      color: accentColor
                                                          .withValues(
                                                            alpha: 0.24,
                                                          ),
                                                      blurRadius: 8,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: titleBottomGap),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                progressPillText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: pillFontSize + 1,
                                  fontFamily: 'SF-UI-Display',
                                ),
                              ),
                            ),
                            SizedBox(width: headerGap),
                            Text(
                              '${(goalProgress * 100).round()}%',
                              style: TextStyle(
                                color: accentStrong,
                                fontWeight: FontWeight.w700,
                                fontSize: pillFontSize + 1,
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: lowerCardPadH,
                      vertical: lowerCardPadV,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(lowerCardRadius),
                      border: Border.all(color: surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supportingText,
                          style: TextStyle(
                            fontSize: lowerHelperFontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: primaryTextColor,
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                        SizedBox(height: lowerTextGap),
                        Row(
                          children: [
                            Text(
                              'This week',
                              style: TextStyle(
                                fontSize: statFontSize,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                            SizedBox(width: headerGap),
                            Expanded(
                              child: Text(
                                streak > 0
                                    ? '$streak day${streak == 1 ? '' : 's'} going'
                                    : 'No streak yet',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: statFontSize - 1,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                  fontFamily: 'SF-UI-Display',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: titleBottomGap),
                        Row(
                          children: List.generate(7, (index) {
                            final day = weekDays[index];
                            final isToday = day == todayNorm;
                            final isFuture = day.isAfter(todayNorm);
                            final hasRead = weekReadDays.contains(day);

                            return Expanded(
                              child: _GoalWeekDayIndicator(
                                label: dayLabels[index],
                                isToday: isToday,
                                isFuture: isFuture,
                                hasRead: hasRead,
                                circleSize: weekCircleSize,
                                iconSize: weekIconSize,
                                labelSize: weekLabelSize,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: detailsGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See details',
                        style: TextStyle(
                          fontSize: detailsFontSize,
                          fontWeight: FontWeight.w600,
                          color: accentStrong,
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      SizedBox(width: chevronGap),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: accentStrong,
                        size: detailsFontSize + 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSupportingText({
    required int streak,
    required bool hasStarted,
    required bool isCompleted,
    required int remainingGoalMinutes,
    required int goalMinutes,
  }) {
    if (isCompleted) {
      return 'You hit your goal today. Keep reading to grow your streak.';
    }

    if (!hasStarted) {
      if (streak > 0) {
        return 'Start reading to keep your $streak-day streak alive.';
      }
      return 'Start reading to begin your streak and count today.';
    }

    if (remainingGoalMinutes <= 5) {
      return 'Just a little more and your $goalMinutes min goal is done. Keep going!';
    }

    return 'Read $remainingGoalMinutes more min to finish today\'s goal.';
  }

  String _buildProgressPillText({
    required bool hasStarted,
    required bool isCompleted,
    required int remainingGoalMinutes,
  }) {
    if (isCompleted) {
      return 'Goal reached';
    }
    if (!hasStarted) {
      return 'Start reading';
    }
    if (remainingGoalMinutes <= 5) {
      return 'Almost there';
    }
    return '$remainingGoalMinutes min left';
  }
}

class _GoalWeekDayIndicator extends StatelessWidget {
  final String label;
  final bool isToday;
  final bool isFuture;
  final bool hasRead;
  final double circleSize;
  final double iconSize;
  final double labelSize;

  const _GoalWeekDayIndicator({
    required this.label,
    required this.isToday,
    required this.isFuture,
    required this.hasRead,
    required this.circleSize,
    required this.iconSize,
    required this.labelSize,
  });

  @override
  Widget build(BuildContext context) {
    const primaryTextColor = Color(0xFF2D170F);
    const secondaryTextColor = Color(0xFF6C4A3A);
    const accentStrong = Color(0xFF4A2317);
    const accentSoft = Color(0xFFE4C29F);
    const mutedBorder = Color(0xFFE8D4C0);
    Widget circle;

    if (hasRead) {
      circle = Container(
        width: circleSize,
        height: circleSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: accentSoft,
        ),
        child: Icon(Icons.check_rounded, color: accentStrong, size: iconSize),
      );
    } else if (isToday) {
      circle = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF2DECB),
          border: Border.all(
            color: accentStrong.withValues(alpha: 0.5),
            width: 1.8,
          ),
        ),
        child: Icon(
          Icons.access_time_rounded,
          color: accentStrong,
          size: iconSize - 1,
        ),
      );
    } else if (isFuture) {
      circle = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE5C2A4).withValues(alpha: 0.72),
          border: Border.all(color: mutedBorder, width: 1.5),
        ),
      );
    } else {
      circle = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE5C2A4),
          border: Border.all(color: mutedBorder, width: 1.5),
        ),
        child: Icon(
          Icons.close_rounded,
          color: secondaryTextColor.withValues(alpha: 0.72),
          size: iconSize - 2,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? primaryTextColor : secondaryTextColor,
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakWidget extends ConsumerStatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final Set<DateTime> weekReadDays;
  final Set<DateTime> streakSaverDays;
  final VoidCallback? onSeeDetails;

  // Goal streak data
  final int goalStreak;
  final int longestGoalStreak;
  final int goalMinutes;
  final Set<DateTime> weekGoalDays;
  final VoidCallback? onSeeGoalDetails;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.weekReadDays = const {},
    this.streakSaverDays = const {},
    this.onSeeDetails,
    this.goalStreak = 0,
    this.longestGoalStreak = 0,
    this.goalMinutes = 30,
    this.weekGoalDays = const {},
    this.onSeeGoalDetails,
  });

  @override
  ConsumerState<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends ConsumerState<StreakWidget> {
  int _currentPage = 0;

  void _onHorizontalSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! < -200 && _currentPage == 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentPage = 1);
    } else if (details.primaryVelocity! > 200 && _currentPage == 1) {
      HapticFeedback.selectionClick();
      setState(() => _currentPage = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] as String? ?? 'Reader';
    final firstName = displayName.split(' ').first;

    final Widget currentCard =
        _currentPage == 0
            ? KeyedSubtree(
              key: const ValueKey(0),
              child: _StreakVisualizationCard(
                currentStreak: widget.currentStreak,
                firstName: firstName,
                weekReadDays: widget.weekReadDays,
                streakSaverDays: widget.streakSaverDays,
                onSeeDetails: widget.onSeeDetails,
              ),
            )
            : KeyedSubtree(
              key: const ValueKey(1),
              child: _GoalStreakCard(
                goalStreak: widget.goalStreak,
                longestGoalStreak: widget.longestGoalStreak,
                goalMinutes: widget.goalMinutes,
                firstName: firstName,
                weekGoalDays: widget.weekGoalDays,
                weekReadDays: widget.weekReadDays,
                onSeeDetails: widget.onSeeGoalDetails,
              ),
            );

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: _onHorizontalSwipe,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: currentCard,
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color:
                    isActive
                        ? (index == 0
                            ? const Color(0xFF8B6CF6)
                            : const Color(0xFFD97757))
                        : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Streak Visualization Card (gradient card from image) ─────────────────

class _StreakVisualizationCard extends StatelessWidget {
  final int currentStreak;
  final String firstName;
  final Set<DateTime> weekReadDays;
  final Set<DateTime> streakSaverDays;
  final VoidCallback? onSeeDetails;

  const _StreakVisualizationCard({
    required this.currentStreak,
    required this.firstName,
    required this.weekReadDays,
    this.streakSaverDays = const {},
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final iconContainerSize = (72 * scale).roundToDouble();
    final iconSize = (44 * scale).roundToDouble();
    final titleFontSize = (28 * scale).clamp(22.0, 28.0);
    final subtitleFontSize = (14 * scale).clamp(12.0, 14.0);
    final circleSize = (36 * scale).clamp(28.0, 36.0);
    final circleIconSize = (circleSize * 0.5).clamp(14.0, 20.0);
    final smallCircleIconSize = (circleSize * 0.44).clamp(12.0, 18.0);
    final dayLabelSize = (11 * scale).clamp(9.0, 11.0);
    final detailsFontSize = (15 * scale).clamp(13.0, 15.0);
    final outerPadH = (24 * scale).clamp(16.0, 24.0);
    final outerPadTop = (36 * scale).clamp(28.0, 36.0);

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Compute the start of the week (Saturday)
    final daysSinceSaturday = (today.weekday - 6 + 7) % 7;
    final weekStart = todayNorm.subtract(Duration(days: daysSinceSaturday));

    // Generate 7 days: Sat → Fri
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayLabels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    // Motivational text
    final motivationText =
        currentStreak > 0
            ? "You're doing really great, on fire, $firstName!"
            : 'Start reading today to build your streak, $firstName!';

    return GestureDetector(
      onTap: onSeeDetails,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B6CF6), Color(0xFF6C2CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CE7).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Content ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(outerPadH, outerPadTop, outerPadH, 20),
              child: Column(
                children: [
                  // Lightning bolt icon
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: iconSize,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: (20 * scale).clamp(14.0, 20.0)),

                  // Streak count text
                  Text(
                    '$currentStreak ${currentStreak == 1 ? 'Day' : 'Days'} Streak',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'SF-UI-Display',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Motivational text
                  Text(
                    motivationText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontFamily: 'SF-UI-Display',
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: (24 * scale).clamp(16.0, 24.0)),

                  // ─── Week day circles ────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (12 * scale).clamp(8.0, 12.0),
                      vertical: (14 * scale).clamp(10.0, 14.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: List.generate(7, (index) {
                        final day = weekDays[index];
                        final isToday = day == todayNorm;
                        final isFuture = day.isAfter(todayNorm);
                        final hasRead = weekReadDays.contains(day);
                        final isStreakSaver = streakSaverDays.contains(day);

                        return Expanded(
                          child: _buildDayCircle(
                            label: dayLabels[index],
                            isToday: isToday,
                            isFuture: isFuture,
                            hasRead: hasRead,
                            isStreakSaver: isStreakSaver,
                            circleSize: circleSize,
                            iconSize: circleIconSize,
                            smallIconSize: smallCircleIconSize,
                            labelSize: dayLabelSize,
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: (16 * scale).clamp(12.0, 16.0)),

                  // See Details link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See Details',
                        style: TextStyle(
                          fontSize: detailsFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: (20 * scale).clamp(16.0, 20.0),
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

  Widget _buildDayCircle({
    required String label,
    required bool isToday,
    required bool isFuture,
    required bool hasRead,
    required bool isStreakSaver,
    required double circleSize,
    required double iconSize,
    required double smallIconSize,
    required double labelSize,
  }) {
    Widget circleContent;

    if (isStreakSaver) {
      // Streak saver day — green with shield icon
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.shield_rounded, color: Colors.white, size: smallIconSize),
      );
    } else if (isToday) {
      // Current day: clock icon
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: hasRead ? 0.25 : 0.2),
          border:
              hasRead
                  ? null
                  : Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
        ),
        child: Icon(
          Icons.access_time_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: smallIconSize,
        ),
      );
    } else if (!isFuture && hasRead) {
      // Past day with reading: blue checkmark
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: iconSize),
      );
    } else if (!isFuture && !hasRead) {
      // Past day without reading: red-tinted missed day
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE53935).withValues(alpha: 0.2),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          color: const Color(0xFFFF8A80).withValues(alpha: 0.9),
          size: smallIconSize,
        ),
      );
    } else {
      // Future day: empty circle
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 2,
          ),
          color: Colors.white.withValues(alpha: 0.06),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circleContent,
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.65),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }
}

// ─── Goal Streak Card ─────────────────────────────────────────────────────

class _GoalStreakCard extends StatelessWidget {
  final int goalStreak;
  final int longestGoalStreak;
  final int goalMinutes;
  final String firstName;
  final Set<DateTime> weekGoalDays;
  final Set<DateTime> weekReadDays;
  final VoidCallback? onSeeDetails;

  const _GoalStreakCard({
    required this.goalStreak,
    required this.longestGoalStreak,
    required this.goalMinutes,
    required this.firstName,
    required this.weekGoalDays,
    required this.weekReadDays,
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final iconContainerSize = (72 * scale).roundToDouble();
    final iconSize = (44 * scale).roundToDouble();
    final titleFontSize = (28 * scale).clamp(22.0, 28.0);
    final subtitleFontSize = (14 * scale).clamp(12.0, 14.0);
    final circleSize = (36 * scale).clamp(28.0, 36.0);
    final circleIconSize = (circleSize * 0.5).clamp(14.0, 20.0);
    final smallCircleIconSize = (circleSize * 0.44).clamp(12.0, 18.0);
    final dayLabelSize = (11 * scale).clamp(9.0, 11.0);
    final detailsFontSize = (15 * scale).clamp(13.0, 15.0);
    final outerPadH = (24 * scale).clamp(16.0, 24.0);
    final outerPadTop = (36 * scale).clamp(28.0, 36.0);

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final daysSinceSaturday = (today.weekday - 6 + 7) % 7;
    final weekStart = todayNorm.subtract(Duration(days: daysSinceSaturday));

    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayLabels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    final motivationText =
        goalStreak > 0
            ? 'You\'ve hit your $goalMinutes min goal $goalStreak days in a row!'
            : 'Read $goalMinutes min today to start your goal streak!';

    return GestureDetector(
      onTap: onSeeDetails,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFD97757), Color(0xFFB85C38)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97757).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(outerPadH, outerPadTop, outerPadH, 20),
              child: Column(
                children: [
                  // Target icon
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: iconSize,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: (20 * scale).clamp(14.0, 20.0)),

                  Text(
                    '$goalStreak ${goalStreak == 1 ? 'Day' : 'Days'} Goal Streak',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'SF-UI-Display',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    motivationText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontFamily: 'SF-UI-Display',
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: (24 * scale).clamp(16.0, 24.0)),

                  // Week day circles — goal achieved variant
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (12 * scale).clamp(8.0, 12.0),
                      vertical: (14 * scale).clamp(10.0, 14.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: List.generate(7, (index) {
                        final day = weekDays[index];
                        final isToday = day == todayNorm;
                        final isFuture = day.isAfter(todayNorm);
                        final goalAchieved = weekGoalDays.contains(day);
                        final hasRead = weekReadDays.contains(day);

                        return Expanded(
                          child: _buildGoalDayCircle(
                            label: dayLabels[index],
                            isToday: isToday,
                            isFuture: isFuture,
                            goalAchieved: goalAchieved,
                            hasRead: hasRead,
                            circleSize: circleSize,
                            iconSize: circleIconSize,
                            smallIconSize: smallCircleIconSize,
                            labelSize: dayLabelSize,
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: (16 * scale).clamp(12.0, 16.0)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See Details',
                        style: TextStyle(
                          fontSize: detailsFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: (20 * scale).clamp(16.0, 20.0),
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

  Widget _buildGoalDayCircle({
    required String label,
    required bool isToday,
    required bool isFuture,
    required bool goalAchieved,
    required bool hasRead,
    required double circleSize,
    required double iconSize,
    required double smallIconSize,
    required double labelSize,
  }) {
    Widget circleContent;

    if (isToday) {
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: goalAchieved ? 0.25 : 0.2),
          border:
              goalAchieved
                  ? null
                  : Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
        ),
        child: Icon(
          goalAchieved ? Icons.check_rounded : Icons.access_time_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: smallIconSize,
        ),
      );
    } else if (!isFuture && goalAchieved) {
      // Goal achieved — golden checkmark
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: iconSize),
      );
    } else if (!isFuture && hasRead && !goalAchieved) {
      // Read but didn't meet goal — partial (amber-ish)
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber.withValues(alpha: 0.25),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.remove_rounded,
          color: Colors.white.withValues(alpha: 0.7),
          size: smallIconSize,
        ),
      );
    } else if (!isFuture && !hasRead) {
      // Missed day
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE53935).withValues(alpha: 0.2),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          color: const Color(0xFFFF8A80).withValues(alpha: 0.9),
          size: smallIconSize,
        ),
      );
    } else {
      // Future day
      circleContent = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 2,
          ),
          color: Colors.white.withValues(alpha: 0.06),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circleContent,
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.65),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:biblio/core/services/streak_service.dart';
import 'package:biblio/Homescreen/pages/streak/day_detail_screen.dart';

class GoalStreakDetailsScreen extends StatefulWidget {
  final int goalStreak;
  final int longestGoalStreak;
  final int goalMinutes;

  const GoalStreakDetailsScreen({
    super.key,
    required this.goalStreak,
    required this.longestGoalStreak,
    required this.goalMinutes,
  });

  @override
  State<GoalStreakDetailsScreen> createState() =>
      _GoalStreakDetailsScreenState();
}

class _GoalStreakDetailsScreenState extends State<GoalStreakDetailsScreen> {
  static const Color _bg = Color(0xFFFCF9F5);
  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _calendarBg = Color(0xFF2E1A0E);

  final StreakService _streakService = StreakService();
  Map<DateTime, int> _heatmapData = {};
  bool _dataLoading = true;
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month, 1);
    _loadData();
  }

  Future<void> _loadData() async {
    final heatmap = await _streakService.getReadingHeatmapData(months: 4);
    if (mounted) {
      setState(() {
        _heatmapData = heatmap;
        _dataLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final titleSize = (32 * scale).clamp(26.0, 32.0);
    final padH = (20 * scale).clamp(16.0, 20.0);
    final padBottom = (40 * scale).clamp(32.0, 40.0);
    final gap20 = (20 * scale).clamp(16.0, 20.0);
    final gap28 = (28 * scale).clamp(22.0, 28.0);

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
              'Goal Streak',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          padH,
          (16 * scale).clamp(12.0, 16.0),
          padH,
          padBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalHero(scale),
            SizedBox(height: gap20),
            _buildGoalInfoCard(scale),
            SizedBox(height: gap20),
            _buildCalendarSection(scale),
            SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
            _buildWeeklyGoalStat(scale),
            SizedBox(height: gap28),
          ],
        ),
      ),
    );
  }

  // ─── Hero Card ────────────────────────────────────────────────────────

  Widget _buildGoalHero(double scale) {
    const gradientColors = [Color(0xFFD97757), Color(0xFFB85C38)];
    final heroPadding = (24 * scale).clamp(18.0, 24.0);
    final iconCircleSize = (72 * scale).clamp(60.0, 72.0);
    final iconSize = (36 * scale).clamp(30.0, 36.0);
    final titleSize = (28 * scale).clamp(22.0, 28.0);
    final subtitleSize = (13 * scale).clamp(11.0, 13.0);
    final statNumberSize = (22 * scale).clamp(18.0, 22.0);
    final statLabelSize = (12 * scale).clamp(10.0, 12.0);
    final streakLabel = widget.goalStreak == 1 ? 'Day' : 'Days';

    String subtitle;
    if (widget.goalStreak == 0) {
      subtitle =
          'Read ${widget.goalMinutes} min today to start your goal streak!';
    } else if (widget.goalStreak < 7) {
      subtitle = 'Great start — keep hitting your daily goal!';
    } else if (widget.goalStreak < 30) {
      subtitle = 'Amazing discipline! Keep the momentum going!';
    } else {
      subtitle = 'Legendary consistency — you\'re unstoppable!';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(heroPadding),
        child: Column(
          children: [
            Container(
              width: iconCircleSize,
              height: iconCircleSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(height: (14 * scale).clamp(10.0, 14.0)),
            Text(
              '${widget.goalStreak} $streakLabel',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'SF-UI-Display',
                height: 1.1,
              ),
            ),
            SizedBox(height: (12 * scale).clamp(8.0, 12.0)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
            // Current vs Longest row
            Container(
              padding: EdgeInsets.symmetric(
                vertical: (12 * scale).clamp(10.0, 12.0),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${widget.goalStreak}',
                          style: TextStyle(
                            fontSize: statNumberSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                        SizedBox(height: (2 * scale).roundToDouble()),
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: statLabelSize,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: (32 * scale).clamp(26.0, 32.0),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${widget.longestGoalStreak}',
                          style: TextStyle(
                            fontSize: statNumberSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                        SizedBox(height: (2 * scale).roundToDouble()),
                        Text(
                          'Best Streak',
                          style: TextStyle(
                            fontSize: statLabelSize,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Goal Info Card ───────────────────────────────────────────────────

  Widget _buildGoalInfoCard(double scale) {
    final cardPad = (20 * scale).clamp(16.0, 20.0);
    final iconBox = (52 * scale).clamp(44.0, 52.0);
    final iconSize = (28 * scale).clamp(22.0, 28.0);
    final labelSize = (13 * scale).clamp(11.0, 13.0);
    final valueSize = (20 * scale).clamp(16.0, 20.0);
    final badgeSize = (13 * scale).clamp(11.0, 13.0);
    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.track_changes_rounded,
              color: Color(0xFFD97757),
              size: iconSize,
            ),
          ),
          SizedBox(width: (16 * scale).clamp(12.0, 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Daily Goal',
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                SizedBox(height: (2 * scale).roundToDouble()),
                Text(
                  '${widget.goalMinutes} minutes per day',
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    fontFamily: 'SF-UI-Display',
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (12 * scale).clamp(10.0, 12.0),
              vertical: (6 * scale).clamp(5.0, 6.0),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD97757).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 14,
                  color: Color(0xFFD97757),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.goalStreak}',
                  style: TextStyle(
                    fontSize: badgeSize,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97757),
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

  // ─── Calendar Section ─────────────────────────────────────────────────

  Widget _buildCalendarSection(double scale) {
    final sectionTitleSize = (18 * scale).clamp(15.0, 18.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Activity',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.w700,
            color: _textDark,
            fontFamily: 'SF-UI-Display',
          ),
        ),
        SizedBox(height: (14 * scale).clamp(10.0, 14.0)),
        _buildCalendarView(scale),
      ],
    );
  }

  Widget _buildCalendarView(double scale) {
    final calendarHeight = (280 * scale).clamp(236.0, 280.0);
    final calPadX = (18 * scale).clamp(14.0, 18.0);
    final calPadTop = (18 * scale).clamp(14.0, 18.0);
    final calPadBottom = (20 * scale).clamp(16.0, 20.0);
    final navBox = (32 * scale).clamp(28.0, 32.0);
    final navIcon = (20 * scale).clamp(17.0, 20.0);
    final monthFont = (16 * scale).clamp(14.0, 16.0);
    final dowFont = (12 * scale).clamp(10.0, 12.0);
    final dayCellHeight = (42 * scale).clamp(36.0, 42.0);
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(
      _calendarMonth.year,
      _calendarMonth.month,
    );
    final firstWeekday =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday % 7;
    final totalSlots = firstWeekday + daysInMonth;
    final rows = (totalSlots / 7).ceil();
    final isCurrentMonth =
        _calendarMonth.year == now.year && _calendarMonth.month == now.month;

    final goalSeconds = widget.goalMinutes * 60;

    if (_dataLoading) {
      return Container(
        height: calendarHeight,
        decoration: BoxDecoration(
          color: _calendarBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD97757),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _calendarBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97757).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(calPadX, calPadTop, calPadX, calPadBottom),
        child: Column(
          children: [
            // Month header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _calendarMonth = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month - 1,
                        1,
                      );
                    });
                  },
                  child: Container(
                    width: navBox,
                    height: navBox,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: navIcon,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_calendarMonth),
                  style: TextStyle(
                    fontSize: monthFont,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                GestureDetector(
                  onTap:
                      isCurrentMonth
                          ? null
                          : () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _calendarMonth = DateTime(
                                _calendarMonth.year,
                                _calendarMonth.month + 1,
                                1,
                              );
                            });
                          },
                  child: AnimatedOpacity(
                    opacity: isCurrentMonth ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: navBox,
                      height: navBox,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: navIcon,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: (18 * scale).clamp(14.0, 18.0)),

            // Day-of-week headers
            Row(
              children:
                  ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: dowFont,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.4),
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: (10 * scale).clamp(8.0, 10.0)),

            // Calendar grid
            ...List.generate(rows, (rowIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: (6 * scale).clamp(4.0, 6.0)),
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final slotIndex = rowIndex * 7 + colIndex;
                    final dayNumber = slotIndex - firstWeekday + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return Expanded(child: SizedBox(height: dayCellHeight));
                    }

                    final date = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month,
                      dayNumber,
                    );
                    final isToday = date == todayNorm;
                    final isFuture = date.isAfter(todayNorm);
                    final seconds = _heatmapData[date] ?? 0;
                    final goalAchieved = seconds >= goalSeconds;
                    final hasRead = seconds > 0;

                    return Expanded(
                      child: GestureDetector(
                        onTap:
                            isFuture
                                ? null
                                : () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DayDetailScreen(
                                            date: date,
                                            heatmapData: _heatmapData,
                                          ),
                                    ),
                                  );
                                },
                        child: _buildCalendarDay(
                          scale: scale,
                          dayNumber: dayNumber,
                          isToday: isToday,
                          isFuture: isFuture,
                          goalAchieved: goalAchieved,
                          hasRead: hasRead,
                          seconds: seconds,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),

            SizedBox(height: (14 * scale).clamp(10.0, 14.0)),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFFD97757), 'Goal Met', scale),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
                _buildLegendItem(
                  Colors.amber.withValues(alpha: 0.35),
                  'Partial',
                  scale,
                ),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
                _buildLegendItem(
                  const Color(0xFFE53935).withValues(alpha: 0.15),
                  'Missed',
                  scale,
                ),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
                _buildLegendDot('Today', scale),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay({
    required double scale,
    required int dayNumber,
    required bool isToday,
    required bool isFuture,
    required bool goalAchieved,
    required bool hasRead,
    required int seconds,
  }) {
    final dayCellHeight = (42 * scale).clamp(36.0, 42.0);
    final dayFont = (14 * scale).clamp(12.0, 14.0);
    final markerInset = (3 * scale).roundToDouble();
    final markerSize = (10 * scale).clamp(8.0, 10.0);
    Color bgColor;
    Color textColor;

    if (isFuture) {
      bgColor = Colors.transparent;
      textColor = Colors.white.withValues(alpha: 0.15);
    } else if (goalAchieved) {
      // Goal achieved — warm gradient intensity
      final intensity = _getGoalIntensity(seconds);
      switch (intensity) {
        case 1:
          bgColor = const Color(0xFFD97757).withValues(alpha: 0.5);
        case 2:
          bgColor = const Color(0xFFD97757).withValues(alpha: 0.7);
        case 3:
          bgColor = const Color(0xFFD97757).withValues(alpha: 0.85);
        case 4:
          bgColor = const Color(0xFFD97757);
        default:
          bgColor = const Color(0xFFD97757).withValues(alpha: 0.5);
      }
      textColor = Colors.white;
    } else if (hasRead) {
      // Read but didn't meet goal — amber partial
      bgColor = Colors.amber.withValues(alpha: 0.2);
      textColor = Colors.amber.shade200;
    } else {
      // Missed
      bgColor = const Color(0xFFE53935).withValues(alpha: 0.15);
      textColor = const Color(0xFFFF8A80);
    }

    return Container(
      height: dayCellHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border:
            isToday
                ? Border.all(color: const Color(0xFFD97757), width: 2)
                : null,
        boxShadow:
            goalAchieved && !isFuture
                ? [
                  BoxShadow(
                    color: const Color(0xFFD97757).withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$dayNumber',
            style: TextStyle(
              fontSize: dayFont,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          if (goalAchieved && !isFuture)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.check_circle_rounded,
                size: markerSize,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          if (!isFuture && !isToday && hasRead && !goalAchieved)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.remove_circle_outline_rounded,
                size: markerSize,
                color: Colors.amber.withValues(alpha: 0.7),
              ),
            ),
          if (!isFuture && !isToday && !hasRead)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.close_rounded,
                size: markerSize,
                color: const Color(0xFFE53935).withValues(alpha: 0.7),
              ),
            ),
          if (isToday)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.access_time_rounded,
                size: markerSize,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: (12 * scale).clamp(10.0, 12.0),
          height: (12 * scale).clamp(10.0, 12.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: (6 * scale).clamp(4.0, 6.0)),
        Text(
          label,
          style: TextStyle(
            fontSize: (11 * scale).clamp(9.0, 11.0),
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(String label, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: (12 * scale).clamp(10.0, 12.0),
          height: (12 * scale).clamp(10.0, 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD97757), width: 1.5),
          ),
        ),
        SizedBox(width: (6 * scale).clamp(4.0, 6.0)),
        Text(
          label,
          style: TextStyle(
            fontSize: (11 * scale).clamp(9.0, 11.0),
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }

  // ─── Weekly Goal Stat ─────────────────────────────────────────────────

  Widget _buildWeeklyGoalStat(double scale) {
    final cardPadH = (20 * scale).clamp(16.0, 20.0);
    final cardPadV = (16 * scale).clamp(12.0, 16.0);
    final iconBox = (44 * scale).clamp(38.0, 44.0);
    final iconSize = (24 * scale).clamp(20.0, 24.0);
    final labelSize = (13 * scale).clamp(11.0, 13.0);
    final valueSize = (22 * scale).clamp(18.0, 22.0);
    final badgeSize = (12 * scale).clamp(10.0, 12.0);
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    final daysSinceSat = (now.weekday - 6 + 7) % 7;
    final weekStart = todayNorm.subtract(Duration(days: daysSinceSat));
    final goalSeconds = widget.goalMinutes * 60;
    int daysGoalMet = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final s = _heatmapData[day] ?? 0;
      if (s >= goalSeconds) daysGoalMet++;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: cardPadH, vertical: cardPadV),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFD97757),
              size: iconSize,
            ),
          ),
          SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                SizedBox(height: (2 * scale).roundToDouble()),
                Text(
                  '$daysGoalMet day${daysGoalMet == 1 ? '' : 's'} goal met',
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    fontFamily: 'SF-UI-Display',
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (12 * scale).clamp(10.0, 12.0),
              vertical: (6 * scale).clamp(5.0, 6.0),
            ),
            decoration: BoxDecoration(
              color:
                  daysGoalMet >= 5
                      ? const Color(0xFF43A047).withValues(alpha: 0.10)
                      : const Color(0xFFD97757).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$daysGoalMet / 7 days',
              style: TextStyle(
                fontSize: badgeSize,
                fontWeight: FontWeight.w600,
                color:
                    daysGoalMet >= 5
                        ? const Color(0xFF43A047)
                        : const Color(0xFFD97757),
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  int _getGoalIntensity(int totalSeconds) {
    final minutes = totalSeconds / 60;
    final goalMin = widget.goalMinutes;
    if (minutes < goalMin) return 0;
    final ratio = minutes / goalMin;
    if (ratio < 1.25) return 1;
    if (ratio < 1.5) return 2;
    if (ratio < 2.0) return 3;
    return 4;
  }
}

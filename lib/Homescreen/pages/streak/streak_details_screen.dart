import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:biblio/core/services/streak_service.dart';
import 'package:biblio/features/gamification/screens/streak_saver_screen.dart';
import 'package:biblio/Homescreen/pages/streak/day_detail_screen.dart';

class StreakDetailsScreen extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final Set<DateTime> weekReadDays;

  const StreakDetailsScreen({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.weekReadDays,
  });

  @override
  State<StreakDetailsScreen> createState() => _StreakDetailsScreenState();
}

class _StreakDetailsScreenState extends State<StreakDetailsScreen> {
  static const Color _bg = Color(0xFFFCF9F5);
  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);

  // Calendar dark theme
  static const Color _calendarBg = Color(0xFF1A1A2E);

  final StreakService _streakService = StreakService();
  Map<DateTime, int> _heatmapData = {};
  Set<DateTime> _streakSaverDays = {};
  bool _dataLoading = true;
  late DateTime _calendarMonth; // current month being shown in calendar

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month, 1);
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _streakService.getReadingHeatmapData(months: 4),
      _streakService.getStreakSaverDays(months: 4),
    ]);
    if (mounted) {
      setState(() {
        _heatmapData = results[0] as Map<DateTime, int>;
        _streakSaverDays = results[1] as Set<DateTime>;
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
              'Streak Details',
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
            _buildStreakHero(scale),
            SizedBox(height: gap20),
            _buildStreakSaverCard(scale),
            SizedBox(height: gap20),
            _buildHeatmapSection(scale),
            SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
            _buildWeeklyReadingStat(scale),
            SizedBox(height: gap28),
          ],
        ),
      ),
    );
  }

  // ─── Hero Card (matching LevelsScreen style) ─────────────────────────

  Widget _buildStreakHero(double scale) {
    const gradientColors = [Color(0xFF8B6CF6), Color(0xFF5B4AE8)];
    final heroPadding = (24 * scale).clamp(18.0, 24.0);
    final iconCircleSize = (72 * scale).clamp(60.0, 72.0);
    final iconSize = (36 * scale).clamp(30.0, 36.0);
    final titleSize = (28 * scale).clamp(22.0, 28.0);
    final subtitleSize = (13 * scale).clamp(11.0, 13.0);
    final statNumberSize = (22 * scale).clamp(18.0, 22.0);
    final statLabelSize = (12 * scale).clamp(10.0, 12.0);
    final streakLabel = widget.currentStreak == 1 ? 'Day' : 'Days';

    String subtitle;
    if (widget.currentStreak == 0) {
      subtitle = 'Start reading to build your streak!';
    } else if (widget.currentStreak < 7) {
      subtitle = 'Great start — keep the momentum going!';
    } else if (widget.currentStreak < 30) {
      subtitle = 'Impressive consistency, keep it up!';
    } else {
      subtitle = 'Incredible dedication — you\'re unstoppable!';
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
            // Icon circle
            Container(
              width: iconCircleSize,
              height: iconCircleSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(height: (14 * scale).clamp(10.0, 14.0)),
            // Streak count
            Text(
              '${widget.currentStreak} $streakLabel',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'SF-UI-Display',
                height: 1.1,
              ),
            ),

            SizedBox(height: (12 * scale).clamp(8.0, 12.0)),

            // Subtitle
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
                          '${widget.currentStreak}',
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
                          '${widget.longestStreak}',
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

  // ─── Weekly Reading Stat ──────────────────────────────────────────────

  Widget _buildWeeklyReadingStat(double scale) {
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
    int weekSeconds = 0;
    int daysRead = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final s = _heatmapData[day] ?? 0;
      weekSeconds += s;
      if (s > 0) daysRead++;
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
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.timer_rounded,
              color: Color(0xFF42A5F5),
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
                  _formatMinutes(weekSeconds ~/ 60),
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
              color: const Color(0xFF43A047).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$daysRead / 7 days',
              style: TextStyle(
                fontSize: badgeSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFF43A047),
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reading Activity Section — Calendar only ──────────────────────

  Widget _buildHeatmapSection(double scale) {
    final sectionTitleSize = (18 * scale).clamp(15.0, 18.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Activity',
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

  // ─── Calendar View ────────────────────────────────────────────────────

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
    // Sunday = 0 based (DateTime.sunday == 7, so convert)
    final firstWeekday =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday %
        7; // 0=Sun
    final totalSlots = firstWeekday + daysInMonth;
    final rows = (totalSlots / 7).ceil();
    final isCurrentMonth =
        _calendarMonth.year == now.year && _calendarMonth.month == now.month;

    if (_dataLoading) {
      return Container(
        height: calendarHeight,
        decoration: BoxDecoration(
          color: _calendarBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B6CF6),
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
            color: const Color(0xFF8B6CF6).withValues(alpha: 0.15),
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
            // ── Month header with arrows ──
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

            // ── Day-of-week headers ──
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

            // ── Calendar grid ──
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
                    final hasRead = seconds > 0;
                    final isStreakSaver = _streakSaverDays.contains(date);

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
                          hasRead: hasRead,
                          seconds: seconds,
                          isStreakSaver: isStreakSaver,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),

            SizedBox(height: (14 * scale).clamp(10.0, 14.0)),

            // ── Legend ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCalendarLegendItem(
                  const Color(0xFF8B6CF6),
                  'Active',
                  scale,
                ),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
                _buildCalendarLegendItem(
                  const Color(0xFFE53935).withValues(alpha: 0.15),
                  'Missed',
                  scale,
                ),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
                _buildCalendarLegendIcon(
                  Icons.shield_rounded,
                  const Color(0xFF4CAF50),
                  'Saver',
                  scale,
                ),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
                _buildCalendarLegendDot('Today', scale),
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
    required bool hasRead,
    required int seconds,
    required bool isStreakSaver,
  }) {
    final dayCellHeight = (42 * scale).clamp(36.0, 42.0);
    final dayFont = (14 * scale).clamp(12.0, 14.0);
    final saverDayFont = (12 * scale).clamp(10.0, 12.0);
    final markerInset = (3 * scale).roundToDouble();
    final shieldIcon = (10 * scale).clamp(8.0, 10.0);
    final closeIcon = (9 * scale).clamp(7.0, 9.0);
    Color bgColor;
    Color textColor;

    if (isFuture) {
      bgColor = Colors.transparent;
      textColor = Colors.white.withValues(alpha: 0.15);
    } else if (isStreakSaver) {
      // Streak saver day — green tinted
      bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.25);
      textColor = Colors.white;
    } else if (hasRead) {
      final intensity = _getIntensity(seconds);
      switch (intensity) {
        case 1:
          bgColor = const Color(0xFF6B4FB3).withValues(alpha: 0.5);
        case 2:
          bgColor = const Color(0xFF7B5FD3).withValues(alpha: 0.7);
        case 3:
          bgColor = const Color(0xFF8B6CF6).withValues(alpha: 0.85);
        case 4:
          bgColor = const Color(0xFF9D7FF7);
        default:
          bgColor = const Color(0xFF6B4FB3).withValues(alpha: 0.4);
      }
      textColor = Colors.white;
    } else if (!isFuture && !hasRead) {
      // Missed past day — subtle red tint
      bgColor = const Color(0xFFE53935).withValues(alpha: 0.15);
      textColor = const Color(0xFFFF8A80);
    } else {
      bgColor = Colors.white.withValues(alpha: 0.05);
      textColor = Colors.white.withValues(alpha: 0.4);
    }

    return Container(
      height: dayCellHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border:
            isToday
                ? Border.all(color: const Color(0xFFAE8FF7), width: 2)
                : null,
        boxShadow:
            (hasRead || isStreakSaver) && !isFuture
                ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Day number
          Text(
            '$dayNumber',
            style: TextStyle(
              fontSize: isStreakSaver ? saverDayFont : dayFont,
              fontWeight:
                  isToday || hasRead || isStreakSaver
                      ? FontWeight.w700
                      : FontWeight.w500,
              color: textColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          // Streak saver shield icon — bottom-right
          if (isStreakSaver)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.shield_rounded,
                size: shieldIcon,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.9),
              ),
            ),
          // Missed day — small X bottom-right
          if (!isFuture && !isToday && !hasRead && !isStreakSaver)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.close_rounded,
                size: closeIcon,
                color: const Color(0xFFE53935).withValues(alpha: 0.7),
              ),
            ),
          // Today clock icon — bottom-right
          if (isToday && !isStreakSaver)
            Positioned(
              right: markerInset,
              bottom: markerInset,
              child: Icon(
                Icons.access_time_rounded,
                size: shieldIcon,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegendItem(Color color, String label, double scale) {
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

  Widget _buildCalendarLegendDot(String label, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: (12 * scale).clamp(10.0, 12.0),
          height: (12 * scale).clamp(10.0, 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFAE8FF7), width: 1.5),
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

  Widget _buildCalendarLegendIcon(
    IconData icon,
    Color color,
    String label,
    double scale,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: (12 * scale).clamp(10.0, 12.0), color: color),
        SizedBox(width: (4 * scale).clamp(3.0, 4.0)),
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

  // ─── Streak Saver CTA ─────────────────────────────────────────────────

  Widget _buildStreakSaverCard(double scale) {
    final cardPadding = (20 * scale).clamp(16.0, 20.0);
    final iconBox = (52 * scale).clamp(44.0, 52.0);
    final iconSize = (28 * scale).clamp(22.0, 28.0);
    final titleSize = (17 * scale).clamp(14.0, 17.0);
    final subtitleSize = (13 * scale).clamp(11.0, 13.0);
    final chevronBox = (36 * scale).clamp(30.0, 36.0);
    final chevronSize = (22 * scale).clamp(18.0, 22.0);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StreakSaverScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(width: (16 * scale).clamp(12.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Saver',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  SizedBox(height: (4 * scale).roundToDouble()),
                  Text(
                    'Protect your streak on rest days',
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: chevronBox,
              height: chevronBox,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: chevronSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  int _getIntensity(int totalSeconds) {
    if (totalSeconds == 0) return 0;
    final minutes = totalSeconds / 60;
    if (minutes < 5) return 1;
    if (minutes < 15) return 2;
    if (minutes < 30) return 3;
    return 4;
  }

  String _formatMinutes(int minutes) {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }
}

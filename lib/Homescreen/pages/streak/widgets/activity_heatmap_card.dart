import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biblio/core/services/streak_service.dart';

class ActivityHeatmapCard extends StatefulWidget {
  const ActivityHeatmapCard({super.key});

  @override
  State<ActivityHeatmapCard> createState() => _ActivityHeatmapCardState();
}

class _ActivityHeatmapCardState extends State<ActivityHeatmapCard> {
  final StreakService _streakService = StreakService();
  Map<DateTime, int> _heatmapData = {};
  bool _isLoading = true;

  static const cardColor = Colors.white;
  static const textDark = Color(0xFF2D2D2D);
  static const textGrey = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _streakService.getReadingHeatmapData(months: 3);
    if (mounted) {
      setState(() {
        _heatmapData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerFontSize = (18 * scale).clamp(15.0, 18.0);
    final subFontSize = (13 * scale).clamp(11.0, 13.0);
    final tinyFontSize = (11 * scale).clamp(9.0, 11.0);
    final dayLabelFontSize = (10 * scale).clamp(8.0, 10.0);
    final padAll = (16 * scale).clamp(12.0, 16.0);

    final now = DateTime.now();
    final months = List.generate(3, (i) {
      final m = DateTime(now.year, now.month - (2 - i), 1);
      return m;
    });

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reading Activity',
              style: TextStyle(
                fontSize: headerFontSize,
                fontWeight: FontWeight.w600,
                color: textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            Text(
              'Last 3 months',
              style: TextStyle(
                fontSize: subFontSize,
                color: textGrey,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(padAll),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD97757),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                  : Column(
                    children: [
                      // Month labels
                      Row(
                        children:
                            months.map((m) {
                              return Expanded(
                                child: Text(
                                  DateFormat('MMM').format(m),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: textGrey,
                                    fontFamily: 'SF-UI-Display',
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Day labels + grids
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day-of-week labels
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Column(
                              children:
                                  ['M', '', 'W', '', 'F', '', 'S']
                                      .map(
                                        (d) => SizedBox(
                                          height: 16,
                                          child: Text(
                                            d,
                                            style: TextStyle(
                                              fontSize: dayLabelFontSize,
                                              color: textGrey,
                                              fontFamily: 'SF-UI-Display',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),

                          // Month grids
                          ...months.map((month) {
                            return Expanded(child: _buildMonthGrid(month));
                          }),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Less',
                            style: TextStyle(
                              fontSize: tinyFontSize,
                              color: textGrey,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                          const SizedBox(width: 6),
                          ...List.generate(5, (i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: _getHeatmapColor(i),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            'More',
                            style: TextStyle(
                              fontSize: tinyFontSize,
                              color: textGrey,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfWeek =
        DateTime(month.year, month.month, 1).weekday; // 1=Mon, 7=Sun
    final today = DateTime.now();

    // Calculate number of weeks needed
    final totalSlots = firstDayOfWeek - 1 + daysInMonth;
    final weeks = (totalSlots / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = ((constraints.maxWidth - (weeks - 1) * 4) / weeks)
            .clamp(8.0, 14.0);
        final spacing = 3.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(weeks, (weekIndex) {
            return Padding(
              padding: EdgeInsets.only(
                right: weekIndex < weeks - 1 ? spacing : 0,
              ),
              child: Column(
                children: List.generate(7, (dayIndex) {
                  final dayNumber =
                      weekIndex * 7 + dayIndex - (firstDayOfWeek - 2);

                  // Empty cell (before month starts or after month ends)
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return SizedBox(
                      width: cellSize,
                      height: cellSize + spacing,
                    );
                  }

                  final date = DateTime(month.year, month.month, dayNumber);
                  final isFuture = date.isAfter(today);
                  final seconds = _heatmapData[date] ?? 0;
                  final intensity = isFuture ? -1 : _getIntensity(seconds);

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: Tooltip(
                      message:
                          isFuture
                              ? ''
                              : '${DateFormat('MMM d').format(date)}: ${_formatTime(seconds)}',
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color:
                              isFuture
                                  ? Colors.transparent
                                  : _getHeatmapColor(intensity),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  /// Convert total_seconds into an intensity level (0-4)
  int _getIntensity(int totalSeconds) {
    if (totalSeconds == 0) return 0;
    final minutes = totalSeconds / 60;
    if (minutes < 5) return 1; // < 5 min
    if (minutes < 15) return 2; // 5-15 min
    if (minutes < 30) return 3; // 15-30 min
    return 4; // 30+ min
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0:
        return const Color(0xFFF0EDED);
      case 1:
        return const Color(0xFFEAC8BC);
      case 2:
        return const Color(0xFFDFA896);
      case 3:
        return const Color(0xFFD48870);
      case 4:
        return const Color(0xFFC7684B);
      default:
        return Colors.transparent;
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds == 0) return 'No reading';
    final minutes = totalSeconds ~/ 60;
    if (minutes < 1) return '${totalSeconds}s';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) return '${hours}h ${remainingMinutes}m';
    return '${minutes}m';
  }
}

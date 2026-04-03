import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/services/streak_service.dart';
import 'package:biblio/core/services/xp_service.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/Homescreen/pages/streak/day_detail_screen.dart';

class ReadingStatsScreen extends ConsumerStatefulWidget {
  final int todaySeconds;

  const ReadingStatsScreen({super.key, required this.todaySeconds});

  @override
  ConsumerState<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends ConsumerState<ReadingStatsScreen> {
  static const Color _bg = Color(0xFFFCF9F5);
  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _accent = Color(0xFFD97757);
  static const Color _accentYellow = Color(0xFFEDCB57);

  final _streakService = StreakService();
  final _xpService = XpService();

  bool _statsLoaded = false;

  int _todaySeconds = 0;
  int _goalMinutes = 30;
  int _allTimeSeconds = 0;
  int _totalDaysRead = 0;
  List<Map<String, dynamic>> _perBookData = [];

  static const List<int> _goalOptions = [10, 15, 20, 30, 45, 60];
  late PageController _goalPageController;
  int _selectedGoalIndex = 3;

  @override
  void initState() {
    super.initState();
    _todaySeconds = widget.todaySeconds;
    _selectedGoalIndex = _goalOptions.indexOf(_goalMinutes);
    if (_selectedGoalIndex < 0) _selectedGoalIndex = 3;
    _goalPageController = PageController(
      viewportFraction: 0.33,
      initialPage: _selectedGoalIndex,
    );
    _loadStats();
  }

  @override
  void dispose() {
    _goalPageController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final results = await Future.wait([
      _streakService.getTotalAllTimeSeconds(),
      _streakService.getTotalDaysRead(),
      _streakService.getPerBookReadingTime(),
    ]);

    final profile = await _xpService.getUserProfile();

    if (mounted) {
      setState(() {
        _allTimeSeconds = results[0] as int;
        _totalDaysRead = results[1] as int;
        _perBookData = results[2] as List<Map<String, dynamic>>;
        _goalMinutes = profile?.dailyReadingGoalMinutes ?? 30;
        _statsLoaded = true;
        _selectedGoalIndex = _goalOptions.indexOf(_goalMinutes);
        if (_selectedGoalIndex < 0) _selectedGoalIndex = 3;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _goalPageController.hasClients) {
          _goalPageController.jumpToPage(_selectedGoalIndex);
        }
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDurationLong(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    }
    return '$minutes min';
  }

  int get _averageSecondsPerDay {
    if (_totalDaysRead == 0) return 0;
    return _allTimeSeconds ~/ _totalDaysRead;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final appBarTopPad = (15 * scale).clamp(12.0, 15.0);
    final backIconSize = (22 * scale).clamp(18.0, 22.0);
    final titleSize = (32 * scale).clamp(26.0, 32.0);
    final outerPadH = (20 * scale).clamp(16.0, 20.0);
    final sectionGap24 = (24 * scale).clamp(18.0, 24.0);
    final sectionGap28 = (28 * scale).clamp(20.0, 28.0);
    final perBookHeaderSize = (18 * scale).clamp(15.0, 18.0);
    final bottomSpacer = (40 * scale).clamp(32.0, 40.0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + appBarTopPad),
        child: Padding(
          padding: EdgeInsets.only(top: appBarTopPad),
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
              icon: Icon(Icons.arrow_back_ios_rounded, size: backIconSize),
            ),
            title: Text(
              'Reading Stats',
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero: Today's reading ───────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(outerPadH, 8, outerPadH, 0),
              child: _buildTodayHeroCard(),
            ),
          ),

          // ── Lifetime stats ──────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                outerPadH,
                sectionGap24,
                outerPadH,
                0,
              ),
              child:
                  _statsLoaded
                      ? _buildLifetimeStats()
                      : _buildLifetimeSkeleton(),
            ),
          ),

          // ── Per-book header ─────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                outerPadH,
                sectionGap28,
                outerPadH,
                12,
              ),
              child: Text(
                'Time Per Book',
                style: TextStyle(
                  fontSize: perBookHeaderSize,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ),
          ),

          // ── Per-book list ────────────────
          !_statsLoaded
              ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: outerPadH),
                  child: _buildPerBookSkeleton(),
                ),
              )
              : _perBookData.isEmpty
              ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: outerPadH),
                  child: _buildEmptyBooksCard(),
                ),
              )
              : SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: outerPadH),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final book = _perBookData[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildBookTile(book, index),
                    );
                  }, childCount: _perBookData.length),
                ),
              ),

          SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
        ],
      ),
    );
  }

  void _openTodayDetail() {
    HapticFeedback.lightImpact();
    final today = DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DayDetailScreen(
              date: DateTime(today.year, today.month, today.day),
              heatmapData: const {},
            ),
      ),
    );
  }

  // ─── Today hero card ─────────────────────────────────────────────────────

  Widget _buildTodayHeroCard() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final titleSize = (14 * scale).clamp(12.0, 14.0);
    final gaugeWidth = (200 * scale).roundToDouble();
    final gaugeHeight = (100 * scale).roundToDouble();
    final numberSize = (40 * scale).clamp(32.0, 40.0);
    final labelSize = (16 * scale).clamp(13.0, 16.0);
    final goalTextSize = (13 * scale).clamp(11.0, 13.0);
    final detailTextSize = (11 * scale).clamp(9.0, 11.0);
    final padV = (32 * scale).clamp(24.0, 32.0);
    final padH = (24 * scale).clamp(18.0, 24.0);

    final todayMinutes = _todaySeconds ~/ 60;
    final todaySecs = _todaySeconds % 60;
    final progress = (_todaySeconds / (_goalMinutes * 60)).clamp(0.0, 1.0);

    final bool useHours = todayMinutes >= 60;
    final int displayPrimary = useHours ? todayMinutes ~/ 60 : todayMinutes;
    final int displaySecondary = useHours ? todayMinutes % 60 : todaySecs;
    final String primaryUnit = useHours ? 'hr ' : 'min ';
    final String secondaryUnit = useHours ? 'min' : 'sec';
    final goalReached = _todaySeconds >= _goalMinutes * 60;

    return GestureDetector(
      onTap: _openTodayDetail,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                goalReached
                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                    : [const Color(0xFF5B8DEF), const Color(0xFF7C5CBF)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  goalReached
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : const Color(0xFF5B8DEF).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              goalReached ? 'Goal Reached! 🎉' : "Today's Reading",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Arc gauge
            CustomPaint(
              size: Size(gaugeWidth, gaugeHeight),
              painter: _ArcPainter(
                trackColor: Colors.white.withOpacity(0.2),
                progressColor: Colors.white,
                progress: progress,
                strokeWidth: 10,
              ),
              child: SizedBox(
                width: gaugeWidth,
                height: gaugeHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$displayPrimary',
                          style: TextStyle(
                            fontSize: numberSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          primaryUnit,
                          style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$displaySecondary',
                          style: TextStyle(
                            fontSize: numberSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          secondaryUnit,
                          style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showGoalBottomSheet();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: Colors.white70,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Goal: $_goalMinutes min  ✎',
                      style: TextStyle(
                        fontSize: goalTextSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View today\'s details',
                  style: TextStyle(
                    fontSize: detailTextSize,
                    color: Colors.white.withOpacity(0.55),
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: (9 * scale).clamp(7.0, 9.0),
                  color: Colors.white.withOpacity(0.55),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─── Goal bottom sheet ───────────────────────────────────────────────────

  void _showGoalBottomSheet() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final subSize = (13 * scale).clamp(11.0, 13.0);
    final carouselHeight = (110 * scale).roundToDouble();
    final doneTopGap = (28 * scale).clamp(20.0, 28.0);
    final donePadH = (24 * scale).clamp(16.0, 24.0);

    int sheetSelectedIndex = _selectedGoalIndex;
    final sheetPageController = PageController(
      initialPage: _selectedGoalIndex,
      viewportFraction: 0.33,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFCF9F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0CCC6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: (20 * scale).clamp(16.0, 20.0)),

                    // Title
                    Text(
                      'Daily Reading Goal',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF-UI-Display',
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Swipe to choose how long you want to read each day',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: subSize,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SF-UI-Display',
                        color: const Color(0xFF8A8480),
                      ),
                    ),
                    SizedBox(height: (24 * scale).clamp(18.0, 24.0)),

                    // Carousel
                    SizedBox(
                      height: carouselHeight,
                      child: PageView.builder(
                        controller: sheetPageController,
                        itemCount: _goalOptions.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) async {
                          HapticFeedback.selectionClick();
                          final newGoal = _goalOptions[index];
                          setSheetState(() {
                            sheetSelectedIndex = index;
                          });
                          setState(() {
                            _selectedGoalIndex = index;
                            _goalMinutes = newGoal;
                          });
                          final success = await _xpService
                              .updateDailyReadingGoal(newGoal);
                          if (success && mounted) {
                            ref.invalidate(userProfileProvider);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.flag_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Reading goal updated to $newGoal min',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'SF-UI-Display',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF2D2D2D),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  margin: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          }
                        },
                        itemBuilder: (context, index) {
                          final isSelected = index == sheetSelectedIndex;
                          final dist = (index - sheetSelectedIndex).abs();
                          final targetScale =
                              isSelected ? 1.0 : (dist == 1 ? 0.72 : 0.52);
                          final targetOpacity =
                              isSelected ? 1.0 : (dist == 1 ? 0.45 : 0.20);

                          return AnimatedScale(
                            scale: targetScale,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: targetOpacity,
                              duration: const Duration(milliseconds: 220),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? const LinearGradient(
                                            colors: [
                                              Color(0xFF5B8DEF),
                                              Color(0xFF7C5CBF),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                          : null,
                                  color:
                                      isSelected
                                          ? null
                                          : const Color(0xFFECE8E3),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_goalOptions[index]}',
                                        style: TextStyle(
                                          fontSize:
                                              isSelected
                                                  ? (30 * scale).clamp(
                                                    24.0,
                                                    30.0,
                                                  )
                                                  : (22 * scale).clamp(
                                                    18.0,
                                                    22.0,
                                                  ),
                                          fontWeight: FontWeight.w800,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : const Color(0xFFB0AAA4),
                                          fontFamily: 'SF-UI-Display',
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        'min',
                                        style: TextStyle(
                                          fontSize:
                                              isSelected
                                                  ? (12 * scale).clamp(
                                                    10.0,
                                                    12.0,
                                                  )
                                                  : (10 * scale).clamp(
                                                    8.0,
                                                    10.0,
                                                  ),
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? Colors.white70
                                                  : const Color(0xFFB0AAA4),
                                          fontFamily: 'SF-UI-Display',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _goalOptions.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == sheetSelectedIndex ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient:
                                i == sheetSelectedIndex
                                    ? const LinearGradient(
                                      colors: [
                                        Color(0xFF5B8DEF),
                                        Color(0xFF7C5CBF),
                                      ],
                                    )
                                    : null,
                            color:
                                i == sheetSelectedIndex
                                    ? null
                                    : const Color(0xFFD0CCC6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: doneTopGap),

                    // Done button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: donePadH),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(sheetCtx),
                        child: Container(
                          width: double.infinity,
                          height: (52 * scale).clamp(44.0, 52.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B8DEF), Color(0xFF7C5CBF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              'Done',
                              style: TextStyle(
                                fontSize: (16 * scale).clamp(14.0, 16.0),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Skeleton helpers ─────────────────────────────────────────────────

  Widget _skeletonBox({
    double width = double.infinity,
    double height = 16,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFECE8E3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildLifetimeSkeleton() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final blockHeight = (96 * scale).clamp(82.0, 96.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skeletonBox(width: 80, height: 20),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: blockHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8E3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: blockHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8E3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: blockHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8E3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: blockHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8E3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerBookSkeleton() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final tileHeight = (88 * scale).clamp(75.0, 88.0);

    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: tileHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFECE8E3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
  // ─── Lifetime stats ────────────────────────────────────────────────────────

  Widget _buildLifetimeStats() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerSize = (18 * scale).clamp(15.0, 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifetime',
          style: TextStyle(
            fontSize: headerSize,
            fontWeight: FontWeight.w700,
            color: _textDark,
            fontFamily: 'SF-UI-Display',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_outlined,
                label: 'Total Reading',
                value: _formatDurationLong(_allTimeSeconds),
                color: const Color(0xFF5B8DEF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today_rounded,
                label: 'Days Read',
                value: '$_totalDaysRead',
                color: const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up_rounded,
                label: 'Avg / Day',
                value: _formatDuration(_averageSecondsPerDay),
                color: _accentYellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.menu_book_rounded,
                label: 'Books Read',
                value: '${_perBookData.length}',
                color: _accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final iconBoxSize = (36 * scale).clamp(28.0, 36.0);
    final iconSize = (18 * scale).clamp(14.0, 18.0);
    final valueSize = (20 * scale).clamp(16.0, 20.0);
    final labelSize = (12 * scale).clamp(10.0, 12.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: _textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Per-book tiles ────────────────────────────────────────────────────────

  Widget _buildBookTile(Map<String, dynamic> book, int index) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final titleSize = (15 * scale).clamp(13.0, 15.0);
    final authorSize = (12 * scale).clamp(10.0, 12.0);
    final timeSize = (14 * scale).clamp(12.0, 14.0);
    final coverWidth = (56 * scale).roundToDouble();
    final coverHeight = (80 * scale).roundToDouble();

    final title = book['title'] as String? ?? 'Unknown';
    final author = book['author'] as String? ?? '';
    final seconds = book['total_read_seconds'] as int? ?? 0;
    final coverUrl = book['cover_url'] as String?;

    // Compute share of total
    final maxSeconds =
        _perBookData.isNotEmpty
            ? (_perBookData.first['total_read_seconds'] as int? ?? 1)
            : 1;
    final barFraction = (seconds / maxSeconds).clamp(0.0, 1.0);

    // Alternate soft colors
    final colors = [
      const Color(0xFF5B8DEF),
      _accent,
      const Color(0xFF66BB6A),
      _accentYellow,
      const Color(0xFFAB6FE8),
    ];
    final barColor = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    coverUrl != null && coverUrl.isNotEmpty
                        ? Image.network(
                          coverUrl,
                          width: coverWidth,
                          height: coverHeight,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _buildCoverPlaceholder(
                                barColor,
                                coverWidth,
                                coverHeight,
                              ),
                        )
                        : _buildCoverPlaceholder(
                          barColor,
                          coverWidth,
                          coverHeight,
                        ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                        height: 1.3,
                      ),
                    ),
                    if (author.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: authorSize,
                          color: _textGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Time chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatDuration(seconds),
                        style: TextStyle(
                          fontSize: timeSize,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barFraction,
              minHeight: 4,
              backgroundColor: barColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder(Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.auto_stories_rounded, color: color, size: width * 0.46),
    );
  }

  Widget _buildEmptyBooksCard() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (15 * scale).clamp(13.0, 15.0);
    final subSize = (13 * scale).clamp(11.0, 13.0);
    final iconSize = (40 * scale).clamp(32.0, 40.0);
    final cardPad = (32 * scale).clamp(24.0, 32.0);

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: iconSize,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No reading data yet',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: _textGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start reading to see per-book stats',
            style: TextStyle(fontSize: subSize, color: _textGrey),
          ),
        ],
      ),
    );
  }
}

// ─── Arc painter (reused from DailyProgressCard) ────────────────────────────

class _ArcPainter extends CustomPainter {
  final Color trackColor;
  final Color progressColor;
  final double progress;
  final double strokeWidth;

  _ArcPainter({
    required this.trackColor,
    required this.progressColor,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: min(size.width / 2, size.height),
    );

    final bgPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    final fgPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, pi, pi, false, bgPaint);
    canvas.drawArc(rect, pi, pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

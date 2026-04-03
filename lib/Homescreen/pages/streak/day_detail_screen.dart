import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:biblio/core/services/streak_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;
  final Map<DateTime, int> heatmapData;

  const DayDetailScreen({
    super.key,
    required this.date,
    required this.heatmapData,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  static const Color _bg = Color(0xFFFCF9F5);
  static const Color _textDark = Color(0xFF2D2D2D);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _accent = Color(0xFFD97757);

  final StreakService _streakService = StreakService();

  // Swipe support: 90 days back from today
  static const int _totalPages = 91; // 0 = today, 90 = 90 days ago
  late final PageController _pageController;
  late int _initialPage;

  late DateTime _currentDate;
  bool _loading = true;
  int _totalSeconds = 0;
  List<Map<String, dynamic>> _booksRead = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    _currentDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    // Compute page index: 0 = oldest (90 days ago), _totalPages-1 = today
    final daysDiff = todayNorm
        .difference(_currentDate)
        .inDays
        .clamp(0, _totalPages - 1);
    _initialPage = (_totalPages - 1) - daysDiff;
    _pageController = PageController(initialPage: _initialPage);
    _loadDayData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateForPage(int pageIndex) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final daysAgo = (_totalPages - 1) - pageIndex;
    return todayNorm.subtract(Duration(days: daysAgo));
  }

  Future<void> _loadDayData() async {
    setState(() => _loading = true);
    final data = await _streakService.getDayReadingDetails(_currentDate);
    if (mounted) {
      final booksRaw = data?['books_read'] as List<dynamic>? ?? [];
      final aggregated = _aggregateBooks(booksRaw);

      // Enrich with cover_url and author from books table
      final enriched = await _enrichBookData(aggregated);

      setState(() {
        _totalSeconds = data?['total_seconds'] as int? ?? 0;
        _booksRead = enriched;
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _enrichBookData(
    List<Map<String, dynamic>> books,
  ) async {
    if (books.isEmpty) return books;
    try {
      final bookIds =
          books
              .map((b) => b['book_id'] as String?)
              .where((id) => id != null)
              .toSet()
              .toList();

      if (bookIds.isEmpty) return books;

      final response = await Supabase.instance.client
          .from('books')
          .select('id, title, author, cover_url')
          .inFilter('id', bookIds);

      final bookInfoMap = <String, Map<String, dynamic>>{};
      for (final row in response) {
        bookInfoMap[row['id'] as String] = row;
      }

      for (final book in books) {
        final info = bookInfoMap[book['book_id']];
        if (info != null) {
          book['author'] = info['author'];
          book['cover_url'] = info['cover_url'];
        }
      }
    } catch (_) {}
    return books;
  }

  List<Map<String, dynamic>> _aggregateBooks(List<dynamic> raw) {
    final Map<String, Map<String, dynamic>> bookMap = {};
    for (final entry in raw) {
      final map = Map<String, dynamic>.from(entry as Map);
      final bookId =
          map['book_id'] as String? ??
          map['book_title'] as String? ??
          'unknown';
      if (bookMap.containsKey(bookId)) {
        bookMap[bookId]!['duration_seconds'] =
            (bookMap[bookId]!['duration_seconds'] as int) +
            (map['duration_seconds'] as int? ?? 0);
        if (map['mood_emoji'] != null) {
          bookMap[bookId]!['mood_emoji'] = map['mood_emoji'];
        }
      } else {
        bookMap[bookId] = Map<String, dynamic>.from(map);
      }
    }
    final result = bookMap.values.toList();
    result.sort(
      (a, b) => (b['duration_seconds'] as int? ?? 0).compareTo(
        a['duration_seconds'] as int? ?? 0,
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final titleSize = (24 * scale).clamp(20.0, 24.0);
    final subtitleSize = (14 * scale).clamp(12.0, 14.0);
    final helperSize = (11 * scale).clamp(9.0, 11.0);
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final isToday = _currentDate == todayNorm;

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
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: (22 * scale).clamp(18.0, 22.0),
              ),
            ),
            title: Text(
              isToday ? 'Today' : DateFormat('EEEE').format(_currentDate),
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
      body: Column(
        children: [
          // Date subtitle
          Text(
            DateFormat('MMMM d, yyyy').format(_currentDate),
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w500,
              color: _textGrey,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          SizedBox(height: (6 * scale).roundToDouble()),
          // Swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_rounded,
                size: (14 * scale).clamp(12.0, 14.0),
                color: _textGrey.withValues(alpha: 0.5),
              ),
              SizedBox(width: (4 * scale).roundToDouble()),
              Text(
                'Swipe to navigate days',
                style: TextStyle(
                  fontSize: helperSize,
                  color: _textGrey.withValues(alpha: 0.5),
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ],
          ),
          SizedBox(height: (12 * scale).clamp(10.0, 12.0)),
          // Swipeable content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (page) {
                HapticFeedback.selectionClick();
                final newDate = _dateForPage(page);
                setState(() => _currentDate = newDate);
                _loadDayData();
              },
              itemBuilder: (context, index) {
                // Only build content for the current visible page
                final pageDate = _dateForPage(index);
                final isCurrentPage = pageDate == _currentDate;

                if (!isCurrentPage) {
                  // Placeholder for non-current pages
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B6CF6),
                      strokeWidth: 2,
                    ),
                  );
                }

                if (_loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B6CF6),
                      strokeWidth: 2,
                    ),
                  );
                }

                final hasData = _totalSeconds > 0;
                final dayIsToday = pageDate == todayNorm;

                return hasData
                    ? _buildReadingContent(scale)
                    : _buildEmptyState(dayIsToday, scale);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reading Content ──────────────────────────────────────────────────

  Widget _buildReadingContent(double scale) {
    final contentPadH = (20 * scale).clamp(16.0, 20.0);
    final contentPadBottom = (40 * scale).clamp(32.0, 40.0);
    final heroPad = (24 * scale).clamp(18.0, 24.0);
    final heroIconBox = (56 * scale).clamp(46.0, 56.0);
    final heroIconSize = (28 * scale).clamp(22.0, 28.0);
    final timeSize = (36 * scale).clamp(30.0, 36.0);
    final heroLabelSize = (14 * scale).clamp(12.0, 14.0);
    final statsValueSize = (22 * scale).clamp(18.0, 22.0);
    final statsLabelSize = (12 * scale).clamp(10.0, 12.0);
    final sectionTitleSize = (18 * scale).clamp(15.0, 18.0);
    final minutes = _totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${remainingMins}m' : '${minutes}m';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        contentPadH,
        (4 * scale).roundToDouble(),
        contentPadH,
        contentPadBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Summary Hero Card ────────────────────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B6CF6), Color(0xFF5B4AE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B6CF6).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(heroPad),
              child: Column(
                children: [
                  Container(
                    width: heroIconBox,
                    height: heroIconBox,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: heroIconSize,
                    ),
                  ),
                  SizedBox(height: (12 * scale).clamp(8.0, 12.0)),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: timeSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'SF-UI-Display',
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: (4 * scale).roundToDouble()),
                  Text(
                    'Total Reading Time',
                    style: TextStyle(
                      fontSize: heroLabelSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
                  // Stats row inside hero
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
                                '${_booksRead.length}',
                                style: TextStyle(
                                  fontSize: statsValueSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'SF-UI-Display',
                                ),
                              ),
                              SizedBox(height: (2 * scale).roundToDouble()),
                              Text(
                                _booksRead.length == 1 ? 'Book' : 'Books',
                                style: TextStyle(
                                  fontSize: statsLabelSize,
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
                                '$minutes',
                                style: TextStyle(
                                  fontSize: statsValueSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'SF-UI-Display',
                                ),
                              ),
                              SizedBox(height: (2 * scale).roundToDouble()),
                              Text(
                                'Minutes',
                                style: TextStyle(
                                  fontSize: statsLabelSize,
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
          ),
          SizedBox(height: (24 * scale).clamp(18.0, 24.0)),

          // ─── Books Read ───────────────────────────────────
          Text(
            'Books Read',
            style: TextStyle(
              fontSize: sectionTitleSize,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          SizedBox(height: (14 * scale).clamp(10.0, 14.0)),
          ..._booksRead.map((book) => _buildBookCard(book, scale)),
        ],
      ),
    );
  }

  // ─── Book Card (bigger, with cover + author) ──────────────────────────

  Widget _buildBookCard(Map<String, dynamic> book, double scale) {
    final coverWidth = (64 * scale).clamp(54.0, 64.0);
    final coverHeight = (coverWidth * 1.40625).clamp(76.0, 90.0);
    final titleSize = (16 * scale).clamp(14.0, 16.0);
    final authorSize = (13 * scale).clamp(11.0, 13.0);
    final chipSize = (12 * scale).clamp(10.0, 12.0);
    final moodSize = (24 * scale).clamp(20.0, 24.0);
    final title = book['book_title'] as String? ?? 'Unknown Book';
    final author = book['author'] as String? ?? 'Unknown Author';
    final coverUrl = book['cover_url'] as String?;
    final seconds = book['duration_seconds'] as int? ?? 0;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${remainingMins}m' : '${minutes}m';
    final moodEmoji = book['mood_emoji'] as String?;
    final progress = book['progress_gained'] as num?;

    return Container(
      margin: EdgeInsets.only(bottom: (14 * scale).clamp(10.0, 14.0)),
      padding: EdgeInsets.all((14 * scale).clamp(10.0, 14.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Book Cover ──────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                coverUrl != null && coverUrl.isNotEmpty
                    ? Image.network(
                      coverUrl,
                      width: coverWidth,
                      height: coverHeight,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _buildCoverPlaceholder(
                            coverWidth,
                            coverHeight,
                            scale,
                          ),
                    )
                    : _buildCoverPlaceholder(coverWidth, coverHeight, scale),
          ),
          SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
          // ─── Book Info ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    fontFamily: 'SF-UI-Display',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: (4 * scale).roundToDouble()),
                // Author
                Text(
                  author,
                  style: TextStyle(
                    fontSize: authorSize,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                    fontFamily: 'SF-UI-Display',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: (10 * scale).clamp(8.0, 10.0)),
                // Time + Progress row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (10 * scale).clamp(8.0, 10.0),
                        vertical: (4 * scale).roundToDouble(),
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: (13 * scale).clamp(11.0, 13.0),
                            color: _accent,
                          ),
                          SizedBox(width: (4 * scale).roundToDouble()),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: chipSize,
                              fontWeight: FontWeight.w600,
                              color: _accent,
                              fontFamily: 'SF-UI-Display',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (progress != null && progress > 0) ...[
                      SizedBox(width: (8 * scale).roundToDouble()),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (10 * scale).clamp(8.0, 10.0),
                          vertical: (4 * scale).roundToDouble(),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF43A047,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${progress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: chipSize,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF43A047),
                            fontFamily: 'SF-UI-Display',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Mood emoji
          if (moodEmoji != null) ...[
            SizedBox(width: (8 * scale).roundToDouble()),
            Text(moodEmoji, style: TextStyle(fontSize: moodSize)),
          ],
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder(
    double coverWidth,
    double coverHeight,
    double scale,
  ) {
    return Container(
      width: coverWidth,
      height: coverHeight,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: _accent.withValues(alpha: 0.4),
        size: (28 * scale).clamp(22.0, 28.0),
      ),
    );
  }

  // ─── Empty State (missed day / today with no reading) ─────────────────

  Widget _buildEmptyState(bool isToday, double scale) {
    final padH = (40 * scale).clamp(26.0, 40.0);
    final emptyTitle = (18 * scale).clamp(15.0, 18.0);
    final missedTitle = (20 * scale).clamp(16.0, 20.0);
    final bodySize = (14 * scale).clamp(12.0, 14.0);
    final chipSize = (13 * scale).clamp(11.0, 13.0);
    if (isToday) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: (88 * scale).clamp(72.0, 88.0),
                height: (88 * scale).clamp(72.0, 88.0),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: (40 * scale).clamp(32.0, 40.0),
                  color: _accent.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
              Text(
                'No reading yet today',
                style: TextStyle(
                  fontSize: emptyTitle,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
              SizedBox(height: (8 * scale).roundToDouble()),
              Text(
                'Start a reading session to build your streak!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bodySize,
                  color: _textGrey,
                  fontFamily: 'SF-UI-Display',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Missed day — big sad frown
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: (100 * scale).clamp(82.0, 100.0),
              height: (100 * scale).clamp(82.0, 100.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '😔',
                  style: TextStyle(fontSize: (48 * scale).clamp(40.0, 48.0)),
                ),
              ),
            ),
            SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
            Text(
              'You missed this day',
              style: TextStyle(
                fontSize: missedTitle,
                fontWeight: FontWeight.w700,
                color: _textDark,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: (8 * scale).roundToDouble()),
            Text(
              'No reading was recorded. Even a few\nminutes a day can make a big difference!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: bodySize,
                color: _textGrey,
                fontFamily: 'SF-UI-Display',
                height: 1.5,
              ),
            ),
            SizedBox(height: (24 * scale).clamp(18.0, 24.0)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (20 * scale).clamp(14.0, 20.0),
                vertical: (10 * scale).clamp(8.0, 10.0),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Streak was at risk!',
                style: TextStyle(
                  fontSize: chipSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

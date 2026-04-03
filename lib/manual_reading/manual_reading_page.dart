import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/services/supabase_stats_service.dart';
import 'package:biblio/core/services/supabase_book_service.dart';
import 'package:biblio/reading_session/constants/reading_session_colors.dart';
import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';
import 'package:biblio/reading_session/dialogs/target_read_dialog.dart';
import 'package:biblio/reading_session/dialogs/pomodoro_dialog.dart';
import 'widgets/physical_book_card.dart';
import 'widgets/physical_book_mode_tabs.dart';
import 'widgets/physical_book_timer_circle.dart';
import 'widgets/physical_book_action_buttons.dart';
import 'widgets/physical_book_tool_bar.dart';
import 'dialogs/end_session_page_dialog.dart';
import 'focus_mode_screen.dart';
import 'scan_quote/scan_quote_coordinator.dart';
import 'ask_ai/ask_ai_bottom_sheet.dart';
import 'package:biblio/Homescreen/pages/library/widgets/book_journal_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualReadingPage extends StatefulWidget {
  final Book book;
  const ManualReadingPage({super.key, required this.book});

  static const routeName = '/manual-reading';

  @override
  State<ManualReadingPage> createState() => _ManualReadingPageState();
}

class _ManualReadingPageState extends State<ManualReadingPage> {
  late final ReadingTimerController _timerController;
  final _statsService = SupabaseStatsService();
  final _bookService = SupabaseBookService();

  // UI mode: 0 = Stopwatch (open), 1 = Pomodoro, 2 = Custom (target)
  int _uiMode = 0;

  @override
  void initState() {
    super.initState();
    _timerController = ReadingTimerController();
    _timerController.addListener(_onTimerUpdate);
    _timerController.startTimer();
  }

  @override
  void dispose() {
    _timerController.removeListener(_onTimerUpdate);
    _timerController.dispose();
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) setState(() {});
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationReadable(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  Future<void> _selectMode(int uiMode) async {
    if (uiMode == 1) {
      // Pomodoro
      final settings = await showDialog<PomodoroSettings>(
        context: context,
        builder: (_) => const PomodoroDialog(),
      );
      if (settings != null && mounted) {
        _timerController.setMode(2, targetMinutes: settings.workMinutes);
        setState(() => _uiMode = 1);
      }
    } else if (uiMode == 2) {
      // Custom (target read)
      final minutes = await showDialog<int>(
        context: context,
        builder: (_) => const TargetReadDialog(),
      );
      if (minutes != null && mounted) {
        _timerController.setMode(1, targetMinutes: minutes);
        setState(() => _uiMode = 2);
      }
    } else {
      // Stopwatch
      _timerController.setMode(0);
      setState(() => _uiMode = 0);
    }
  }

  void _openFocusMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FocusModeScreen(timerController: _timerController),
      ),
    );
  }

  void _openAskAi() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
            ),
            child: AskAiBottomSheet(book: widget.book),
          ),
    );
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_timerController.isRunning) {
      _timerController.pauseTimer();
    } else {
      _timerController.resumeTimer();
    }
  }

  Future<void> _finishSession() async {
    HapticFeedback.mediumImpact();
    _timerController.pauseTimer();

    final elapsedSeconds = _timerController.elapsedSeconds;
    if (elapsedSeconds < 5) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final duration = _formatDurationReadable(elapsedSeconds);

    final result = await showDialog<EndSessionResult>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => EndSessionPageDialog(
            currentPage: widget.book.currentPage,
            totalPages: widget.book.totalPages,
            duration: duration,
          ),
    );

    if (result == null) {
      // User dismissed — resume timer
      _timerController.resumeTimer();
      return;
    }

    _timerController.endSession();

    // Show a saving indicator so the user isn't left on a frozen screen
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: Card(
              color: Color(0xFFF8EFD0),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFB85C38)),
                    SizedBox(height: 16),
                    Text(
                      'Saving session...',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D2008),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    final pagesRead = result.pageReachedTo - widget.book.currentPage;
    final progressGained =
        widget.book.totalPages > 0
            ? (pagesRead / widget.book.totalPages) * 100
            : 0.0;
    final newProgress =
        widget.book.totalPages > 0
            ? (result.pageReachedTo / widget.book.totalPages) * 100
            : 0.0;

    unawaited(
      (() async {
        try {
          await _statsService.saveReadingSession(
            bookId: widget.book.id,
            bookTitle: widget.book.title,
            durationSeconds: elapsedSeconds,
            progressGained: progressGained,
            moodEmoji: result.moodEmoji,
          );

          await _statsService.updateBookProgress(
            bookId: widget.book.id,
            cfi: null,
            progressPercent: newProgress,
            readSeconds: elapsedSeconds,
          );

          await _bookService.updateBook(
            bookId: widget.book.id,
            currentPage: result.pageReachedTo,
            isStartedReading: true,
          );

          debugPrint('✅ Physical book session saved');
          debugPrint(
            '   Pages: ${widget.book.currentPage} → ${result.pageReachedTo}',
          );
          debugPrint('   Duration: $elapsedSeconds seconds');
          debugPrint('   Progress: +${progressGained.toStringAsFixed(1)}%');

          container.invalidate(currentStreakProvider);
          container.invalidate(todayReadingSecondsProvider);
          container.invalidate(currentWeekReadDaysProvider);
          container.invalidate(userProfileProvider);
        } catch (e) {
          debugPrint('❌ Error saving physical book session: $e');
        }
      })(),
    );

    await Future.delayed(const Duration(milliseconds: 250));

    // Navigate back quickly — save continues in background
    if (mounted) {
      Navigator.of(context)
        ..pop() // dismiss saving indicator
        ..pop(result.pageReachedTo); // return to homepage
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final controllerMode = _timerController.selectedMode;
    final isCountdown = controllerMode == 1 || controllerMode == 2;

    final displayTime =
        isCountdown
            ? _formatTime(_timerController.remainingSeconds)
            : _formatTime(_timerController.elapsedSeconds);

    // Calculate progress for timer ring
    double? timerProgress;
    if (isCountdown && _timerController.targetSeconds > 0) {
      timerProgress =
          _timerController.remainingSeconds / _timerController.targetSeconds;
    }

    final timerLabel = isCountdown ? 'minutes' : 'minutes read';

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFD0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: (24 * scale).clamp(16.0, 24.0),
                  vertical: (16 * scale).clamp(12.0, 16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (widget.book.currentPage > 0) ...[
                      const SizedBox(height: 12),
                      _buildContinueFromBanner(scale),
                    ],
                    const SizedBox(height: 20),
                    PhysicalBookCard(book: widget.book),
                    const SizedBox(height: 24),
                    PhysicalBookModeTabs(
                      selectedMode: _uiMode,
                      onModeSelected: _selectMode,
                    ),
                    const SizedBox(height: 32),
                    PhysicalBookTimerCircle(
                      displayTime: displayTime,
                      label: timerLabel,
                      progress: timerProgress,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Tool bar above action buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                (24 * scale).clamp(16.0, 24.0),
                0,
                (24 * scale).clamp(16.0, 24.0),
                (12 * scale).clamp(8.0, 12.0),
              ),
              child: PhysicalBookToolBar(
                onFocusMode: _openFocusMode,
                onScanQuote:
                    () => ScanQuoteCoordinator.launch(context, widget.book),
                onAskAi: () => _openAskAi(),
                onBookJournal:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookJournalPage(book: widget.book),
                      ),
                    ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                (24 * scale).clamp(16.0, 24.0),
                0,
                (24 * scale).clamp(16.0, 24.0),
                (16 * scale).clamp(12.0, 16.0),
              ),
              child: PhysicalBookActionButtons(
                isRunning: _timerController.isRunning,
                onToggle: _toggleTimer,
                onFinish: _finishSession,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Physical Book Session',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ReadingSessionColors.headerTextColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (_timerController.elapsedSeconds > 5) {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Leave Session?'),
                      content: const Text(
                        'Your reading progress will not be saved.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _timerController.endSession();
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
              );
            } else {
              _timerController.endSession();
              Navigator.pop(context);
            }
          },
          icon: Icon(
            Icons.close,
            color: ReadingSessionColors.headerTextColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueFromBanner(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (16 * scale).clamp(12.0, 16.0),
        vertical: (10 * scale).clamp(8.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFB85C38).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB85C38).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark, size: 18, color: Color(0xFFB85C38)),
          const SizedBox(width: 8),
          Text(
            'You last read till page ${widget.book.currentPage}. Continue from there!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB85C38),
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ],
      ),
    );
  }
}

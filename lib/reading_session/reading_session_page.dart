import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biblio/core/models/book_model.dart';
import 'constants/reading_session_colors.dart';
import 'widgets/book_card.dart';
import 'widgets/mode_tabs.dart';
import 'widgets/timer_circle.dart';
import 'widgets/stats_card.dart';
import 'widgets/action_buttons.dart';
import 'dialogs/target_read_dialog.dart';
import 'dialogs/pomodoro_dialog.dart';
import 'controllers/reading_timer_controller.dart';
import 'package:biblio/core/services/streak_service.dart';

class ReadingSessionPage extends StatefulWidget {
  final Book book;
  final ReadingTimerController timerController;

  const ReadingSessionPage({
    super.key,
    required this.book,
    required this.timerController,
  });

  @override
  State<ReadingSessionPage> createState() => _ReadingSessionPageState();
}

class _ReadingSessionPageState extends State<ReadingSessionPage> {
  final _streakService = StreakService();

  // Replace placeholders with real data
  int _dailyGoalMinutes = 30;
  int _dailyReadMinutes = 0;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    widget.timerController.addListener(_onTimerUpdate);
    _loadStats(); // ✅ Load real stats
  }

  Future<void> _loadStats() async {
    final todaySeconds = await _streakService.getTodayReadingSeconds();
    final streak = await _streakService.calculateCurrentStreak();

    if (mounted) {
      setState(() {
        _dailyReadMinutes = todaySeconds ~/ 60;
        _streakDays = streak;
      });
    }
  }

  @override
  void dispose() {
    widget.timerController.removeListener(_onTimerUpdate);
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _selectMode(int mode) async {
    if (mode == 1) {
      final minutes = await showDialog<int>(
        context: context,
        builder: (_) => const TargetReadDialog(),
      );
      if (minutes != null && mounted) {
        widget.timerController.setMode(1, targetMinutes: minutes);
      }
    } else if (mode == 2) {
      final settings = await showDialog<PomodoroSettings>(
        context: context,
        builder: (_) => const PomodoroDialog(),
      );
      if (settings != null && mounted) {
        widget.timerController.setMode(2, targetMinutes: settings.workMinutes);
      }
    } else {
      widget.timerController.setMode(0);
    }
  }

  void _endSession() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Session?'),
            content: const Text(
              'Are you sure you want to end this reading session?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.timerController.endSession();
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close session page
                },
                child: const Text('End'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final timerController = widget.timerController;
    final displayTime =
        timerController.selectedMode == 0
            ? _formatTime(timerController.elapsedSeconds)
            : _formatTime(timerController.remainingSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFD0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: (22 * scale).clamp(16.0, 24.0),
                  vertical: (14 * scale).clamp(10.0, 16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(scale),
                    SizedBox(height: (18 * scale).clamp(14.0, 20.0)),
                    BookCard(book: widget.book),
                    SizedBox(height: (20 * scale).clamp(16.0, 24.0)),
                    ModeTabs(
                      selectedMode: timerController.selectedMode,
                      onModeSelected: _selectMode,
                    ),
                    SizedBox(height: (28 * scale).clamp(20.0, 32.0)),
                    TimerCircle(displayTime: displayTime),
                    SizedBox(height: (28 * scale).clamp(20.0, 32.0)),
                    _buildStatsRow(),
                    SizedBox(height: (20 * scale).clamp(16.0, 24.0)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                (22 * scale).clamp(16.0, 24.0),
                0,
                (22 * scale).clamp(16.0, 24.0),
                (14 * scale).clamp(10.0, 16.0),
              ),
              child: ActionButtons(
                isRunning: timerController.isRunning,
                onToggle:
                    timerController.isRunning
                        ? timerController.pauseTimer
                        : timerController.resumeTimer,
                onEnd: _endSession,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double scale) {
    final headerFontSize = (26 * scale).clamp(22.0, 32.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Reading Session',
            style: TextStyle(
              fontSize: headerFontSize,
              fontWeight: FontWeight.bold,
              color: ReadingSessionColors.headerTextColor,
              fontFamily: 'SF-UI-Display',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: ReadingSessionColors.headerTextColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            icon: Icons.track_changes,
            iconColor: Colors.blue,
            label: 'Daily Goal',
            value: '$_dailyReadMinutes',
            suffix: ' / $_dailyGoalMinutes min',
            progressValue: _dailyReadMinutes / _dailyGoalMinutes,
            progressColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.red,
            label: 'Streak',
            value: '$_streakDays',
            suffix: ' days',
            subtext: 'Keep it up! 🎉',
          ),
        ),
      ],
    );
  }
}

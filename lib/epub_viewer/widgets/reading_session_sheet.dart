import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biblio/core/models/book_model.dart';

// ============================================================================
// COLOR CONTROLLER - Edit colors here
// ============================================================================
class ReadingSessionColors {
  // Background
  static const Color backgroundColor = Color(0xFFF5F0E8);

  // Header
  static const Color headerTextColor = Color(0xFF1A1A1A);

  // Book card
  static const Color bookCardBackground = Color(0xFFFAF3D9);
  static const Color bookTitleColor = Color(0xFF1A1A1A);
  static const Color bookAuthorColor = Color(0xFF666666);
  static const Color bookPageColor = Color(0xFF888888);

  // Tab buttons
  static const Color tabActiveBackground = Color(0xFFD97A73);
  static const Color tabActiveText = Color(0xFFFFFFFF);
  static const Color tabInactiveBackground = Color(0xFF4A7C59);
  static const Color tabInactiveText = Color(0xFFFFFFFF);
  static const Color pomodoroTabBackground = Color(0xFF5B8A72);

  // Timer circle
  static const Color timerCircleBackground = Color(0xFFFDF8F3);
  static const Color timerCircleBorder = Color(0xFFD4A853);
  static const Color timerTextColor = Color(0xFF1A1A1A);
  static const Color timerLabelColor = Color(0xFF888888);

  // Stats cards
  static const Color statsCardBackground = Color(0xFFFDF8F3);
  static const Color statsLabelColor = Color(0xFF888888);
  static const Color statsValueColor = Color(0xFF1A1A1A);
  static const Color goalIconColor = Color(0xFF4A7C59);
  static const Color streakIconColor = Color(0xFFD4A853);

  // Buttons
  static const Color continueButtonBackground = Color(0xFFD97A73);
  static const Color continueButtonText = Color(0xFFFFFFFF);
  static const Color endButtonBackground = Color(0xFF4A7C59);
  static const Color endButtonText = Color(0xFFFFFFFF);

  // Popup
  static const Color popupBackground = Color(0xFFFFFFFF);
  static const Color popupTextColor = Color(0xFF1A1A1A);
  static const Color popupSecondaryText = Color(0xFF666666);

  // Progress
  static const Color progressTrackColor = Color(0xFFE6DDC8);
  static const Color progressFillColor = Color(0xFFD97A73);
  static const Color progressTextColor = Color(0xFF1A1A1A);
}

// ============================================================================
// READING SESSION SHEET
// ============================================================================
class ReadingSessionSheet extends StatefulWidget {
  final Book book;

  const ReadingSessionSheet({super.key, required this.book});

  @override
  State<ReadingSessionSheet> createState() => _ReadingSessionSheetState();
}

class _ReadingSessionSheetState extends State<ReadingSessionSheet> {
  // Timer state
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  // Mode: 0 = Open Read, 1 = Target Read, 2 = Pomodoro
  int _selectedMode = 0;

  // Target read
  int _targetSeconds = 0;
  int _remainingSeconds = 0;

  // Placeholder stats (wire later)
  final int _dailyGoalMinutes = 30;
  final int _dailyReadMinutes = 24;
  final int _streakDays = 7;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_selectedMode == 1 && _remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds == 0) {
            _timer?.cancel();
            _isRunning = false;
            HapticFeedback.heavyImpact();
          }
        } else {
          _elapsedSeconds++;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    setState(() {});
  }

  void _resumeTimer() {
    if (!_isRunning) {
      _startTimer();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _selectMode(int mode) {
    HapticFeedback.selectionClick();
    if (mode == 1) {
      _showTargetReadPopup();
    } else if (mode == 2) {
      _showPomodoroPopup();
    } else {
      setState(() {
        _selectedMode = mode;
        _targetSeconds = 0;
        _remainingSeconds = 0;
      });
    }
  }

  void _showTargetReadPopup() {
    int selectedMinutes = 25;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ReadingSessionColors.popupBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Set Target Time',
                style: TextStyle(
                  color: ReadingSessionColors.popupTextColor,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How long do you want to read?',
                    style: TextStyle(
                      color: ReadingSessionColors.popupSecondaryText,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (selectedMinutes > 5) {
                            setDialogState(() => selectedMinutes -= 5);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: ReadingSessionColors.tabActiveBackground,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$selectedMinutes min',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ReadingSessionColors.popupTextColor,
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          setDialogState(() => selectedMinutes += 5);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: ReadingSessionColors.tabActiveBackground,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: ReadingSessionColors.popupSecondaryText,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedMode = 1;
                      _targetSeconds = selectedMinutes * 60;
                      _remainingSeconds = _targetSeconds;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReadingSessionColors.tabActiveBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: TextStyle(
                      color: ReadingSessionColors.tabActiveText,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPomodoroPopup() {
    int workMinutes = 25;
    int breakMinutes = 5;
    int sessions = 4;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ReadingSessionColors.popupBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Pomodoro Settings',
                style: TextStyle(
                  color: ReadingSessionColors.popupTextColor,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPomodoroRow(
                    'Work',
                    workMinutes,
                    (v) => setDialogState(() => workMinutes = v),
                  ),
                  const SizedBox(height: 16),
                  _buildPomodoroRow(
                    'Break',
                    breakMinutes,
                    (v) => setDialogState(() => breakMinutes = v),
                  ),
                  const SizedBox(height: 16),
                  _buildPomodoroRow(
                    'Sessions',
                    sessions,
                    (v) => setDialogState(() => sessions = v),
                    isSessions: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: ReadingSessionColors.popupSecondaryText,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedMode = 2;
                      _targetSeconds = workMinutes * 60;
                      _remainingSeconds = _targetSeconds;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReadingSessionColors.pomodoroTabBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: TextStyle(
                      color: ReadingSessionColors.tabActiveText,
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPomodoroRow(
    String label,
    int value,
    Function(int) onChanged, {
    bool isSessions = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ReadingSessionColors.popupTextColor,
            fontFamily: 'SF-UI-Display',
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (value > (isSessions ? 1 : 5)) {
                  onChanged(value - (isSessions ? 1 : 5));
                }
              },
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: ReadingSessionColors.pomodoroTabBackground,
            ),
            Text(
              isSessions ? '$value' : '$value min',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ReadingSessionColors.popupTextColor,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            IconButton(
              onPressed: () {
                onChanged(value + (isSessions ? 1 : 5));
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: ReadingSessionColors.pomodoroTabBackground,
            ),
          ],
        ),
      ],
    );
  }

  void _endSession() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    Navigator.pop(context, _elapsedSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/reading_background2.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reading Session',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: ReadingSessionColors.headerTextColor,
                                    fontFamily: 'SF-UI-Display',
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.close,
                                    color: ReadingSessionColors.headerTextColor
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Book card
                            _buildBookCard(),
                            const SizedBox(height: 24),

                            // Mode tabs
                            _buildModeTabs(),
                            const SizedBox(height: 32),

                            // Timer circle
                            _buildTimerCircle(),
                            const SizedBox(height: 32),

                            // Stats row
                            _buildStatsRow(),
                            const SizedBox(height: 32),
                            const Spacer(), // pushes buttons down
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard() {
    const double readPercent = 0.35;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReadingSessionColors.bookCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 48, 48, 48).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
                    ? Image.network(
                      widget.book.coverUrl!,
                      width: 90,
                      height: 130,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 90,
                          height: 130,
                          color: Colors.grey[300],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 90,
                            height: 130,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                    )
                    : Container(
                      width: 70,
                      height: 96,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    widget.book.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: ReadingSessionColors.bookTitleColor,
                      fontFamily: 'SF-UI-Display',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.book.author,
                  style: TextStyle(
                    fontSize: 13,
                    color: ReadingSessionColors.bookAuthorColor,
                    fontFamily: 'SF-UI-Display',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(), // push progress to bottom
                // Progress
                Text(
                  '35% read',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ReadingSessionColors.progressTextColor,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: LinearProgressIndicator(
                      value: readPercent,
                      backgroundColor: ReadingSessionColors.progressTrackColor,
                      valueColor: const AlwaysStoppedAnimation(
                        ReadingSessionColors.progressFillColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Row(
      children: [
        _buildTab('Open Read', 0, ReadingSessionColors.tabActiveBackground),
        const SizedBox(width: 8),
        _buildTab('Target Read', 1, ReadingSessionColors.tabInactiveBackground),
        const SizedBox(width: 8),
        _buildTab(
          'Pomodoro Focus',
          2,
          ReadingSessionColors.pomodoroTabBackground,
        ),
      ],
    );
  }

  Widget _buildTab(String label, int mode, Color activeColor) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? activeColor : activeColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? ReadingSessionColors.tabActiveText
                        : ReadingSessionColors.tabActiveText.withValues(
                          alpha: 0.8,
                        ),
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle() {
    final displayTime =
        _selectedMode == 0
            ? _formatTime(_elapsedSeconds)
            : _formatTime(_remainingSeconds);

    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: ReadingSessionColors.timerCircleBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: ReadingSessionColors.timerCircleBorder,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: ReadingSessionColors.timerCircleBorder.withValues(
                alpha: 0.2,
              ),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayTime,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w300,
                color: ReadingSessionColors.timerTextColor,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'minutes',
              style: TextStyle(
                fontSize: 14,
                color: ReadingSessionColors.timerLabelColor,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.flag_outlined,
            iconColor: ReadingSessionColors.goalIconColor,
            label: 'Daily Goal',
            value: '$_dailyReadMinutes',
            suffix: ' / $_dailyGoalMinutes min',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: ReadingSessionColors.streakIconColor,
            label: 'Streak',
            value: '$_streakDays',
            suffix: ' days',
            subtext: 'Keep it up! 🎉',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String suffix = '',
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReadingSessionColors.statsCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ReadingSessionColors.statsLabelColor,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ReadingSessionColors.statsValueColor,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 14,
                    color: ReadingSessionColors.statsLabelColor,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 12,
                color: ReadingSessionColors.statsLabelColor,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isRunning ? _pauseTimer : _resumeTimer,
            icon: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: ReadingSessionColors.continueButtonText,
            ),
            label: Text(
              _isRunning ? 'Pause Reading' : 'Continue Reading',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ReadingSessionColors.continueButtonText,
                fontFamily: 'SF-UI-Display',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReadingSessionColors.continueButtonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _endSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: ReadingSessionColors.endButtonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'End Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ReadingSessionColors.endButtonText,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

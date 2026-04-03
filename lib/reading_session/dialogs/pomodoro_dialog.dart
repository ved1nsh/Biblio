import 'package:flutter/material.dart';
import '../constants/reading_session_colors.dart';

class PomodoroSettings {
  final int workMinutes;
  final int breakMinutes;
  final int sessions;

  PomodoroSettings({
    required this.workMinutes,
    required this.breakMinutes,
    required this.sessions,
  });
}

class PomodoroDialog extends StatefulWidget {
  const PomodoroDialog({super.key});

  @override
  State<PomodoroDialog> createState() => _PomodoroDialogState();
}

class _PomodoroDialogState extends State<PomodoroDialog> {
  int workMinutes = 25;
  int breakMinutes = 5;
  int sessions = 4;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ReadingSessionColors.popupBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
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
          _buildRow(
            'Work',
            workMinutes,
            (v) => setState(() => workMinutes = v),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'Break',
            breakMinutes,
            (v) => setState(() => breakMinutes = v),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'Sessions',
            sessions,
            (v) => setState(() => sessions = v),
            isSessions: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: ReadingSessionColors.popupSecondaryText,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
        ElevatedButton(
          onPressed:
              () => Navigator.pop(
                context,
                PomodoroSettings(
                  workMinutes: workMinutes,
                  breakMinutes: breakMinutes,
                  sessions: sessions,
                ),
              ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ReadingSessionColors.pomodoroTabBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Start',
            style: TextStyle(
              color: ReadingSessionColors.tabActiveText,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
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
          style: const TextStyle(
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
              style: const TextStyle(
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
}

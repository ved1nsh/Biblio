import 'package:flutter/material.dart';
import '../constants/reading_session_colors.dart';

class TargetReadDialog extends StatefulWidget {
  const TargetReadDialog({super.key});

  @override
  State<TargetReadDialog> createState() => _TargetReadDialogState();
}

class _TargetReadDialogState extends State<TargetReadDialog> {
  int selectedMinutes = 25;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ReadingSessionColors.popupBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
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
          const Text(
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
                    setState(() => selectedMinutes -= 5);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: ReadingSessionColors.tabActiveBackground,
              ),
              const SizedBox(width: 16),
              Text(
                '$selectedMinutes min',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ReadingSessionColors.popupTextColor,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() => selectedMinutes += 5);
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
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: ReadingSessionColors.popupSecondaryText,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedMinutes),
          style: ElevatedButton.styleFrom(
            backgroundColor: ReadingSessionColors.tabActiveBackground,
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';

class FocusModeScreen extends StatefulWidget {
  final ReadingTimerController timerController;

  const FocusModeScreen({super.key, required this.timerController});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  @override
  void initState() {
    super.initState();
    // Hide status bar for full immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    widget.timerController.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.timerController.removeListener(_onTick);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  String _minutesOnly(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    return '$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final controller = widget.timerController;
    final isCountdown =
        controller.selectedMode == 1 || controller.selectedMode == 2;
    final seconds =
        isCountdown ? controller.remainingSeconds : controller.elapsedSeconds;
    final minutesText = _minutesOnly(seconds);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap anywhere to exit
        behavior: HitTestBehavior.translucent,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Centered timer
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    minutesText,
                    style: TextStyle(
                      fontSize: (120 * scale).clamp(100.0, 120.0),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'SF-UI-Display',
                      letterSpacing: -4,
                    ),
                  ),
                  SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
                  Text(
                    'minutes',
                    style: TextStyle(
                      fontSize: (22 * scale).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w400,
                      color: Color(0x80FFFFFF),
                      fontFamily: 'SF-UI-Display',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Exit button at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: (56 * scale).clamp(48.0, 56.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Column(
                  children: [
                    Container(
                      width: (56 * scale).clamp(48.0, 56.0),
                      height: (56 * scale).clamp(48.0, 56.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: (28 * scale).clamp(24.0, 28.0),
                      ),
                    ),
                    SizedBox(height: (10 * scale).clamp(8.0, 10.0)),
                    Text(
                      'Exit Focus Mode',
                      style: TextStyle(
                        fontSize: (13 * scale).clamp(11.0, 13.0),
                        fontWeight: FontWeight.w500,
                        color: Color(0x80FFFFFF),
                        fontFamily: 'SF-UI-Display',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

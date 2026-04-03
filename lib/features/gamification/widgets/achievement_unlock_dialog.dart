import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:biblio/core/models/achievement_model.dart';
import 'package:biblio/core/constants/achievement_icons.dart';

class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Trigger animations
    Future.delayed(const Duration(milliseconds: 100), () {
      _confettiController.play();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final dialogRadius = (20 * scale).clamp(16.0, 20.0);
    final dialogPad = (24 * scale).clamp(18.0, 24.0);
    final iconBoxSize = (80 * scale).clamp(68.0, 80.0);
    final iconSize = (40 * scale).clamp(32.0, 40.0);
    final titleSize = (18 * scale).clamp(15.0, 18.0);
    final achievementTitleSize = (24 * scale).clamp(19.0, 24.0);
    final bodySize = (14 * scale).clamp(12.0, 14.0);
    final xpSize = (16 * scale).clamp(13.0, 16.0);
    final buttonTextSize = (16 * scale).clamp(13.0, 16.0);
    final buttonVerticalPad = (14 * scale).clamp(11.0, 14.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Dialog
        ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(dialogRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(dialogPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: _getTierColor(widget.achievement.tier),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getTierColor(
                            widget.achievement.tier,
                          ).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      AchievementIcons.getIcon(widget.achievement.id),
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    '🎉 Achievement Unlocked! 🎉',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Achievement Title
                  Text(
                    widget.achievement.title,
                    style: TextStyle(
                      fontSize: achievementTitleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    widget.achievement.description,
                    style: TextStyle(
                      fontSize: bodySize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // XP Reward
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${widget.achievement.xpReward} XP',
                      style: TextStyle(
                        fontSize: xpSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDismiss();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getTierColor(widget.achievement.tier),
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPad,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Awesome!',
                        style: TextStyle(
                          fontSize: buttonTextSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Confetti
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2, // Down
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.purple,
              Colors.orange,
            ],
          ),
        ),
      ],
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey[600]!;
      case 'gold':
        return Colors.amber[700]!;
      default:
        return Colors.blue;
    }
  }
}

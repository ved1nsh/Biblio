import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/xp_provider.dart';

/// A simple, flat greeting widget for the homepage.
///
/// Shows a greeting with the user's first name, a profile avatar,
/// and a streak-aware helper text below.
class HomepageGreeting extends ConsumerWidget {
  final String? userName;
  final String? userPhotoUrl;
  final VoidCallback? onProfileTap;

  const HomepageGreeting({
    super.key,
    this.userName,
    this.userPhotoUrl,
    this.onProfileTap,
  });

  String _getGreeting(String firstName) {
    final greetings = [
      'Hello, $firstName!',
      'Hey there, $firstName!',
      'Hola, $firstName!',
    ];
    final index = Random(DateTime.now().minute ~/ 15).nextInt(greetings.length);
    return greetings[index];
  }

  String _getStreakText(int streak) {
    if (streak > 0) {
      final options = [
        '$streak day strong, ready to continue?',
        'On a $streak-day roll, keep it going!',
        '$streak days and counting, nice work!',
        'Streak alive at $streak days, let\'s read!',
        'You\'ve been at it for $streak days!',
        'Day $streak, the momentum is real!',
      ];
      final index = Random(
        DateTime.now().millisecondsSinceEpoch ~/ 60000,
      ).nextInt(options.length);
      return options[index];
    } else {
      final options = [
        'Start your streak today!',
        'A fresh start awaits, let\'s read!',
        'Today could be day 1!',
        'Open a book and begin your journey!',
        'Your next streak starts now!',
        'Pick up a book and make today count!',
      ];
      final index = Random(
        DateTime.now().millisecondsSinceEpoch ~/ 60000,
      ).nextInt(options.length);
      return options[index];
    }
  }

  Widget _buildAvatar(String name, double scale) {
    final avatarSize = (40 * scale).clamp(36.0, 44.0);
    final avatarFontSize = (16 * scale).clamp(14.0, 18.0);

    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E0D4),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD5CBB8), width: 2),
          image:
              userPhotoUrl != null
                  ? DecorationImage(
                    image: NetworkImage(userPhotoUrl!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            userPhotoUrl == null
                ? Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: avatarFontSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF-UI-Display',
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = userName ?? 'Reader';
    final firstName = fullName.split(' ').first;
    final greeting = _getGreeting(firstName);

    final streakAsync = ref.watch(currentStreakProvider);
    final streak = streakAsync.whenOrNull(data: (v) => v) ?? 0;
    final helperText = _getStreakText(streak);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final textWidth = screenWidth * 0.62;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: textWidth,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.centerLeft,
                child: Text(
                  greeting,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'SF-UI-Display',
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const Spacer(),
            _buildAvatar(firstName, scale),
          ],
        ),
        const SizedBox(height: 4),
        // Streak helper text
        SizedBox(
          width: textWidth,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.centerLeft,
            child: Text(
              helperText,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w400,
                fontFamily: 'SF-UI-Display',
                color: Color(0xFF888888),
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

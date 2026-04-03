import 'package:biblio/core/providers/auth_provider.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionSummaryDialog extends ConsumerWidget {
  final String duration;
  final double progressGained;

  const SessionSummaryDialog({
    super.key,
    required this.duration,
    required this.progressGained,
  });

  String _firstName(AsyncValue authState) {
    final user = authState.value;
    final displayName = user?.displayName as String?;
    if (displayName == null || displayName.trim().isEmpty) return 'Reader';
    return displayName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final todaySecondsAsync = ref.watch(todayReadingSecondsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final xpProgressAsync = ref.watch(xpProgressProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final firstName = _firstName(authState);
    final streak = streakAsync.whenOrNull(data: (value) => value) ?? 0;
    final todaySeconds = todaySecondsAsync.whenOrNull(data: (value) => value);
    final isFirstReadToday = todaySeconds == 0;
    final streakAfterSession = isFirstReadToday ? streak + 1 : streak;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: (20 * scale).clamp(16.0, 20.0),
        vertical: (24 * scale).clamp(18.0, 24.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            (22 * scale).clamp(18.0, 22.0),
            (26 * scale).clamp(20.0, 26.0),
            (22 * scale).clamp(18.0, 22.0),
            (18 * scale).clamp(16.0, 18.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: (72 * scale).clamp(62.0, 72.0),
                height: (72 * scale).clamp(62.0, 72.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  isFirstReadToday ? '🔥' : '📚',
                  style: TextStyle(fontSize: (34 * scale).clamp(28.0, 34.0)),
                ),
              ),
              SizedBox(height: (18 * scale).clamp(14.0, 18.0)),
              Text(
                'Nice work, $firstName!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: (30 * scale).clamp(24.0, 30.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.05,
                ),
              ),
              SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
              Text(
                isFirstReadToday
                    ? 'You showed up today. That is how streaks are built.'
                    : 'Another session in the books. Keep the momentum going.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: (14 * scale).clamp(12.0, 14.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.52),
                  height: 1.35,
                ),
              ),
              if (isFirstReadToday) ...[
                SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (14 * scale).clamp(12.0, 14.0),
                    vertical: (8 * scale).clamp(7.0, 8.0),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🔥',
                        style: TextStyle(
                          fontSize: (17 * scale).clamp(15.0, 17.0),
                        ),
                      ),
                      SizedBox(width: (8 * scale).clamp(6.0, 8.0)),
                      Text(
                        streak == 0 ? 'Streak started!' : 'Streak extended!',
                        style: TextStyle(
                          fontFamily: 'NeueMontreal',
                          fontSize: (14 * scale).clamp(12.0, 14.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.76),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: (22 * scale).clamp(18.0, 22.0)),
                _StreakTransitionCard(
                  previousStreak: streak,
                  currentStreak: streakAfterSession,
                  scale: scale,
                ),
              ],
              SizedBox(height: (22 * scale).clamp(18.0, 22.0)),
              _TimeReadCard(duration: duration, scale: scale),
              SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
              _LevelProgressCard(
                scale: scale,
                profileAsync: profileAsync,
                xpProgressAsync: xpProgressAsync,
              ),
              SizedBox(height: (22 * scale).clamp(18.0, 22.0)),
              SizedBox(
                width: double.infinity,
                height: (54 * scale).clamp(46.0, 54.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('😐'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155EEF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'NeueMontreal',
                      fontSize: (18 * scale).clamp(15.0, 18.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakTransitionCard extends StatelessWidget {
  const _StreakTransitionCard({
    required this.previousStreak,
    required this.currentStreak,
    required this.scale,
  });

  final int previousStreak;
  final int currentStreak;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (18 * scale).clamp(14.0, 18.0),
        vertical: (18 * scale).clamp(14.0, 18.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StreakValue(
              value: previousStreak,
              label: previousStreak == 1 ? 'DAY STREAK' : 'DAYS STREAK',
              scale: scale,
              animate: false,
              dimmed: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (10 * scale).clamp(8.0, 10.0),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: (24 * scale).clamp(20.0, 24.0),
              color: Colors.black.withValues(alpha: 0.22),
            ),
          ),
          Expanded(
            child: _StreakValue(
              value: currentStreak,
              label: currentStreak == 1 ? 'DAY STREAK' : 'DAYS STREAK',
              scale: scale,
              animate: true,
              dimmed: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakValue extends StatelessWidget {
  const _StreakValue({
    required this.value,
    required this.label,
    required this.scale,
    required this.animate,
    required this.dimmed,
  });

  final int value;
  final String label;
  final double scale;
  final bool animate;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final numberColor =
        dimmed ? Colors.black.withValues(alpha: 0.45) : Colors.black;

    return Column(
      children: [
        Text('🔥', style: TextStyle(fontSize: (40 * scale).clamp(32.0, 40.0))),
        SizedBox(height: (10 * scale).clamp(8.0, 10.0)),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration:
              animate
                  ? const Duration(milliseconds: 900)
                  : const Duration(milliseconds: 0),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return Text(
              '${animate ? animatedValue.round() : value}',
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: (44 * scale).clamp(32.0, 44.0),
                fontWeight: FontWeight.w700,
                color: numberColor,
                height: 1,
              ),
            );
          },
        ),
        SizedBox(height: (4 * scale).clamp(2.0, 4.0)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NeueMontreal',
            fontSize: (14 * scale).clamp(11.0, 14.0),
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: dimmed ? 0.28 : 0.42),
            letterSpacing: 0.8,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _TimeReadCard extends StatelessWidget {
  const _TimeReadCard({required this.duration, required this.scale});

  final String duration;
  final double scale;

  int get _hours {
    final match = RegExp(r'(\d+)h').firstMatch(duration);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  int get _minutes {
    final match = RegExp(r'(\d+)m').firstMatch(duration);
    if (match != null) return int.tryParse(match.group(1) ?? '') ?? 0;
    return duration == '<1m' ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final hasHours = _hours > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (18 * scale).clamp(14.0, 18.0),
        vertical: (18 * scale).clamp(14.0, 18.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time read',
            style: TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: (14 * scale).clamp(12.0, 14.0),
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: (12 * scale).clamp(10.0, 12.0)),
          Row(
            children: [
              if (hasHours) ...[
                Expanded(
                  child: _AnimatedMetricNumber(
                    value: _hours,
                    label: _hours == 1 ? 'hour' : 'hours',
                    scale: scale,
                  ),
                ),
                SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
              ],
              Expanded(
                child: _AnimatedMetricNumber(
                  value: _minutes,
                  label: _minutes == 1 ? 'minute' : 'minutes',
                  scale: scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedMetricNumber extends StatelessWidget {
  const _AnimatedMetricNumber({
    required this.value,
    required this.label,
    required this.scale,
  });

  final int value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (14 * scale).clamp(12.0, 14.0),
        vertical: (14 * scale).clamp(12.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Text(
                '${animatedValue.round()}',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: (36 * scale).clamp(28.0, 36.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1,
                ),
              );
            },
          ),
          SizedBox(height: (6 * scale).clamp(4.0, 6.0)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: (13 * scale).clamp(11.0, 13.0),
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({
    required this.scale,
    required this.profileAsync,
    required this.xpProgressAsync,
  });

  final double scale;
  final AsyncValue<UserProfile?> profileAsync;
  final AsyncValue<Map<String, int>> xpProgressAsync;

  @override
  Widget build(BuildContext context) {
    final profile = profileAsync.whenOrNull(data: (value) => value);
    final xpProgress = xpProgressAsync.whenOrNull(data: (value) => value);

    if (profile == null || xpProgress == null) {
      return const SizedBox.shrink();
    }

    final current = xpProgress['current'] ?? 0;
    final min = xpProgress['min'] ?? 0;
    final max = xpProgress['max'] ?? 100;
    final levelRange = max - min;
    final progressInLevel = (current - min).clamp(0, levelRange);
    final progressValue = levelRange > 0 ? progressInLevel / levelRange : 0.0;
    final progressPercent = (progressValue * 100).round();
    final xpToNext = (max - current).clamp(0, max);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (18 * scale).clamp(14.0, 18.0),
        vertical: (18 * scale).clamp(14.0, 18.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E6D0)),
      ),
      child: Row(
        children: [
          Container(
            width: (54 * scale).clamp(46.0, 54.0),
            height: (54 * scale).clamp(46.0, 54.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF6ECD8),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '📚',
              style: TextStyle(fontSize: (28 * scale).clamp(24.0, 28.0)),
            ),
          ),
          SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Level ${profile.currentLevel} ($progressPercent%)',
                        style: TextStyle(
                          fontFamily: 'NeueMontreal',
                          fontSize: (18 * scale).clamp(15.0, 18.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '$xpToNext XP',
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: (15 * scale).clamp(13.0, 15.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (10 * scale).clamp(8.0, 10.0)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: (10 * scale).clamp(8.0, 10.0),
                    backgroundColor: const Color(0xFFEADFCB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2F7E84)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

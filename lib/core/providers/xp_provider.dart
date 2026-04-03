import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:biblio/core/models/user_profile_model.dart';
import 'package:biblio/core/services/xp_service.dart';
import 'package:biblio/core/services/streak_saver_service.dart';
import 'package:biblio/core/services/streak_service.dart';

final xpServiceProvider = Provider((ref) => XpService());

// User Profile Provider
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final xpService = ref.watch(xpServiceProvider);

  // Yield immediately with a timeout so the page never hangs
  try {
    final profile = await xpService.getUserProfile().timeout(
      const Duration(seconds: 10),
    );
    yield profile;
  } catch (_) {
    yield null;
  }

  // Poll every 10 seconds (was 5s — reduces load, gives each call breathing room)
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    try {
      final updatedProfile = await xpService.getUserProfile().timeout(
        const Duration(seconds: 10),
      );
      yield updatedProfile;
    } catch (_) {
      // skip this cycle silently
    }
  }
});

// Total XP Provider
final totalXpProvider = FutureProvider<int>((ref) async {
  final xpService = ref.watch(xpServiceProvider);
  return await xpService.getUserXP();
});

// Current Level Provider
final currentLevelProvider = FutureProvider<int>((ref) async {
  final xpService = ref.watch(xpServiceProvider);
  return await xpService.getUserLevel();
});

// XP Progress Provider (for progress bar)
final xpProgressProvider = FutureProvider<Map<String, int>>((ref) async {
  final xpService = ref.watch(xpServiceProvider);
  return await xpService.getXPProgress();
});

// Streak Savers Available Provider
final streakSaversProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.streakSaversAvailable ?? 0;
});

// Broken Streak Provider — checks if user has a broken streak to restore
final brokenStreakProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = StreakSaverService();
  return await service.checkBrokenStreak();
});

// Flag to suppress the broken-streak prompt after user taps "Start Fresh"
final brokenStreakDismissedProvider = StateProvider<bool>((ref) {
  return false;
});

// Current streak provider
final currentStreakProvider = FutureProvider<int>((ref) async {
  final service = StreakService();
  return await service.calculateCurrentStreak();
});

// Today's reading seconds provider
final todayReadingSecondsProvider = FutureProvider<int>((ref) async {
  final service = StreakService();
  return await service.getTodayReadingSeconds();
});

final currentWeekReadDaysProvider = FutureProvider<Set<DateTime>>((ref) async {
  final service = StreakService();
  final now = DateTime.now();
  final todayNorm = DateTime(now.year, now.month, now.day);
  final daysSinceSaturday = (now.weekday - 6 + 7) % 7;
  final weekStart = todayNorm.subtract(Duration(days: daysSinceSaturday));
  final weekEnd = weekStart.add(const Duration(days: 6));

  return await service.getReadingDaysInRange(weekStart, weekEnd);
});

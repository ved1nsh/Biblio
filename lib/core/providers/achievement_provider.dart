import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/achievement_model.dart';
import 'package:biblio/core/services/achievement_service.dart';

final achievementServiceProvider = Provider((ref) => AchievementService());

// Unlocked Achievements Provider
final unlockedAchievementsProvider =
    FutureProvider<List<UserAchievement>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getUnlockedAchievements();
});

// Locked Achievements Provider
final lockedAchievementsProvider =
    FutureProvider<List<UserAchievement>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getLockedAchievements();
});

// New Achievements (need confetti) Provider
final newAchievementsProvider =
    FutureProvider<List<UserAchievement>>((ref) async {
  final unlocked = await ref.watch(unlockedAchievementsProvider.future);
  return unlocked.where((ua) => ua.needsConfetti).toList();
});

// Achievement Progress Provider (for specific achievement)
final achievementProgressProvider =
    FutureProvider.family<Map<String, int>, String>((ref, achievementId) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getAchievementProgress(achievementId);
});

// Total Unlocked Count Provider
final unlockedCountProvider = FutureProvider<int>((ref) async {
  final unlocked = await ref.watch(unlockedAchievementsProvider.future);
  return unlocked.length;
});
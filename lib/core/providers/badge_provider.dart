import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/achievement_model.dart';
import 'package:biblio/core/services/badge_service.dart';

final badgeServiceProvider = Provider((ref) => BadgeService());

// Current Display Badge Provider
final displayBadgeProvider = FutureProvider<Achievement?>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return await service.getDisplayBadge();
});

// Selectable Badges Provider (unlocked achievements)
final selectableBadgesProvider =
    FutureProvider<List<Achievement>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return await service.getSelectableBadges();
});

// Set Display Badge Action
final setDisplayBadgeProvider =
    FutureProvider.family<void, String>((ref, achievementId) async {
  final service = ref.watch(badgeServiceProvider);
  await service.setDisplayBadge(achievementId);
  ref.invalidate(displayBadgeProvider); // Refresh
});

// Clear Display Badge Action
final clearDisplayBadgeProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  await service.clearDisplayBadge();
  ref.invalidate(displayBadgeProvider); // Refresh
});
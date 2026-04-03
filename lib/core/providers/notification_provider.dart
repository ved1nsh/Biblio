import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/notification_model.dart';
import 'package:biblio/core/services/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

// Real-time Notification Stream Provider
final notificationStreamProvider =
    StreamProvider<List<UserNotification>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream();
});

// Unread Notifications Provider
final unreadNotificationsProvider =
    FutureProvider<List<UserNotification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getUnreadNotifications();
});

// Unread Count Provider
final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getUnreadCount();
});

// All Notifications Provider
final allNotificationsProvider =
    FutureProvider<List<UserNotification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getAllNotifications();
});

// Action Required Notifications Provider (streak broken, etc.)
final actionRequiredNotificationsProvider =
    FutureProvider<List<UserNotification>>((ref) async {
  final unread = await ref.watch(unreadNotificationsProvider.future);
  return unread.where((n) => n.requiresAction).toList();
});
// lib/presentation/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Stream of all notifications (broadcasts)
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchAllNotifications();
});

/// Unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchUnreadCount();
});

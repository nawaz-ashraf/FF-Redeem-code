// lib/data/repositories/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _firestore = FirebaseService.firestore;

  /// Create a notification (admin sends)
  Future<void> createNotification({
    required String title,
    required String message,
    String? image,
    required NotificationType type,
    String? targetUserId,
  }) async {
    final data = {
      'title': title,
      'message': message,
      'image': image,
      'type': type.name,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'sentBy': FirebaseService.currentUserId,
    };

    if (targetUserId != null) {
      data['targetUserId'] = targetUserId;
    }

    await _firestore
        .collection(AppConstants.notificationsCollection)
        .add(data);
  }

  /// Send notification to all users (broadcast)
  Future<void> sendBroadcast({
    required String title,
    required String message,
    String? image,
    NotificationType type = NotificationType.announcement,
  }) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .add({
      'title': title,
      'message': message,
      'image': image,
      'type': type.name,
      'isRead': false,
      'broadcast': true,
      'createdAt': FieldValue.serverTimestamp(),
      'sentBy': FirebaseService.currentUserId,
    });
  }

  /// Stream of notifications (broadcasts + user-specific)
  Stream<List<NotificationModel>> watchNotifications({String? userId}) {
    // Get broadcast notifications and user-specific ones
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      return snap.docs
          .where((d) {
        final data = d.data() as Map<String, dynamic>;
        final isBroadcast = data['type'] == 'broadcast' || data['broadcast'] == true;
        final isTargeted = data['targetUserId'] == userId;
        return isBroadcast || isTargeted || data['targetUserId'] == null;
      }).map((d) => NotificationModel.fromFirestore(d)).toList();
    });
  }

  /// Get all notifications as stream (simpler approach)
  Stream<List<NotificationModel>> watchAllNotifications() {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final snap = await _firestore
        .collection(AppConstants.notificationsCollection)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get unread notification count
  Stream<int> watchUnreadCount() {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .delete();
  }
}

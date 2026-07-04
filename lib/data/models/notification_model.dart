// lib/data/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  dailyReward,
  newVersion,
  redeemApproved,
  redeemRejected,
  newEvent,
  maintenance,
  announcement,
  referralReward,
}

extension NotificationTypeExt on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.dailyReward:
        return 'Daily Reward';
      case NotificationType.newVersion:
        return 'New Version';
      case NotificationType.redeemApproved:
        return 'Redeem Approved';
      case NotificationType.redeemRejected:
        return 'Redeem Rejected';
      case NotificationType.newEvent:
        return 'New Event';
      case NotificationType.maintenance:
        return 'Maintenance';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.referralReward:
        return 'Referral Reward';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.dailyReward:
        return '🎁';
      case NotificationType.newVersion:
        return '🆕';
      case NotificationType.redeemApproved:
        return '✅';
      case NotificationType.redeemRejected:
        return '❌';
      case NotificationType.newEvent:
        return '🎉';
      case NotificationType.maintenance:
        return '🔧';
      case NotificationType.announcement:
        return '📢';
      case NotificationType.referralReward:
        return '👥';
    }
  }

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.announcement;
    for (final type in NotificationType.values) {
      if (type.name == value) return type;
    }
    return NotificationType.announcement;
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? image;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.image,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? data['body'] ?? '',
      image: data['image'],
      type: NotificationTypeExt.fromString(data['type']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'image': image,
      'type': type.name,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      image: image,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

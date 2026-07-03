// lib/data/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  adReward,
  dailyLogin,
  scratch,
  spin,
  referral,
  redeem,
  adminAdjustment,
}

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.adReward:
        return 'Watch Ad';
      case TransactionType.dailyLogin:
        return 'Daily Login';
      case TransactionType.scratch:
        return 'Scratch Card';
      case TransactionType.spin:
        return 'Spin Wheel';
      case TransactionType.referral:
        return 'Referral Bonus';
      case TransactionType.redeem:
        return 'Redeem';
      case TransactionType.adminAdjustment:
        return 'Admin Adjustment';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.adReward:
        return '📺';
      case TransactionType.dailyLogin:
        return '🎁';
      case TransactionType.scratch:
        return '🎴';
      case TransactionType.spin:
        return '🎡';
      case TransactionType.referral:
        return '👥';
      case TransactionType.redeem:
        return '💎';
      case TransactionType.adminAdjustment:
        return '⚙️';
    }
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final int coins;
  final bool isCredit; // true = add, false = deduct
  final String description;
  final DateTime createdAt;
  final String status; // completed, pending, failed

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.coins,
    required this.isCredit,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => TransactionType.adminAdjustment,
      ),
      coins: (data['coins'] ?? 0).toInt(),
      isCredit: data['isCredit'] ?? true,
      description: data['description'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'coins': coins,
      'isCredit': isCredit,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}

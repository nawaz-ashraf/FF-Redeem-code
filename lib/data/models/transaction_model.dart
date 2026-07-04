// lib/data/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  rewardedAd,
  scratch,
  spin,
  referral,
  dailyLogin,
  redeemRequest,
  redeemApproved,
  redeemRejected,
  adminCredit,
  adminDebit,
}

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.rewardedAd:
        return 'Rewarded Ad';
      case TransactionType.scratch:
        return 'Scratch Card';
      case TransactionType.spin:
        return 'Spin Wheel';
      case TransactionType.referral:
        return 'Referral Bonus';
      case TransactionType.dailyLogin:
        return 'Daily Login';
      case TransactionType.redeemRequest:
        return 'Redeem Request';
      case TransactionType.redeemApproved:
        return 'Redeem Approved';
      case TransactionType.redeemRejected:
        return 'Redeem Rejected';
      case TransactionType.adminCredit:
        return 'Admin Credit';
      case TransactionType.adminDebit:
        return 'Admin Debit';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.rewardedAd:
        return '📺';
      case TransactionType.scratch:
        return '🎴';
      case TransactionType.spin:
        return '🎡';
      case TransactionType.referral:
        return '👥';
      case TransactionType.dailyLogin:
        return '🎁';
      case TransactionType.redeemRequest:
        return '💎';
      case TransactionType.redeemApproved:
        return '✅';
      case TransactionType.redeemRejected:
        return '❌';
      case TransactionType.adminCredit:
        return '⬆️';
      case TransactionType.adminDebit:
        return '⬇️';
    }
  }

  bool get isCredit {
    switch (this) {
      case TransactionType.rewardedAd:
      case TransactionType.scratch:
      case TransactionType.spin:
      case TransactionType.referral:
      case TransactionType.dailyLogin:
      case TransactionType.redeemRejected:
      case TransactionType.adminCredit:
        return true;
      case TransactionType.redeemRequest:
      case TransactionType.redeemApproved:
      case TransactionType.adminDebit:
        return false;
    }
  }

  /// Parse from Firestore string, supporting both old and new names
  static TransactionType fromString(String? value) {
    if (value == null) return TransactionType.adminCredit;
    // Support legacy enum names from previous schema
    switch (value) {
      case 'rewardedAd':
      case 'adReward':
        return TransactionType.rewardedAd;
      case 'scratch':
        return TransactionType.scratch;
      case 'spin':
        return TransactionType.spin;
      case 'referral':
        return TransactionType.referral;
      case 'dailyLogin':
        return TransactionType.dailyLogin;
      case 'redeemRequest':
      case 'redeem':
        return TransactionType.redeemRequest;
      case 'redeemApproved':
        return TransactionType.redeemApproved;
      case 'redeemRejected':
        return TransactionType.redeemRejected;
      case 'adminCredit':
        return TransactionType.adminCredit;
      case 'adminDebit':
        return TransactionType.adminDebit;
      case 'adminAdjustment':
        return TransactionType.adminCredit;
      default:
        return TransactionType.adminCredit;
    }
  }
}

class TransactionModel {
  final String transactionId;
  final String userId;
  final TransactionType type;
  final int rewardAmount;
  final int balanceBefore;
  final int balanceAfter;
  final String? referenceId;
  final String description;
  final String status; // completed, pending, failed
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.rewardAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  bool get isCredit => type.isCredit;

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      transactionId: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionTypeExt.fromString(data['type']),
      rewardAmount: (data['rewardAmount'] ?? data['coins'] ?? 0).toInt(),
      balanceBefore: (data['balanceBefore'] ?? 0).toInt(),
      balanceAfter: (data['balanceAfter'] ?? 0).toInt(),
      referenceId: data['referenceId'],
      description: data['description'] ?? '',
      status: data['status'] ?? 'completed',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'rewardAmount': rewardAmount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

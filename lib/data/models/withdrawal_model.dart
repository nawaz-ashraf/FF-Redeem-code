// lib/data/models/withdrawal_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus { pending, approved, rejected }

extension WithdrawalStatusExt on WithdrawalStatus {
  String get label {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }
}

class WithdrawalModel {
  final String id;
  final String userId;
  final String ffUid;
  final String packageName;
  final int coinAmount;
  final String packageValue; // e.g., "₹100"
  final WithdrawalStatus status;
  final String? redeemCode;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WithdrawalModel({
    required this.id,
    required this.userId,
    required this.ffUid,
    required this.packageName,
    required this.coinAmount,
    required this.packageValue,
    required this.status,
    this.redeemCode,
    this.adminNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      ffUid: data['ffUid'] ?? '',
      packageName: data['packageName'] ?? '',
      coinAmount: (data['coinAmount'] ?? 0).toInt(),
      packageValue: data['packageValue'] ?? '',
      status: WithdrawalStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      redeemCode: data['redeemCode'],
      adminNotes: data['adminNotes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'ffUid': ffUid,
      'packageName': packageName,
      'coinAmount': coinAmount,
      'packageValue': packageValue,
      'status': status.name,
      'redeemCode': redeemCode,
      'adminNotes': adminNotes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : null,
    };
  }

  WithdrawalModel copyWith({
    WithdrawalStatus? status,
    String? redeemCode,
    String? adminNotes,
    DateTime? updatedAt,
  }) {
    return WithdrawalModel(
      id: id,
      userId: userId,
      ffUid: ffUid,
      packageName: packageName,
      coinAmount: coinAmount,
      packageValue: packageValue,
      status: status ?? this.status,
      redeemCode: redeemCode ?? this.redeemCode,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

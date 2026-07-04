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

  static WithdrawalStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return WithdrawalStatus.approved;
      case 'rejected':
        return WithdrawalStatus.rejected;
      default:
        return WithdrawalStatus.pending;
    }
  }
}

class WithdrawalModel {
  final String withdrawalId;
  final String userId;
  final String freeFireUID;
  final String package;
  final int coinCost;
  final String packageValue; // e.g., "₹100"
  final WithdrawalStatus status;
  final String? assignedRedeemCode;
  final String? adminRemark;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;

  const WithdrawalModel({
    required this.withdrawalId,
    required this.userId,
    required this.freeFireUID,
    required this.package,
    required this.coinCost,
    required this.packageValue,
    required this.status,
    this.assignedRedeemCode,
    this.adminRemark,
    required this.requestedAt,
    this.approvedAt,
    this.completedAt,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      withdrawalId: doc.id,
      userId: data['userId'] ?? '',
      freeFireUID: data['freeFireUID'] ?? data['ffUid'] ?? '',
      package: data['package'] ?? data['packageName'] ?? '',
      coinCost: (data['coinCost'] ?? data['coinAmount'] ?? 0).toInt(),
      packageValue: data['packageValue'] ?? '',
      status: WithdrawalStatusExt.fromString(data['status']),
      assignedRedeemCode:
          data['assignedRedeemCode'] ?? data['redeemCode'],
      adminRemark: data['adminRemark'] ?? data['adminNotes'],
      requestedAt: _toDateTime(data['requestedAt'] ?? data['createdAt']) ??
          DateTime.now(),
      approvedAt: _toDateTime(data['approvedAt']),
      completedAt: _toDateTime(data['completedAt'] ?? data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'freeFireUID': freeFireUID,
      'package': package,
      'coinCost': coinCost,
      'packageValue': packageValue,
      'status': status.name,
      'assignedRedeemCode': assignedRedeemCode,
      'adminRemark': adminRemark,
      'requestedAt': FieldValue.serverTimestamp(),
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  WithdrawalModel copyWith({
    WithdrawalStatus? status,
    String? assignedRedeemCode,
    String? adminRemark,
    DateTime? approvedAt,
    DateTime? completedAt,
  }) {
    return WithdrawalModel(
      withdrawalId: withdrawalId,
      userId: userId,
      freeFireUID: freeFireUID,
      package: package,
      coinCost: coinCost,
      packageValue: packageValue,
      status: status ?? this.status,
      assignedRedeemCode: assignedRedeemCode ?? this.assignedRedeemCode,
      adminRemark: adminRemark ?? this.adminRemark,
      requestedAt: requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

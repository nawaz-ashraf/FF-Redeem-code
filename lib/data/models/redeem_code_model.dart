// lib/data/models/redeem_code_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum RedeemCodeStatus { available, assigned, used }

extension RedeemCodeStatusExt on RedeemCodeStatus {
  String get label {
    switch (this) {
      case RedeemCodeStatus.available:
        return 'Available';
      case RedeemCodeStatus.assigned:
        return 'Assigned';
      case RedeemCodeStatus.used:
        return 'Used';
    }
  }

  static RedeemCodeStatus fromString(String? value) {
    switch (value) {
      case 'assigned':
        return RedeemCodeStatus.assigned;
      case 'used':
        return RedeemCodeStatus.used;
      default:
        return RedeemCodeStatus.available;
    }
  }
}

class RedeemCodeModel {
  final String code;
  final String package;
  final String value; // e.g., "₹100"
  final RedeemCodeStatus status;
  final String? assignedUser;
  final DateTime? assignedDate;
  final DateTime createdDate;
  final String createdBy;

  const RedeemCodeModel({
    required this.code,
    required this.package,
    required this.value,
    required this.status,
    this.assignedUser,
    this.assignedDate,
    required this.createdDate,
    required this.createdBy,
  });

  factory RedeemCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RedeemCodeModel(
      code: data['code'] ?? doc.id,
      package: data['package'] ?? '',
      value: data['value'] ?? '',
      status: RedeemCodeStatusExt.fromString(data['status']),
      assignedUser: data['assignedUser'],
      assignedDate: data['assignedDate'] != null
          ? (data['assignedDate'] as Timestamp).toDate()
          : null,
      createdDate: data['createdDate'] != null
          ? (data['createdDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'package': package,
      'value': value,
      'status': status.name,
      'assignedUser': assignedUser,
      'assignedDate':
          assignedDate != null ? Timestamp.fromDate(assignedDate!) : null,
      'createdDate': Timestamp.fromDate(createdDate),
      'createdBy': createdBy,
    };
  }

  RedeemCodeModel copyWith({
    RedeemCodeStatus? status,
    String? assignedUser,
    DateTime? assignedDate,
  }) {
    return RedeemCodeModel(
      code: code,
      package: package,
      value: value,
      status: status ?? this.status,
      assignedUser: assignedUser ?? this.assignedUser,
      assignedDate: assignedDate ?? this.assignedDate,
      createdDate: createdDate,
      createdBy: createdBy,
    );
  }
}

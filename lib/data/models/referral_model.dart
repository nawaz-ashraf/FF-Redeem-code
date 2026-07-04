// lib/data/models/referral_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralModel {
  final String referralId;
  final String inviterId;
  final String newUserId;
  final int reward;
  final String status; // completed, pending
  final DateTime createdAt;

  const ReferralModel({
    required this.referralId,
    required this.inviterId,
    required this.newUserId,
    required this.reward,
    required this.status,
    required this.createdAt,
  });

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralModel(
      referralId: doc.id,
      inviterId: data['inviterId'] ?? data['referrerId'] ?? '',
      newUserId: data['newUserId'] ?? data['referredUserId'] ?? '',
      reward: (data['reward'] ?? data['coinsRewarded'] ?? 0).toInt(),
      status: data['status'] ?? 'completed',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inviterId': inviterId,
      'newUserId': newUserId,
      'reward': reward,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

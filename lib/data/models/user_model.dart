// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String ffUid;
  final String? profilePicUrl;
  final int coins;
  final String referralCode;
  final String? referredBy;
  final int referralCount;
  final int totalEarned;
  final int totalRedeemed;
  final int dailyStreak;
  final int xp;
  final int level;
  final DateTime? lastLoginDate;
  final DateTime registrationDate;
  final String deviceId;
  final String status; // active, banned, suspended
  final bool isAdmin;
  final Map<String, dynamic>? achievements;
  final DateTime? lastUpdated;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.ffUid,
    this.profilePicUrl,
    required this.coins,
    required this.referralCode,
    this.referredBy,
    required this.referralCount,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.dailyStreak,
    required this.xp,
    required this.level,
    this.lastLoginDate,
    required this.registrationDate,
    required this.deviceId,
    required this.status,
    required this.isAdmin,
    this.achievements,
    this.lastUpdated,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      ffUid: data['ffUid'] ?? '',
      profilePicUrl: data['profilePicUrl'],
      coins: (data['coins'] ?? 0).toInt(),
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      referralCount: (data['referralCount'] ?? 0).toInt(),
      totalEarned: (data['totalEarned'] ?? 0).toInt(),
      totalRedeemed: (data['totalRedeemed'] ?? 0).toInt(),
      dailyStreak: (data['dailyStreak'] ?? 0).toInt(),
      xp: (data['xp'] ?? 0).toInt(),
      level: (data['level'] ?? 1).toInt(),
      lastLoginDate: data['lastLoginDate'] != null
          ? (data['lastLoginDate'] as Timestamp).toDate()
          : null,
      registrationDate: data['registrationDate'] != null
          ? (data['registrationDate'] as Timestamp).toDate()
          : DateTime.now(),
      deviceId: data['deviceId'] ?? '',
      status: data['status'] ?? 'active',
      isAdmin: data['isAdmin'] ?? false,
      achievements: data['achievements'],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'ffUid': ffUid,
      'profilePicUrl': profilePicUrl,
      'coins': coins,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'totalEarned': totalEarned,
      'totalRedeemed': totalRedeemed,
      'dailyStreak': dailyStreak,
      'xp': xp,
      'level': level,
      'lastLoginDate': lastLoginDate != null
          ? Timestamp.fromDate(lastLoginDate!)
          : null,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'deviceId': deviceId,
      'status': status,
      'isAdmin': isAdmin,
      'achievements': achievements,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? profilePicUrl,
    int? coins,
    int? referralCount,
    int? totalEarned,
    int? totalRedeemed,
    int? dailyStreak,
    int? xp,
    int? level,
    DateTime? lastLoginDate,
    String? status,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      ffUid: ffUid,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      coins: coins ?? this.coins,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount ?? this.referralCount,
      totalEarned: totalEarned ?? this.totalEarned,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      registrationDate: registrationDate,
      deviceId: deviceId,
      status: status ?? this.status,
      isAdmin: isAdmin,
      achievements: achievements,
      lastUpdated: DateTime.now(),
    );
  }
}

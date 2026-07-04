// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String freeFireUID;
  final String deviceId;
  final String? email;
  final String? profileImage;

  // Coin balances
  final int coins;
  final int totalEarnedCoins;
  final int totalRedeemedCoins;
  final int totalAdsWatched;

  // Daily counters
  final int scratchToday;
  final int spinToday;
  final int adsToday;

  // Date tracking
  final DateTime? lastLogin;
  final DateTime? lastScratchDate;
  final DateTime? lastSpinDate;
  final DateTime? lastAdDate;
  final DateTime? dailyLoginDate;

  // Referral
  final String referralCode;
  final String? referredBy;
  final int referralCount;

  // Withdrawal
  final int withdrawalCount;

  // Account
  final String accountStatus; // active, banned, suspended
  final bool isBanned;
  final bool isAdmin;

  // Gamification
  final int dailyStreak;
  final int xp;
  final int level;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Optional extras
  final Map<String, dynamic>? achievements;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.name,
    required this.freeFireUID,
    required this.deviceId,
    this.email,
    this.profileImage,
    required this.coins,
    required this.totalEarnedCoins,
    required this.totalRedeemedCoins,
    required this.totalAdsWatched,
    required this.scratchToday,
    required this.spinToday,
    required this.adsToday,
    this.lastLogin,
    this.lastScratchDate,
    this.lastSpinDate,
    this.lastAdDate,
    this.dailyLoginDate,
    required this.referralCode,
    this.referredBy,
    required this.referralCount,
    required this.withdrawalCount,
    required this.accountStatus,
    required this.isBanned,
    required this.isAdmin,
    required this.dailyStreak,
    required this.xp,
    required this.level,
    required this.createdAt,
    this.updatedAt,
    this.achievements,
    this.fcmToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      freeFireUID: data['freeFireUID'] ?? data['ffUid'] ?? '',
      deviceId: data['deviceId'] ?? '',
      email: data['email'],
      profileImage: data['profileImage'] ?? data['profilePicUrl'],
      coins: (data['coins'] ?? 0).toInt(),
      totalEarnedCoins:
          (data['totalEarnedCoins'] ?? data['totalEarned'] ?? 0).toInt(),
      totalRedeemedCoins:
          (data['totalRedeemedCoins'] ?? data['totalRedeemed'] ?? 0).toInt(),
      totalAdsWatched: (data['totalAdsWatched'] ?? 0).toInt(),
      scratchToday: (data['scratchToday'] ?? 0).toInt(),
      spinToday: (data['spinToday'] ?? 0).toInt(),
      adsToday: (data['adsToday'] ?? 0).toInt(),
      lastLogin: _toDateTime(data['lastLogin'] ?? data['lastLoginDate']),
      lastScratchDate: _toDateTime(data['lastScratchDate']),
      lastSpinDate: _toDateTime(data['lastSpinDate']),
      lastAdDate: _toDateTime(data['lastAdDate']),
      dailyLoginDate: _toDateTime(data['dailyLoginDate']),
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      referralCount: (data['referralCount'] ?? 0).toInt(),
      withdrawalCount: (data['withdrawalCount'] ?? 0).toInt(),
      accountStatus: data['accountStatus'] ?? data['status'] ?? 'active',
      isBanned: data['isBanned'] ?? (data['status'] == 'banned'),
      isAdmin: data['isAdmin'] ?? false,
      dailyStreak: (data['dailyStreak'] ?? 0).toInt(),
      xp: (data['xp'] ?? 0).toInt(),
      level: (data['level'] ?? 1).toInt(),
      createdAt: _toDateTime(data['createdAt'] ?? data['registrationDate']) ??
          DateTime.now(),
      updatedAt: _toDateTime(data['updatedAt'] ?? data['lastUpdated']),
      achievements: data['achievements'] as Map<String, dynamic>?,
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'freeFireUID': freeFireUID,
      'deviceId': deviceId,
      'email': email,
      'profileImage': profileImage,
      'coins': coins,
      'totalEarnedCoins': totalEarnedCoins,
      'totalRedeemedCoins': totalRedeemedCoins,
      'totalAdsWatched': totalAdsWatched,
      'scratchToday': scratchToday,
      'spinToday': spinToday,
      'adsToday': adsToday,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'lastScratchDate':
          lastScratchDate != null ? Timestamp.fromDate(lastScratchDate!) : null,
      'lastSpinDate':
          lastSpinDate != null ? Timestamp.fromDate(lastSpinDate!) : null,
      'lastAdDate':
          lastAdDate != null ? Timestamp.fromDate(lastAdDate!) : null,
      'dailyLoginDate':
          dailyLoginDate != null ? Timestamp.fromDate(dailyLoginDate!) : null,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'withdrawalCount': withdrawalCount,
      'accountStatus': accountStatus,
      'isBanned': isBanned,
      'isAdmin': isAdmin,
      'dailyStreak': dailyStreak,
      'xp': xp,
      'level': level,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'achievements': achievements,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? name,
    String? freeFireUID,
    String? email,
    String? profileImage,
    int? coins,
    int? totalEarnedCoins,
    int? totalRedeemedCoins,
    int? totalAdsWatched,
    int? scratchToday,
    int? spinToday,
    int? adsToday,
    DateTime? lastLogin,
    DateTime? lastScratchDate,
    DateTime? lastSpinDate,
    DateTime? lastAdDate,
    DateTime? dailyLoginDate,
    int? referralCount,
    int? withdrawalCount,
    String? accountStatus,
    bool? isBanned,
    int? dailyStreak,
    int? xp,
    int? level,
    Map<String, dynamic>? achievements,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      freeFireUID: freeFireUID ?? this.freeFireUID,
      deviceId: deviceId,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      coins: coins ?? this.coins,
      totalEarnedCoins: totalEarnedCoins ?? this.totalEarnedCoins,
      totalRedeemedCoins: totalRedeemedCoins ?? this.totalRedeemedCoins,
      totalAdsWatched: totalAdsWatched ?? this.totalAdsWatched,
      scratchToday: scratchToday ?? this.scratchToday,
      spinToday: spinToday ?? this.spinToday,
      adsToday: adsToday ?? this.adsToday,
      lastLogin: lastLogin ?? this.lastLogin,
      lastScratchDate: lastScratchDate ?? this.lastScratchDate,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      lastAdDate: lastAdDate ?? this.lastAdDate,
      dailyLoginDate: dailyLoginDate ?? this.dailyLoginDate,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount ?? this.referralCount,
      withdrawalCount: withdrawalCount ?? this.withdrawalCount,
      accountStatus: accountStatus ?? this.accountStatus,
      isBanned: isBanned ?? this.isBanned,
      isAdmin: isAdmin,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      achievements: achievements ?? this.achievements,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  /// Helper to parse Firestore Timestamp or null safely
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

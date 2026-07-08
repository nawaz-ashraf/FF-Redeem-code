// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String uuid;
  final String userId;
  final String deviceId;
  final String? email;
  final String? password;
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
  final DateTime? lastDailyReset;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Optional extras
  final Map<String, dynamic>? achievements;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.name,
    required this.uuid,
    required this.userId,
    required this.deviceId,
    this.email,
    this.password,
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
    this.lastDailyReset,
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
      uuid: data['uuid'] ?? doc.id,
      userId: data['userId'] ?? (data['uuid'] != null ? data['uuid'].toString().substring(0, 8).toUpperCase() : doc.id.substring(0, 8).toUpperCase()),
      deviceId: data['deviceId'] ?? '',
      email: data['email'],
      password: data['password'],
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
      lastDailyReset: _toDateTime(data['lastDailyReset']),
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
      'uuid': uuid,
      'userId': userId,
      'deviceId': deviceId,
      'email': email,
      if (password != null) 'password': password,
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
      'lastDailyReset': lastDailyReset != null ? Timestamp.fromDate(lastDailyReset!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'achievements': achievements,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? name,
    String? uuid,
    String? userId,
    String? email,
    String? password,
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
    DateTime? lastDailyReset,
    Map<String, dynamic>? achievements,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      deviceId: deviceId,
      email: email ?? this.email,
      password: password ?? this.password,
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
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
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

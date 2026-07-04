// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class UserRepository {
  final _firestore = FirebaseService.firestore;
  final _storage = FirebaseService.storage;

  /// Real-time stream of a user document
  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Get user once
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update arbitrary fields on a user document
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  /// Add coins to a user with transaction logging including balance tracking
  Future<void> addCoins({
    required String userId,
    required int coins,
    required TransactionType type,
    required String description,
    String? referenceId,
  }) async {
    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) return;
      final currentCoins = (userDoc.data()!['coins'] ?? 0).toInt();

      tx.update(userRef, {
        'coins': FieldValue.increment(coins),
        'totalEarnedCoins': FieldValue.increment(coins),
        'xp': FieldValue.increment(coins ~/ 2),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': userId,
        'type': type.name,
        'rewardAmount': coins,
        'balanceBefore': currentCoins,
        'balanceAfter': currentCoins + coins,
        'referenceId': referenceId,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    });
  }

  /// Deduct coins from a user (used during redeem approval)
  Future<bool> deductCoins({
    required String userId,
    required int coins,
    String? description,
    String? referenceId,
    TransactionType type = TransactionType.redeemApproved,
  }) async {
    bool success = false;
    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) return;
      final currentCoins = (userDoc.data()!['coins'] ?? 0).toInt();

      if (currentCoins < coins) {
        success = false;
        return;
      }

      tx.update(userRef, {
        'coins': FieldValue.increment(-coins),
        'totalRedeemedCoins': FieldValue.increment(coins),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (description != null) {
        final txRef = _firestore
            .collection(AppConstants.transactionsCollection)
            .doc();
        tx.set(txRef, {
          'userId': userId,
          'type': type.name,
          'rewardAmount': coins,
          'balanceBefore': currentCoins,
          'balanceAfter': currentCoins - coins,
          'referenceId': referenceId,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
      }

      success = true;
    });
    return success;
  }

  /// Process daily login reward with streak tracking
  Future<void> updateDailyLogin(String userId) async {
    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final currentCoins = (data['coins'] ?? 0).toInt();
      final lastLoginRaw = data['dailyLoginDate'] ?? data['lastLogin'];
      final lastLogin = lastLoginRaw is Timestamp
          ? lastLoginRaw.toDate()
          : null;
      final now = DateTime.now();

      int newStreak = (data['dailyStreak'] ?? 0).toInt();

      if (lastLogin == null) {
        newStreak = 1;
      } else {
        final dayDiff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastLogin.year, lastLogin.month, lastLogin.day))
            .inDays;
        if (dayDiff == 1) {
          newStreak = newStreak + 1;
          if (newStreak > 7) newStreak = 1;
        } else if (dayDiff > 1) {
          newStreak = 1;
        }
      }

      final streakBonus = AppConstants.streakBonuses[newStreak] ??
          AppConstants.dailyLoginCoins;

      tx.update(userRef, {
        'dailyLoginDate': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'dailyStreak': newStreak,
        'coins': FieldValue.increment(streakBonus),
        'totalEarnedCoins': FieldValue.increment(streakBonus),
        'xp': FieldValue.increment(streakBonus ~/ 2),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': userId,
        'type': 'dailyLogin',
        'rewardAmount': streakBonus,
        'balanceBefore': currentCoins,
        'balanceAfter': currentCoins + streakBonus,
        'description': 'Day $newStreak daily login bonus',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    });
  }

  /// Update daily counter for ads watched
  Future<void> incrementAdsToday(String userId) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final lastAdDate = data['lastAdDate'] is Timestamp
          ? (data['lastAdDate'] as Timestamp).toDate()
          : null;
      final lastAdStr = lastAdDate != null
          ? '${lastAdDate.year}-${lastAdDate.month}-${lastAdDate.day}'
          : '';

      if (lastAdStr != todayStr) {
        // New day, reset counter
        tx.update(userRef, {
          'adsToday': 1,
          'lastAdDate': FieldValue.serverTimestamp(),
          'totalAdsWatched': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(userRef, {
          'adsToday': FieldValue.increment(1),
          'totalAdsWatched': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Update daily counter for scratch cards
  Future<void> incrementScratchToday(String userId) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final lastDate = data['lastScratchDate'] is Timestamp
          ? (data['lastScratchDate'] as Timestamp).toDate()
          : null;
      final lastStr = lastDate != null
          ? '${lastDate.year}-${lastDate.month}-${lastDate.day}'
          : '';

      if (lastStr != todayStr) {
        tx.update(userRef, {
          'scratchToday': 1,
          'lastScratchDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(userRef, {
          'scratchToday': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Update daily counter for spins
  Future<void> incrementSpinToday(String userId) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final lastDate = data['lastSpinDate'] is Timestamp
          ? (data['lastSpinDate'] as Timestamp).toDate()
          : null;
      final lastStr = lastDate != null
          ? '${lastDate.year}-${lastDate.month}-${lastDate.day}'
          : '';

      if (lastStr != todayStr) {
        tx.update(userRef, {
          'spinToday': 1,
          'lastSpinDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(userRef, {
          'spinToday': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(String userId, File file) async {
    final ref = _storage.ref('profile_pics/$userId.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    // Update Firestore with new URL
    await updateUser(userId, {'profileImage': url});
    return url;
  }

  /// Stream of user's transactions with optional type filter
  Stream<List<TransactionModel>> watchTransactions(
    String userId, {
    String? typeFilter,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: userId);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList());
  }

  /// Get paginated transactions
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    String? typeFilter,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: userId);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => TransactionModel.fromFirestore(d))
        .toList();
  }

  /// Update FCM token for push notifications
  Future<void> updateFCMToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

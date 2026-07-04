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

  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  Future<void> addCoins({
    required String userId,
    required int coins,
    required TransactionType type,
    required String description,
  }) async {
    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) return;

      tx.update(userRef, {
        'coins': FieldValue.increment(coins),
        'totalEarned': FieldValue.increment(coins),
        'xp': FieldValue.increment(coins ~/ 2),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': userId,
        'type': type.name,
        'coins': coins,
        'isCredit': true,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    });
  }

  Future<bool> deductCoins({
    required String userId,
    required int coins,
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
        'totalRedeemed': FieldValue.increment(coins),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      success = true;
    });
    return success;
  }

  Future<void> updateDailyLogin(String userId) async {
    await _firestore.runTransaction((tx) async {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final lastLogin = data['lastLoginDate'] != null
          ? (data['lastLoginDate'] as Timestamp).toDate()
          : null;
      final now = DateTime.now();

      int newStreak = (data['dailyStreak'] ?? 0).toInt();

      if (lastLogin == null) {
        newStreak = 1;
      } else {
        final dayDiff = now.difference(lastLogin).inDays;
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
        'lastLoginDate': FieldValue.serverTimestamp(),
        'dailyStreak': newStreak,
        'coins': FieldValue.increment(streakBonus),
        'totalEarned': FieldValue.increment(streakBonus),
        'xp': FieldValue.increment(streakBonus ~/ 2),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': userId,
        'type': 'dailyLogin',
        'coins': streakBonus,
        'isCredit': true,
        'description': 'Day $newStreak daily login bonus',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    });
  }

  Future<String?> uploadProfilePicture(String userId, File file) async {
    final ref = _storage.ref('profile_pics/$userId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _firestore
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList());
  }

  Future<void> updateFCMToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }
}

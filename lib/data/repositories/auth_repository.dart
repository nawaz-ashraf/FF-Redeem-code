// lib/data/repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _auth = FirebaseService.auth;
  final _firestore = FirebaseService.firestore;

  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? const Uuid().v4();
      }
    } catch (_) {}
    return const Uuid().v4();
  }

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String ffUid,
    String? referralCode,
  }) async {
    // Check if FF UID already exists
    final uidQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('ffUid', isEqualTo: ffUid)
        .limit(1)
        .get();

    if (uidQuery.docs.isNotEmpty) {
      throw const DuplicateAccountException(
        message: 'This Free Fire UID is already registered.',
      );
    }

    final deviceId = await _getDeviceId();

    // Check device ID
    final deviceQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (deviceQuery.docs.isNotEmpty) {
      throw const DuplicateAccountException(
        message:
            'An account already exists on this device. One device allows only one account.',
      );
    }

    // Create Firebase Auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = credential.user!.uid;
    final newReferralCode = AppConstants.usersCollection == 'users'
        ? 'FF${userId.substring(0, 6).toUpperCase()}'
        : const Uuid().v4().substring(0, 8).toUpperCase();

    // Verify referral code
    String? referredBy;
    if (referralCode != null && referralCode.isNotEmpty) {
      if (referralCode.toUpperCase() == newReferralCode) {
        throw const ValidationException(
          message: 'You cannot use your own referral code.',
        );
      }

      final refQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .limit(1)
          .get();

      if (refQuery.docs.isNotEmpty) {
        referredBy = refQuery.docs.first.id;
      }
    }

    final user = UserModel(
      id: userId,
      name: name,
      email: email,
      ffUid: ffUid,
      coins: 0,
      referralCode: 'FF${userId.substring(0, 6).toUpperCase()}',
      referredBy: referredBy,
      referralCount: 0,
      totalEarned: 0,
      totalRedeemed: 0,
      dailyStreak: 0,
      xp: 0,
      level: 1,
      registrationDate: DateTime.now(),
      deviceId: deviceId,
      status: 'active',
      isAdmin: false,
    );

    // Save user to Firestore
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set(user.toFirestore());

    // Reward referrer
    if (referredBy != null) {
      await _rewardReferrer(referredBy, userId);
    }

    await FirebaseService.logSignUp();
    return user;
  }

  Future<void> _rewardReferrer(String referrerId, String newUserId) async {
    await _firestore.runTransaction((tx) async {
      final referrerRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(referrerId);
      final referrerDoc = await tx.get(referrerRef);

      if (!referrerDoc.exists) return;

      tx.update(referrerRef, {
        'coins': FieldValue.increment(AppConstants.referralCoins),
        'referralCount': FieldValue.increment(1),
        'totalEarned': FieldValue.increment(AppConstants.referralCoins),
        'xp': FieldValue.increment(AppConstants.referralCoins),
      });

      // Log referral transaction
      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': referrerId,
        'type': 'referral',
        'coins': AppConstants.referralCoins,
        'isCredit': true,
        'description': 'Referral bonus for inviting a new user',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Log referral record
      final refRef =
          _firestore.collection(AppConstants.referralsCollection).doc();
      tx.set(refRef, {
        'referrerId': referrerId,
        'referredUserId': newUserId,
        'coinsRewarded': AppConstants.referralCoins,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = credential.user!.uid;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!doc.exists) {
      throw const AuthException(message: 'Account not found.');
    }

    final user = UserModel.fromFirestore(doc);

    if (user.status == 'banned') {
      await _auth.signOut();
      throw const BannedException(
        message:
            'Your account has been banned. Contact support for assistance.',
      );
    }

    await FirebaseService.logLogin();
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .delete();
    await _auth.currentUser?.delete();
  }
}

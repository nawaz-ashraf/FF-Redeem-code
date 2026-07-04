// lib/data/repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _auth = FirebaseService.auth;
  final _firestore = FirebaseService.firestore;

  /// Retrieve a stable device identifier
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

  /// Register a new user with full device + UID validation per spec
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String freeFireUID,
    String? referralCode,
  }) async {
    // 1. Validate Free Fire UID not already registered
    final uidQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('freeFireUID', isEqualTo: freeFireUID)
        .limit(1)
        .get();

    if (uidQuery.docs.isNotEmpty) {
      throw const DuplicateAccountException(
        message: 'This Free Fire UID is already registered.',
      );
    }

    // 2. Device ID check — one device, one UID, one registration
    final deviceId = await _getDeviceId();
    final deviceQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (deviceQuery.docs.isNotEmpty) {
      throw const DuplicateAccountException(
        message: 'This device already has a registered account.',
      );
    }

    // 3. Check if device is banned
    final bannedDeviceDoc = await _firestore
        .collection(AppConstants.bannedUsersCollection)
        .doc(deviceId)
        .get();

    if (bannedDeviceDoc.exists) {
      throw const BannedException(
        message:
            'This device has been banned. Contact support for assistance.',
      );
    }

    // 4. Create Firebase Auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = credential.user!.uid;
    final newReferralCode = 'FF${userId.substring(0, 6).toUpperCase()}';

    // 5. Validate referral code
    String? referredBy;
    if (referralCode != null && referralCode.isNotEmpty) {
      final normalizedCode = referralCode.toUpperCase();

      // Cannot use own referral code
      if (normalizedCode == newReferralCode) {
        throw const ValidationException(
          message: 'You cannot use your own referral code.',
        );
      }

      final refQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('referralCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();

      if (refQuery.docs.isNotEmpty) {
        referredBy = refQuery.docs.first.id;
      }
    }

    // 6. Create user document
    final now = DateTime.now();
    final user = UserModel(
      uid: userId,
      name: name,
      freeFireUID: freeFireUID,
      deviceId: deviceId,
      email: email,
      coins: 0,
      totalEarnedCoins: 0,
      totalRedeemedCoins: 0,
      totalAdsWatched: 0,
      scratchToday: 0,
      spinToday: 0,
      adsToday: 0,
      referralCode: newReferralCode,
      referredBy: referredBy,
      referralCount: 0,
      withdrawalCount: 0,
      accountStatus: 'active',
      isBanned: false,
      isAdmin: false,
      dailyStreak: 0,
      xp: 0,
      level: 1,
      createdAt: now,
    );

    // 7. Save to Firestore
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set(user.toFirestore());

    // 8. Reward referrer if valid
    if (referredBy != null) {
      await _rewardReferrer(referredBy, userId);
    }

    await FirebaseService.logSignUp();
    return user;
  }

  /// Award referral bonus to the inviter using a Firestore transaction
  Future<void> _rewardReferrer(String referrerId, String newUserId) async {
    await _firestore.runTransaction((tx) async {
      final referrerRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(referrerId);
      final referrerDoc = await tx.get(referrerRef);

      if (!referrerDoc.exists) return;
      final currentCoins = (referrerDoc.data()!['coins'] ?? 0).toInt();

      tx.update(referrerRef, {
        'coins': FieldValue.increment(AppConstants.referralCoins),
        'referralCount': FieldValue.increment(1),
        'totalEarnedCoins': FieldValue.increment(AppConstants.referralCoins),
        'xp': FieldValue.increment(AppConstants.referralCoins),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log transaction with balance tracking
      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': referrerId,
        'type': 'referral',
        'rewardAmount': AppConstants.referralCoins,
        'balanceBefore': currentCoins,
        'balanceAfter': currentCoins + AppConstants.referralCoins,
        'referenceId': newUserId,
        'description': 'Referral bonus for inviting a new user',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Save referral record
      final refRef =
          _firestore.collection(AppConstants.referralsCollection).doc();
      tx.set(refRef, {
        'inviterId': referrerId,
        'newUserId': newUserId,
        'reward': AppConstants.referralCoins,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Login with email/password
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

    // Check ban status
    if (user.isBanned || user.accountStatus == 'banned') {
      await _auth.signOut();
      throw const BannedException(
        message:
            'Your account has been banned. Contact support for assistance.',
      );
    }

    // Update last login
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseService.logLogin();
    return user;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the currently logged-in user's model
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

  /// Stream of Firebase Auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Delete user account and Firestore document
  Future<void> deleteAccount(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .delete();
    await _auth.currentUser?.delete();
  }
}

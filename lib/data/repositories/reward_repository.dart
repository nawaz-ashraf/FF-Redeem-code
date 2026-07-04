// lib/data/repositories/reward_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/app_utils.dart';
import '../models/transaction_model.dart';
import 'user_repository.dart';

class RewardRepository {
  final _firestore = FirebaseService.firestore;
  final _userRepo = UserRepository();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── AD REWARDS ──────────────────────────────────────────

  /// Claim reward for watching ad. Validates both local and server-side limits.
  Future<int> claimAdReward(String userId) async {
    final prefs = await _prefs;
    final today = AppUtils.formatDate(DateTime.now());
    final lastDate = prefs.getString(AppConstants.lastAdRewardDateKey);
    int adCount = prefs.getInt(AppConstants.dailyAdCountKey) ?? 0;

    // Reset local counter on new day
    if (lastDate != today) {
      adCount = 0;
      await prefs.setString(AppConstants.lastAdRewardDateKey, today);
    }

    if (adCount >= AppConstants.maxDailyAds) {
      throw const LimitExceededException(
        message: 'You have reached the daily limit of 30 ads.',
      );
    }

    // Server-side duplicate prevention via Firestore
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final existingRewards = await _firestore
        .collection(AppConstants.adRewardsCollection)
        .where('userId', isEqualTo: userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    if (existingRewards.docs.length >= AppConstants.maxDailyAds) {
      throw const LimitExceededException(
        message: 'Daily ad reward limit reached.',
      );
    }

    // Add coins with balance tracking
    await _userRepo.addCoins(
      userId: userId,
      coins: AppConstants.adRewardCoins,
      type: TransactionType.rewardedAd,
      description: 'Rewarded ad #${adCount + 1}',
    );

    // Log ad reward event
    await _firestore.collection(AppConstants.adRewardsCollection).add({
      'userId': userId,
      'coins': AppConstants.adRewardCoins,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update daily counter on user document
    await _userRepo.incrementAdsToday(userId);

    adCount++;
    await prefs.setInt(AppConstants.dailyAdCountKey, adCount);

    await FirebaseService.logEvent('ad_reward_claimed', parameters: {
      'coins': AppConstants.adRewardCoins,
      'ad_count': adCount,
    });

    return AppConstants.adRewardCoins;
  }

  // ── SCRATCH CARD ─────────────────────────────────────────

  /// Claim scratch card reward with limit validation
  Future<int> claimScratchReward(String userId) async {
    final prefs = await _prefs;
    final today = AppUtils.formatDate(DateTime.now());
    final lastDate = prefs.getString('last_scratch_date');
    int count = prefs.getInt(AppConstants.dailyScratchCountKey) ?? 0;

    if (lastDate != today) {
      count = 0;
      await prefs.setString('last_scratch_date', today);
    }

    if (count >= AppConstants.maxDailyScratch) {
      throw const LimitExceededException(
        message:
            'You have used all scratch cards for today. Come back tomorrow!',
      );
    }

    // Pseudo-random reward from scratch rewards pool
    final rewards = AppConstants.scratchRewards;
    final reward =
        rewards[DateTime.now().millisecondsSinceEpoch % rewards.length];

    await _userRepo.addCoins(
      userId: userId,
      coins: reward,
      type: TransactionType.scratch,
      description: 'Scratch card reward',
    );

    await _firestore.collection(AppConstants.scratchHistoryCollection).add({
      'userId': userId,
      'coins': reward,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update daily counter on user document
    await _userRepo.incrementScratchToday(userId);

    count++;
    await prefs.setInt(AppConstants.dailyScratchCountKey, count);

    await FirebaseService.logEvent('scratch_reward_claimed',
        parameters: {'coins': reward});

    return reward;
  }

  // ── SPIN WHEEL ───────────────────────────────────────────

  /// Claim spin wheel reward with limit validation
  Future<int> claimSpinReward(String userId) async {
    final prefs = await _prefs;
    final today = AppUtils.formatDate(DateTime.now());
    final lastDate = prefs.getString('last_spin_date');
    int count = prefs.getInt(AppConstants.dailySpinCountKey) ?? 0;

    if (lastDate != today) {
      count = 0;
      await prefs.setString('last_spin_date', today);
    }

    if (count >= AppConstants.maxDailySpin) {
      throw const LimitExceededException(
        message: 'You have used all spins for today. Come back tomorrow!',
      );
    }

    final rewards = AppConstants.spinRewards;
    final reward =
        rewards[DateTime.now().microsecondsSinceEpoch % rewards.length];

    await _userRepo.addCoins(
      userId: userId,
      coins: reward,
      type: TransactionType.spin,
      description: 'Spin wheel reward',
    );

    await _firestore.collection(AppConstants.spinHistoryCollection).add({
      'userId': userId,
      'coins': reward,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update daily counter on user document
    await _userRepo.incrementSpinToday(userId);

    count++;
    await prefs.setInt(AppConstants.dailySpinCountKey, count);

    await FirebaseService.logEvent('spin_reward_claimed',
        parameters: {'coins': reward});

    return reward;
  }

  // ── DAILY LOGIN ──────────────────────────────────────────

  /// Claim daily login bonus with streak tracking
  Future<Map<String, dynamic>> claimDailyLogin(String userId) async {
    final prefs = await _prefs;
    final today = AppUtils.formatDate(DateTime.now());
    final lastDate = prefs.getString(AppConstants.lastLoginDateKey);

    if (lastDate == today) {
      throw const LimitExceededException(
        message: 'You have already claimed your daily login bonus today.',
      );
    }

    await _userRepo.updateDailyLogin(userId);
    await prefs.setString(AppConstants.lastLoginDateKey, today);

    final user = await _userRepo.getUser(userId);
    final streak = user?.dailyStreak ?? 1;
    final bonus =
        AppConstants.streakBonuses[streak] ?? AppConstants.dailyLoginCoins;

    await FirebaseService.logEvent('daily_login_claimed', parameters: {
      'streak': streak,
      'coins': bonus,
    });

    return {'streak': streak, 'coins': bonus};
  }

  // ── REFERRAL CODE VALIDATION ─────────────────────────────

  /// Validate and apply a referral code entered by a user
  Future<void> applyReferralCode({
    required String userId,
    required String referralCode,
  }) async {
    final normalizedCode = referralCode.toUpperCase();

    // 1. Cannot use own code
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      throw const AuthException(message: 'User not found.');
    }

    final userData = userDoc.data()!;
    if (userData['referralCode'] == normalizedCode) {
      throw const ValidationException(
        message: 'You cannot use your own referral code.',
      );
    }

    // 2. Check if user already used a referral code
    if (userData['referredBy'] != null) {
      throw const ValidationException(
        message: 'You have already used a referral code.',
      );
    }

    // 3. Find the inviter by referral code
    final refQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('referralCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (refQuery.docs.isEmpty) {
      throw const ValidationException(
        message: 'Invalid referral code.',
      );
    }

    final inviterId = refQuery.docs.first.id;
    final inviterCoins = (refQuery.docs.first.data()['coins'] ?? 0).toInt();

    // 4. Apply reward to inviter in a transaction
    await _firestore.runTransaction((tx) async {
      final inviterRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(inviterId);

      tx.update(inviterRef, {
        'coins': FieldValue.increment(AppConstants.referralCoins),
        'referralCount': FieldValue.increment(1),
        'totalEarnedCoins': FieldValue.increment(AppConstants.referralCoins),
        'xp': FieldValue.increment(AppConstants.referralCoins),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark the new user as referred
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      tx.update(userRef, {
        'referredBy': inviterId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Transaction log for inviter
      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': inviterId,
        'type': 'referral',
        'rewardAmount': AppConstants.referralCoins,
        'balanceBefore': inviterCoins,
        'balanceAfter': inviterCoins + AppConstants.referralCoins,
        'referenceId': userId,
        'description': 'Referral bonus for inviting a new user',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Referral record
      final refRef =
          _firestore.collection(AppConstants.referralsCollection).doc();
      tx.set(refRef, {
        'inviterId': inviterId,
        'newUserId': userId,
        'reward': AppConstants.referralCoins,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── LIMITS CHECK ─────────────────────────────────────────

  /// Get remaining daily limits for all reward types
  Future<Map<String, int>> getDailyLimits(String userId) async {
    final prefs = await _prefs;
    final today = AppUtils.formatDate(DateTime.now());

    final lastAdDate = prefs.getString(AppConstants.lastAdRewardDateKey);
    final lastScratchDate = prefs.getString('last_scratch_date');
    final lastSpinDate = prefs.getString('last_spin_date');
    final lastLoginDate = prefs.getString(AppConstants.lastLoginDateKey);

    return {
      'adsRemaining': lastAdDate == today
          ? AppConstants.maxDailyAds -
              (prefs.getInt(AppConstants.dailyAdCountKey) ?? 0)
          : AppConstants.maxDailyAds,
      'scratchRemaining': lastScratchDate == today
          ? AppConstants.maxDailyScratch -
              (prefs.getInt(AppConstants.dailyScratchCountKey) ?? 0)
          : AppConstants.maxDailyScratch,
      'spinRemaining': lastSpinDate == today
          ? AppConstants.maxDailySpin -
              (prefs.getInt(AppConstants.dailySpinCountKey) ?? 0)
          : AppConstants.maxDailySpin,
      'loginClaimed': lastLoginDate == today ? 1 : 0,
    };
  }
}

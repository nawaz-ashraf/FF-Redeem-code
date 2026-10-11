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
  final FirebaseFirestore _firestore;
  final UserRepository _userRepo;

  RewardRepository({
    FirebaseFirestore? firestore,
    UserRepository? userRepo,
  })  : _firestore = firestore ?? FirebaseService.firestore,
        _userRepo = userRepo ?? UserRepository(firestore: firestore);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── AD REWARDS ──────────────────────────────────────────

  /// Claim reward for watching ad. Validates both local and server-side limits.
  Future<int> claimAdReward(String userId, String rewardId) async {
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

    // Add coins with balance tracking and atomic duplicate prevention
    await _userRepo.addCoins(
      userId: userId,
      coins: AppConstants.adRewardCoins,
      type: TransactionType.rewardedAd,
      description: 'Rewarded ad #${adCount + 1}',
      transactionId: rewardId,
    );

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
  Future<int> claimScratchReward(String userId, String rewardId) async {
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
    const rewards = AppConstants.scratchRewards;
    final reward =
        rewards[DateTime.now().millisecondsSinceEpoch % rewards.length];

    await _userRepo.addCoins(
      userId: userId,
      coins: reward,
      type: TransactionType.scratch,
      description: 'Scratch card reward',
      transactionId: rewardId,
    );

    count++;
    await prefs.setInt(AppConstants.dailyScratchCountKey, count);

    await FirebaseService.logEvent('scratch_reward_claimed',
        parameters: {'coins': reward});

    return reward;
  }

  // ── SPIN WHEEL ───────────────────────────────────────────

  /// Claim spin wheel reward with limit validation
  Future<int> claimSpinReward(String userId, String rewardId) async {
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

    const rewards = AppConstants.spinRewards;
    final reward =
        rewards[DateTime.now().microsecondsSinceEpoch % rewards.length];

    await _userRepo.addCoins(
      userId: userId,
      coins: reward,
      type: TransactionType.spin,
      description: 'Spin wheel reward',
      transactionId: rewardId,
    );

    count++;
    await prefs.setInt(AppConstants.dailySpinCountKey, count);

    await FirebaseService.logEvent('spin_reward_claimed',
        parameters: {'coins': reward});

    return reward;
  }

  // ── DAILY LOGIN ──────────────────────────────────────────

  /// Claim daily login bonus with streak tracking
  Future<Map<String, dynamic>> claimDailyLogin(String userId) async {
    final todayKey = AppUtils.getRewardDayKey();
    final prefs = await _prefs;
    final lastDate = prefs.getString(AppConstants.lastLoginDateKey);

    if (lastDate == todayKey) {
      throw const LimitExceededException(
        message: 'You have already claimed your daily reward. Come back tomorrow!',
      );
    }

    await _userRepo.updateDailyLogin(userId);
    await prefs.setString(AppConstants.lastLoginDateKey, todayKey);

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
    final todayKey = AppUtils.getRewardDayKey();

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
    if (inviterId == userId) {
      throw const ValidationException(
        message: 'You cannot use your own referral code.',
      );
    }

    // 4. Pre-check daily limit for inviter
    final dailyRefRef = _firestore
        .collection(AppConstants.dailyReferralsCollection)
        .doc('${inviterId}_$todayKey');
    final dailyRefDocPre = await dailyRefRef.get();
    if (dailyRefDocPre.exists &&
        ((dailyRefDocPre.data()?['count'] ?? 0) as num).toInt() >=
            AppConstants.maxDailyReferrals) {
      throw const LimitExceededException(
        message: 'Daily referral limit reached (5/5). Try again tomorrow!',
      );
    }

    // 5. Apply reward to inviter atomically in a transaction
    await _firestore.runTransaction((tx) async {
      final inviterRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(inviterId);
      final inviterDoc = await tx.get(inviterRef);
      if (!inviterDoc.exists) {
        throw const ValidationException(message: 'Referrer account not found.');
      }

      // Check authoritative daily referral count inside transaction
      final dailyRefDoc = await tx.get(dailyRefRef);
      final todayCount = dailyRefDoc.exists
          ? ((dailyRefDoc.data()?['count'] ?? 0) as num).toInt()
          : 0;

      if (todayCount >= AppConstants.maxDailyReferrals) {
        throw const LimitExceededException(
          message: 'Daily referral limit reached (5/5). Try again tomorrow!',
        );
      }

      // Check that this new user was not already rewarded
      final refRef = _firestore
          .collection(AppConstants.referralsCollection)
          .doc(userId);
      final refDoc = await tx.get(refRef);
      if (refDoc.exists) {
        throw const ValidationException(
          message: 'You have already used a referral code.',
        );
      }

      final inviterCoins = ((inviterDoc.data()!['coins'] ?? 0) as num).toInt();

      // Update inviter document
      tx.update(inviterRef, {
        'coins': FieldValue.increment(AppConstants.referralCoins),
        'referralCount': FieldValue.increment(1),
        'dailyReferralDate': todayKey,
        'dailyReferralCount': todayCount + 1,
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
        'description':
            'Referral bonus for inviting a new user (${todayCount + 1}/${AppConstants.maxDailyReferrals} today)',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Daily referral tracking record
      tx.set(
        dailyRefRef,
        {
          'referrerId': inviterId,
          'dateKey': todayKey,
          'count': todayCount + 1,
          'referrals': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Dedicated idempotent referral record keyed by userId
      tx.set(refRef, {
        'inviterId': inviterId,
        'referrerId': inviterId,
        'newUserId': userId,
        'reward': AppConstants.referralCoins,
        'dateKey': todayKey,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get authoritative count of successful referrals for today
  Future<int> getReferralsToday(String userId) async {
    final todayKey = AppUtils.getRewardDayKey();
    try {
      final doc = await _firestore
          .collection(AppConstants.dailyReferralsCollection)
          .doc('${userId}_$todayKey')
          .get();
      if (doc.exists) {
        return ((doc.data()?['count'] ?? 0) as num).toInt();
      }
    } catch (_) {}
    return 0;
  }

  // ── LIMITS CHECK ─────────────────────────────────────────

  /// Get remaining daily limits for all reward types
  Future<Map<String, int>> getDailyLimits(String userId) async {
    final prefs = await _prefs;
    final today = AppUtils.formatDate(DateTime.now());
    final todayRewardKey = AppUtils.getRewardDayKey();

    final lastAdDate = prefs.getString(AppConstants.lastAdRewardDateKey);
    final lastScratchDate = prefs.getString('last_scratch_date');
    final lastSpinDate = prefs.getString('last_spin_date');
    final lastLoginDate = prefs.getString(AppConstants.lastLoginDateKey);

    int loginClaimed = 0;
    if (lastLoginDate == todayRewardKey) {
      loginClaimed = 1;
    } else {
      // Authoritative check against Firestore to survive logout/login, reinstall, cache clear
      try {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final dailyLoginRaw = data['dailyLoginDate'];
          if (dailyLoginRaw is Timestamp) {
            final loginDate = dailyLoginRaw.toDate();
            if (AppUtils.isSameRewardDay(DateTime.now(), loginDate)) {
              loginClaimed = 1;
              await prefs.setString(AppConstants.lastLoginDateKey, todayRewardKey);
            }
          }
        }
      } catch (_) {
        loginClaimed = lastLoginDate == todayRewardKey ? 1 : 0;
      }
    }

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
      'loginClaimed': loginClaimed,
    };
  }
}

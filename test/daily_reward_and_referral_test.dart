import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ff_redeem_code/core/constants/app_constants.dart';
import 'package:ff_redeem_code/core/errors/app_exception.dart';
import 'package:ff_redeem_code/core/utils/app_utils.dart';
import 'package:ff_redeem_code/data/repositories/user_repository.dart';
import 'package:ff_redeem_code/data/repositories/reward_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore fakeFirestore;
  late UserRepository userRepo;
  late RewardRepository rewardRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirebaseFirestore();
    userRepo = UserRepository(firestore: fakeFirestore);
    rewardRepo = RewardRepository(
      firestore: fakeFirestore,
      userRepo: userRepo,
    );
  });

  group('Daily Reward Tests', () {
    test('Claim once: 5 coins granted, dailyLoginDate set, transaction created', () async {
      const userId = 'daily_user_1';
      final userRef = fakeFirestore.collection(AppConstants.usersCollection).doc(userId);
      await userRef.set({
        'coins': 100,
        'dailyStreak': 0,
        'isBanned': false,
        'accountStatus': 'active',
      });

      // Claim daily login through userRepo
      await userRepo.updateDailyLogin(userId);

      final userDoc = await userRef.get();
      expect(userDoc.data()?['coins'], 105);
      expect(userDoc.data()?['dailyStreak'], 1);
      expect(userDoc.data()?['dailyLoginDate'], isNotNull);

      final todayKey = AppUtils.getRewardDayKey();
      final claimDoc = await fakeFirestore
          .collection(AppConstants.dailyRewardsCollection)
          .doc('${userId}_$todayKey')
          .get();
      expect(claimDoc.exists, true);
      expect(claimDoc.data()?['coins'], 5);

      final txSnap = await fakeFirestore
          .collection(AppConstants.transactionsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      expect(txSnap.docs.length, 1);
      expect(txSnap.docs.first.data()['type'], 'dailyLogin');
      expect(txSnap.docs.first.data()['rewardAmount'], 5);
    });

    test('Claim again on same calendar day: throws LimitExceededException', () async {
      const userId = 'daily_user_2';
      final userRef = fakeFirestore.collection(AppConstants.usersCollection).doc(userId);

      await userRef.set({
        'coins': 100,
        'dailyStreak': 0,
        'isBanned': false,
        'accountStatus': 'active',
      });

      // First claim succeeds
      await userRepo.updateDailyLogin(userId);

      // Second claim on the exact same day must throw LimitExceededException
      expect(
        () => userRepo.updateDailyLogin(userId),
        throwsA(isA<LimitExceededException>().having(
          (e) => e.message,
          'message',
          contains('You have already claimed your daily reward. Come back tomorrow!'),
        )),
      );

      // Balance must remain 105, not 110
      final userDoc = await userRef.get();
      expect(userDoc.data()?['coins'], 105);
    });

    test('Log out and back in: eligibility persists and is not reset', () async {
      const userId = 'daily_user_3';
      final todayKey = AppUtils.getRewardDayKey();
      
      // Simulate user already claimed today in Firestore
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 105,
        'dailyStreak': 1,
        'dailyLoginDate': Timestamp.now(),
        'isBanned': false,
        'accountStatus': 'active',
      });
      await fakeFirestore.collection(AppConstants.dailyRewardsCollection).doc('${userId}_$todayKey').set({
        'userId': userId,
        'dateKey': todayKey,
        'coins': 5,
      });

      // Clear local SharedPreferences (simulating app data clear / reinstall / logout)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      expect(prefs.getString(AppConstants.lastLoginDateKey), isNull);

      // getDailyLimits queries Firestore directly, detecting that reward is already claimed
      final limits = await rewardRepo.getDailyLimits(userId);
      expect(limits['loginClaimed'], 1);

      // Attempting to claim again is rejected
      expect(
        () => userRepo.updateDailyLogin(userId),
        throwsA(isA<LimitExceededException>().having(
          (e) => e.message,
          'message',
          contains('You have already claimed your daily reward. Come back tomorrow!'),
        )),
      );
    });

    test('Claim on next day: streak advances and coins granted', () async {
      const userId = 'daily_user_4';
      final userRef = fakeFirestore.collection(AppConstants.usersCollection).doc(userId);
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));

      await userRef.set({
        'coins': 105,
        'dailyStreak': 1,
        'dailyLoginDate': Timestamp.fromDate(yesterday),
        'isBanned': false,
        'accountStatus': 'active',
      });

      await userRepo.updateDailyLogin(userId);

      final userDoc = await userRef.get();
      expect(userDoc.data()?['coins'], 111); // 105 + 6 (Day 2 streak bonus from AppConstants.streakBonuses)
      expect(userDoc.data()?['dailyStreak'], 2);
    });

    test('Broken streak (dayDiff > 1): streak resets to 1', () async {
      const userId = 'daily_user_5';
      final userRef = fakeFirestore.collection(AppConstants.usersCollection).doc(userId);
      final threeDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 3));

      await userRef.set({
        'coins': 200,
        'dailyStreak': 5,
        'dailyLoginDate': Timestamp.fromDate(threeDaysAgo),
        'isBanned': false,
        'accountStatus': 'active',
      });

      await userRepo.updateDailyLogin(userId);

      final userDoc = await userRef.get();
      expect(userDoc.data()?['coins'], 205); // 200 + 5 (Day 1 bonus)
      expect(userDoc.data()?['dailyStreak'], 1);
    });
  });

  group('Referral Limit Tests', () {
    test('One successful referral grants exactly 10 coins and records transaction', () async {
      const referrerId = 'referrer_single';
      const newUserId = 'new_user_single';
      final referrerRef = fakeFirestore.collection(AppConstants.usersCollection).doc(referrerId);
      await referrerRef.set({
        'coins': 0,
        'totalEarnedCoins': 0,
        'referralCount': 0,
        'dailyReferralCount': 0,
        'referralCode': 'REFSINGLE',
        'accountStatus': 'active',
        'isBanned': false,
      });

      await fakeFirestore.collection(AppConstants.usersCollection).doc(newUserId).set({
        'coins': 0,
        'referralCode': 'NEWSINGLE',
        'accountStatus': 'active',
        'isBanned': false,
      });

      // Apply referral code
      await rewardRepo.applyReferralCode(
        userId: newUserId,
        referralCode: 'REFSINGLE',
      );

      // Verify referrer receives exactly 10 coins
      final referrerDoc = await referrerRef.get();
      expect(referrerDoc.data()?['coins'], 10);
      expect(referrerDoc.data()?['totalEarnedCoins'], 10);
      expect(referrerDoc.data()?['referralCount'], 1);
      expect(referrerDoc.data()?['dailyReferralCount'], 1);

      // Verify referral record
      final refRecord = await fakeFirestore
          .collection(AppConstants.referralsCollection)
          .doc(newUserId)
          .get();
      expect(refRecord.exists, isTrue);
      expect(refRecord.data()?['reward'], 10);
      expect(refRecord.data()?['inviterId'], referrerId);

      // Verify transaction history entry
      final txQuery = await fakeFirestore
          .collection(AppConstants.transactionsCollection)
          .where('userId', isEqualTo: referrerId)
          .where('type', isEqualTo: 'referral')
          .get();
      expect(txQuery.docs.length, 1);
      final txData = txQuery.docs.first.data();
      expect(txData['rewardAmount'], 10);
      expect(txData['balanceBefore'], 0);
      expect(txData['balanceAfter'], 10);
    });

    test('Five successful referrals grant a total of 50 coins, 6th referral is rejected', () async {
      const referrerId = 'referrer_1';
      final referrerRef = fakeFirestore.collection(AppConstants.usersCollection).doc(referrerId);
      await referrerRef.set({
        'coins': 0,
        'totalEarnedCoins': 0,
        'referralCount': 0,
        'dailyReferralCount': 0,
        'referralCode': 'FFREF1',
        'accountStatus': 'active',
        'isBanned': false,
      });

      // Create 6 new users
      for (int i = 1; i <= 6; i++) {
        await fakeFirestore.collection(AppConstants.usersCollection).doc('new_user_$i').set({
          'coins': 0,
          'referralCode': 'NEW$i',
          'accountStatus': 'active',
          'isBanned': false,
        });
      }

      // Apply referrals 1 through 5
      for (int i = 1; i <= 5; i++) {
        await rewardRepo.applyReferralCode(
          userId: 'new_user_$i',
          referralCode: 'FFREF1',
        );
      }

      var referrerDoc = await referrerRef.get();
      expect(referrerDoc.data()?['coins'], 50); // 5 * 10 coins = exactly 50 coins
      expect(referrerDoc.data()?['totalEarnedCoins'], 50);
      expect(referrerDoc.data()?['referralCount'], 5);
      expect(referrerDoc.data()?['dailyReferralCount'], 5);

      final todayKey = AppUtils.getRewardDayKey();
      var trackerDoc = await fakeFirestore
          .collection(AppConstants.dailyReferralsCollection)
          .doc('${referrerId}_$todayKey')
          .get();
      expect(trackerDoc.data()?['count'], 5);

      // 6th referral on same day must be rejected with exact required message
      expect(
        () => rewardRepo.applyReferralCode(
          userId: 'new_user_6',
          referralCode: 'FFREF1',
        ),
        throwsA(isA<LimitExceededException>().having(
          (e) => e.message,
          'message',
          contains('Daily referral limit reached (5/5). Try again tomorrow!'),
        )),
      );

      // Referrer coins and count must remain 50 and 5
      referrerDoc = await referrerRef.get();
      expect(referrerDoc.data()?['coins'], 50);
      expect(referrerDoc.data()?['referralCount'], 5);

      // Querying authoritative referrals today returns 5
      final todayCount = await rewardRepo.getReferralsToday(referrerId);
      expect(todayCount, 5);
    });

    test('Duplicate referral for same referred user is rejected', () async {
      const referrerId = 'referrer_2';
      const newUserId = 'new_user_dup';

      await fakeFirestore.collection(AppConstants.usersCollection).doc(referrerId).set({
        'coins': 0,
        'referralCode': 'FFREF2',
      });
      await fakeFirestore.collection(AppConstants.usersCollection).doc(newUserId).set({
        'coins': 0,
        'referralCode': 'FFNEWDUP',
      });

      // First application succeeds
      await rewardRepo.applyReferralCode(
        userId: newUserId,
        referralCode: 'FFREF2',
      );

      // Second application for same user must be rejected
      expect(
        () => rewardRepo.applyReferralCode(
          userId: newUserId,
          referralCode: 'FFREF2',
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('You have already used a referral code.'),
        )),
      );

      final referrerDoc = await fakeFirestore.collection(AppConstants.usersCollection).doc(referrerId).get();
      expect(referrerDoc.data()?['coins'], 10);
      expect(referrerDoc.data()?['referralCount'], 1);
    });

    test('Self referral is prevented', () async {
      const userId = 'user_self';
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 0,
        'referralCode': 'FFSELF',
      });

      expect(
        () => rewardRepo.applyReferralCode(
          userId: userId,
          referralCode: 'FFSELF',
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('You cannot use your own referral code.'),
        )),
      );
    });

    test('Invalid referral code is rejected', () async {
      const userId = 'user_invalid';
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 0,
        'referralCode': 'FFVALID',
      });

      expect(
        () => rewardRepo.applyReferralCode(
          userId: userId,
          referralCode: 'NONEXISTENT',
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Invalid referral code.'),
        )),
      );
    });
  });
}

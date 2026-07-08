import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ff_redeem_code/core/constants/app_constants.dart';
import 'package:ff_redeem_code/core/errors/app_exception.dart';
import 'package:ff_redeem_code/data/models/withdrawal_model.dart';
import 'package:ff_redeem_code/data/repositories/withdrawal_repository.dart';
import 'package:ff_redeem_code/data/repositories/user_repository.dart';
import 'package:ff_redeem_code/data/repositories/notification_repository.dart';
import 'package:ff_redeem_code/data/models/user_model.dart';
import 'package:ff_redeem_code/data/models/notification_model.dart';
import 'package:ff_redeem_code/data/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockUserRepository mockUserRepo;
  late MockNotificationRepository mockNotificationRepo;
  late WithdrawalRepository withdrawalRepo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockUserRepo = MockUserRepository();
    mockNotificationRepo = MockNotificationRepository();

    withdrawalRepo = WithdrawalRepository(
      firestore: fakeFirestore,
      userRepo: mockUserRepo,
      notificationRepo: mockNotificationRepo,
    );
  });

  group('WithdrawalRepository Tests', () {
    test('submitWithdrawal creates a new request when no pending exists', () async {
      final userId = 'user_123';
      final ffUid = '987654321';
      final package = '100 Diamonds';
      final cost = 1000;
      final value = '100';

      final withdrawal = await withdrawalRepo.submitWithdrawal(
        userId: userId,
        freeFireUID: ffUid,
        package: package,
        coinCost: cost,
        packageValue: value,
      );

      expect(withdrawal.userId, userId);
      expect(withdrawal.freeFireUID, ffUid);
      expect(withdrawal.status, WithdrawalStatus.pending);

      final snapshot = await fakeFirestore
          .collection(AppConstants.withdrawalsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      expect(snapshot.docs.length, 1);
    });

    test('submitWithdrawal throws ValidationException if pending exists', () async {
      final userId = 'user_123';

      // Insert an existing pending request
      await fakeFirestore.collection(AppConstants.withdrawalsCollection).add({
        'userId': userId,
        'freeFireUID': '111',
        'package': 'Test',
        'coinCost': 100,
        'packageValue': '10',
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      expect(
        () => withdrawalRepo.submitWithdrawal(
          userId: userId,
          freeFireUID: '222',
          package: 'Another',
          coinCost: 200,
          packageValue: '20',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('approveWithdrawal deducts coins, assigns auto code, and updates status', () async {
      final userId = 'user_123';
      
      // Setup user with 5000 coins
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 5000,
      });

      // Setup pending withdrawal
      final withdrawalRef = await fakeFirestore.collection(AppConstants.withdrawalsCollection).add({
        'userId': userId,
        'freeFireUID': '111',
        'package': '100 Diamonds',
        'coinCost': 1000,
        'packageValue': '100',
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      // Setup available redeem code
      final codeRef = await fakeFirestore.collection(AppConstants.redeemCodesCollection).add({
        'code': 'XYZ-123',
        'package': '100 Diamonds',
        'status': 'available',
      });

      await withdrawalRepo.approveWithdrawal(
        withdrawalId: withdrawalRef.id,
        adminRemark: 'Enjoy!',
      );

      // Verify user coins deducted
      final userDoc = await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).get();
      expect(userDoc.data()?['coins'], 4000);

      // Verify withdrawal updated
      final updatedWithdrawal = await withdrawalRef.get();
      expect(updatedWithdrawal.data()?['status'], 'approved');
      expect(updatedWithdrawal.data()?['assignedRedeemCode'], 'XYZ-123');

      // Verify code updated
      final updatedCode = await codeRef.get();
      expect(updatedCode.data()?['status'], 'assigned');
    });

    test('rejectWithdrawal updates status without deducting coins', () async {
      final userId = 'user_123';

      final withdrawalRef = await fakeFirestore.collection(AppConstants.withdrawalsCollection).add({
        'userId': userId,
        'freeFireUID': '111',
        'package': '100 Diamonds',
        'coinCost': 1000,
        'packageValue': '100',
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      await withdrawalRepo.rejectWithdrawal(
        withdrawalId: withdrawalRef.id,
        adminRemark: 'Invalid UID',
      );

      final updatedWithdrawal = await withdrawalRef.get();
      expect(updatedWithdrawal.data()?['status'], 'rejected');
      expect(updatedWithdrawal.data()?['adminRemark'], 'Invalid UID');
    });
  });
}

class MockUserRepository implements UserRepository {
  @override
  Future<UserModel?> getUser(String uid) async {
    return UserModel(
      uid: uid,
      name: 'Test User',
      uuid: 'uuid-123',
      deviceId: 'dev-123',
      email: 'test@test.com',
      coins: 5000,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      dailyStreak: 0,
      totalEarnedCoins: 5000,
      totalRedeemedCoins: 0,
      adsToday: 0,
      scratchToday: 0,
      spinToday: 0,
      totalAdsWatched: 0,
      referralCode: 'REF123',
      referralCount: 0,
      withdrawalCount: 0,
      accountStatus: 'active',
      isBanned: false,
      isAdmin: false,
    );
  }

  @override
  Future<void> createUser(UserModel user) async {}

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteUser(String uid) async {}
  
  @override
  Future<void> updateCoins(String uid, int amount) async {}
  
  @override
  Stream<UserModel?> watchUser(String uid) => const Stream.empty();

  @override
  Future<void> addCoins({required String userId, required int coins, required TransactionType type, required String description, String? transactionId}) async {}

  @override
  Future<bool> deductCoins({required String userId, required int coins, String? description, String? referenceId, TransactionType type = TransactionType.redeemApproved}) async => true;

  @override
  Future<List<TransactionModel>> getTransactions(String userId, {String? typeFilter, DocumentSnapshot? lastDoc, int limit = 20}) async => [];

  @override
  Future<void> updateDailyLogin(String userId) async {}

  @override
  Future<void> updateFCMToken(String userId, String token) async {}

  @override
  Future<String?> uploadProfilePicture(String userId, File file) async => null;

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId, {String? typeFilter, int limit = 50}) => const Stream.empty();
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<void> createNotification({
    required String title,
    required String message,
    String? image,
    required NotificationType type,
    String? targetUserId,
  }) async {}

  @override
  Future<void> deleteNotification(String notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> sendBroadcast({
    required String title,
    required String message,
    String? image,
    NotificationType type = NotificationType.announcement,
  }) async {}

  @override
  Stream<List<NotificationModel>> watchAllNotifications() => const Stream.empty();

  @override
  Stream<List<NotificationModel>> watchNotifications({String? userId}) => const Stream.empty();

  @override
  Stream<int> watchUnreadCount() => const Stream.empty();
}

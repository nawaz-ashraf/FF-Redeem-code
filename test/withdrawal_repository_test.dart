import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ff_redeem_code/core/constants/app_constants.dart';
import 'package:ff_redeem_code/core/errors/app_exception.dart';
import 'package:ff_redeem_code/data/models/withdrawal_model.dart';
import 'package:ff_redeem_code/data/repositories/withdrawal_repository.dart';
import 'package:ff_redeem_code/data/repositories/notification_repository.dart';
import 'package:ff_redeem_code/data/models/notification_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockNotificationRepository mockNotificationRepo;
  late WithdrawalRepository withdrawalRepo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockNotificationRepo = MockNotificationRepository();

    withdrawalRepo = WithdrawalRepository(
      firestore: fakeFirestore,
      notificationRepo: mockNotificationRepo,
    );
  });

  group('WithdrawalRepository Tests', () {
    test('Case 1: User has 3000 coins, Redeems 2500 -> Balance becomes 500 immediately', () async {
      const userId = 'user_case_1';
      
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 3000,
        'isBanned': false,
      });

      final withdrawal = await withdrawalRepo.submitWithdrawal(
        userId: userId,
        freeFireUID: '111',
        package: '₹100 Voucher',
        coinCost: 2500,
        packageValue: '100',
      );

      final userDoc = await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).get();
      expect(userDoc.data()?['coins'], 500);

      final txSnapshot = await fakeFirestore.collection(AppConstants.transactionsCollection).where('userId', isEqualTo: userId).get();
      expect(txSnapshot.docs.length, 1);
      expect(txSnapshot.docs.first.data()['rewardAmount'], -2500);
      
      expect(withdrawal.status, WithdrawalStatus.pending);
    });

    test('Case 2: Admin approves. Balance remains 500. Redeem code appears.', () async {
      const userId = 'user_case_2';
      
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 500,
      });

      final withdrawalRef = await fakeFirestore.collection(AppConstants.withdrawalsCollection).add({
        'userId': userId,
        'freeFireUID': '111',
        'package': '₹100 Voucher',
        'coinCost': 2500,
        'packageValue': '100',
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      await fakeFirestore.collection(AppConstants.redeemCodesCollection).add({
        'code': 'XYZ-123',
        'package': '₹100 Voucher',
        'status': 'available',
      });

      await withdrawalRepo.approveWithdrawal(
        withdrawalId: withdrawalRef.id,
      );

      final userDoc = await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).get();
      expect(userDoc.data()?['coins'], 500);

      final updatedWithdrawal = await withdrawalRef.get();
      expect(updatedWithdrawal.data()?['status'], 'approved');
      expect(updatedWithdrawal.data()?['assignedRedeemCode'], 'XYZ-123');
    });

    test('Case 3: Admin rejects. Coins return to 3000. Refund transaction created.', () async {
      const userId = 'user_case_3';
      
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 500,
      });

      final withdrawalRef = await fakeFirestore.collection(AppConstants.withdrawalsCollection).add({
        'userId': userId,
        'freeFireUID': '111',
        'package': '₹100 Voucher',
        'coinCost': 2500,
        'packageValue': '100',
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      await withdrawalRepo.rejectWithdrawal(
        withdrawalId: withdrawalRef.id,
      );

      final userDoc = await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).get();
      expect(userDoc.data()?['coins'], 3000);

      final updatedWithdrawal = await withdrawalRef.get();
      expect(updatedWithdrawal.data()?['status'], 'rejected');

      final txSnapshot = await fakeFirestore.collection(AppConstants.transactionsCollection).where('userId', isEqualTo: userId).get();
      expect(txSnapshot.docs.length, 1);
      expect(txSnapshot.docs.first.data()['rewardAmount'], 2500);
      expect(txSnapshot.docs.first.data()['type'], 'Redeem Refund');
    });

    test('Case 4: User has 2000 coins. Redeem button pressed -> Insufficient coins.', () async {
      const userId = 'user_case_4';
      
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 2000,
        'isBanned': false,
      });

      expect(
        () => withdrawalRepo.submitWithdrawal(
          userId: userId,
          freeFireUID: '111',
          package: '₹100 Voucher',
          coinCost: 2500,
          packageValue: '100',
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('Insufficient coins'))),
      );

      final snapshot = await fakeFirestore.collection(AppConstants.withdrawalsCollection).where('userId', isEqualTo: userId).get();
      expect(snapshot.docs.length, 0);
    });

    test('Case 5: User already has a Pending request -> Fails with duplicate pending', () async {
      const userId = 'user_case_5';
      
      await fakeFirestore.collection(AppConstants.usersCollection).doc(userId).set({
        'coins': 5000,
        'isBanned': false,
      });

      await fakeFirestore.collection(AppConstants.withdrawalsCollection).add({
        'userId': userId,
        'freeFireUID': '111',
        'package': '₹100 Voucher',
        'coinCost': 2500,
        'packageValue': '100',
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      expect(
        () => withdrawalRepo.submitWithdrawal(
          userId: userId,
          freeFireUID: '111',
          package: '₹100 Voucher',
          coinCost: 2500,
          packageValue: '100',
        ),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('under review'))),
      );
    });
  });
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

// lib/data/repositories/withdrawal_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_service.dart';
import '../models/withdrawal_model.dart';
import '../models/redeem_code_model.dart';
import '../models/notification_model.dart';
import 'user_repository.dart';
import 'notification_repository.dart';

class WithdrawalRepository {
  final FirebaseFirestore _firestore;
  final UserRepository _userRepo;
  final NotificationRepository _notificationRepo;

  WithdrawalRepository({
    FirebaseFirestore? firestore,
    UserRepository? userRepo,
    NotificationRepository? notificationRepo,
  })  : _firestore = firestore ?? FirebaseService.firestore,
        _userRepo = userRepo ?? UserRepository(),
        _notificationRepo = notificationRepo ?? NotificationRepository();

  /// Submit a new withdrawal/redeem request
  Future<WithdrawalModel> submitWithdrawal({
    required String userId,
    required String freeFireUID,
    required String package,
    required int coinCost,
    required String packageValue,
  }) async {
    // Validate user exists and has enough coins
    final user = await _userRepo.getUser(userId);
    if (user == null) throw const AuthException(message: 'User not found.');

    if (user.coins < coinCost) {
      throw const ValidationException(
        message: 'Insufficient coins for this redemption.',
      );
    }

    // Check for existing pending request (only 1 allowed at a time)
    final existingPending = await _firestore
        .collection(AppConstants.withdrawalsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingPending.docs.isNotEmpty) {
      throw const ValidationException(
        message:
            'You already have a pending request. Please wait for it to be processed.',
      );
    }

    final docRef =
        _firestore.collection(AppConstants.withdrawalsCollection).doc();

    final withdrawal = WithdrawalModel(
      withdrawalId: docRef.id,
      userId: userId,
      freeFireUID: freeFireUID,
      package: package,
      coinCost: coinCost,
      packageValue: packageValue,
      status: WithdrawalStatus.pending,
      requestedAt: DateTime.now(),
    );

    await docRef.set(withdrawal.toFirestore());

    // Log redeem request transaction
    final currentCoins = user.coins;
    await _firestore.collection(AppConstants.transactionsCollection).add({
      'userId': userId,
      'type': 'redeemRequest',
      'rewardAmount': coinCost,
      'balanceBefore': currentCoins,
      'balanceAfter': currentCoins, // Coins not deducted yet (only on approval)
      'referenceId': docRef.id,
      'description': 'Redemption request for $package - $packageValue',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    await FirebaseService.logEvent('withdrawal_submitted', parameters: {
      'package': package,
      'coins': coinCost,
    });

    return withdrawal;
  }

  /// Stream user's withdrawal history
  Stream<List<WithdrawalModel>> watchUserWithdrawals(String userId) {
    return _firestore
        .collection(AppConstants.withdrawalsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => WithdrawalModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  /// Stream all withdrawals filtered by status (admin use)
  Stream<List<WithdrawalModel>> watchAllWithdrawals({String? status}) {
    return _firestore
        .collection(AppConstants.withdrawalsCollection)
        .snapshots()
        .map((snap) {
          var list = snap.docs.map((d) => WithdrawalModel.fromFirestore(d)).toList();
          if (status != null) {
            list = list.where((w) => w.status.name == status.toLowerCase()).toList();
          }
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  /// Approve a withdrawal: assign redeem code, deduct coins, update statuses
  Future<void> approveWithdrawal({
    required String withdrawalId,
    String? redeemCode,
    String? adminRemark,
  }) async {
    String? finalAssignedCode;
    String targetUserId = '';
    
    await _firestore.runTransaction((tx) async {
      // 1. Read the withdrawal
      final withdrawalRef = _firestore
          .collection(AppConstants.withdrawalsCollection)
          .doc(withdrawalId);
      final withdrawalDoc = await tx.get(withdrawalRef);

      if (!withdrawalDoc.exists) {
        throw const FirestoreException(message: 'Withdrawal not found.');
      }

      final withdrawal = WithdrawalModel.fromFirestore(withdrawalDoc);

      if (withdrawal.status != WithdrawalStatus.pending) {
        throw const ValidationException(
            message: 'This request has already been processed.');
      }

      // 2. Verify user has enough coins
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(withdrawal.userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) {
        throw const FirestoreException(message: 'User not found.');
      }

      final currentCoins = (userDoc.data()!['coins'] ?? 0).toInt();
      if (currentCoins < withdrawal.coinCost) {
        throw const ValidationException(
            message: 'User has insufficient coins.');
      }

      // 3. Find code if not provided
      String? codeToAssign = redeemCode;
      DocumentReference? codeRefToAssign;

      if (codeToAssign == null || codeToAssign.isEmpty) {
        final codeQuery = await _firestore
            .collection(AppConstants.redeemCodesCollection)
            .where('package', isEqualTo: withdrawal.package)
            .where('status', isEqualTo: 'available')
            .limit(1)
            .get();

        if (codeQuery.docs.isEmpty) {
          throw const ValidationException(
              message: 'No available redeem codes for this package.');
        }

        codeToAssign = codeQuery.docs.first.data()['code'];
        codeRefToAssign = codeQuery.docs.first.reference;
      }
      
      finalAssignedCode = codeToAssign;
      targetUserId = withdrawal.userId;

      // 4. Deduct coins from user
      tx.update(userRef, {
        'coins': FieldValue.increment(-withdrawal.coinCost),
        'totalRedeemedCoins': FieldValue.increment(withdrawal.coinCost),
        'withdrawalCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Update withdrawal status
      tx.update(withdrawalRef, {
        'status': 'approved',
        'assignedRedeemCode': codeToAssign,
        'adminRemark': adminRemark,
        'approvedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 6. Log approval transaction
      final txRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      tx.set(txRef, {
        'userId': withdrawal.userId,
        'type': 'redeemApproved',
        'rewardAmount': withdrawal.coinCost,
        'balanceBefore': currentCoins,
        'balanceAfter': currentCoins - withdrawal.coinCost,
        'referenceId': withdrawalId,
        'description':
            'Redeem approved: ${withdrawal.package} - ${withdrawal.packageValue}',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // 7. Mark redeem code as assigned
      if (codeRefToAssign != null) {
        tx.update(codeRefToAssign, {
          'status': 'assigned',
          'assignedUser': withdrawal.userId,
          'assignedDate': FieldValue.serverTimestamp(),
        });
      } else if (codeToAssign != null && codeToAssign.isNotEmpty) {
        final codeQuery = await _firestore
            .collection(AppConstants.redeemCodesCollection)
            .where('code', isEqualTo: codeToAssign)
            .limit(1)
            .get();

        if (codeQuery.docs.isNotEmpty) {
          tx.update(codeQuery.docs.first.reference, {
            'status': 'assigned',
            'assignedUser': withdrawal.userId,
            'assignedDate': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    // 8. Send Push Notification
    if (targetUserId.isNotEmpty) {
      await _notificationRepo.createNotification(
        title: 'Congratulations!',
        message: 'Your withdrawal request was approved. You received a redeem code!',
        type: NotificationType.redeemApproved,
        targetUserId: targetUserId,
      );
    }
  }

  /// Reject a withdrawal — coins remain unchanged
  Future<void> rejectWithdrawal({
    required String withdrawalId,
    String? adminRemark,
  }) async {
    final withdrawalRef = _firestore
        .collection(AppConstants.withdrawalsCollection)
        .doc(withdrawalId);
    final doc = await withdrawalRef.get();

    if (!doc.exists) {
      throw const FirestoreException(message: 'Withdrawal not found.');
    }

    final withdrawal = WithdrawalModel.fromFirestore(doc);

    await withdrawalRef.update({
      'status': 'rejected',
      'adminRemark': adminRemark,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Log rejection transaction
    await _firestore.collection(AppConstants.transactionsCollection).add({
      'userId': withdrawal.userId,
      'type': 'redeemRejected',
      'rewardAmount': withdrawal.coinCost,
      'balanceBefore': 0, // Will be 0 since no coins changed
      'balanceAfter': 0,
      'referenceId': withdrawalId,
      'description':
          'Redeem rejected: ${withdrawal.package}${adminRemark != null ? " - $adminRemark" : ""}',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    });
    
    // Send Push Notification
    await _notificationRepo.createNotification(
      title: 'Redemption Rejected',
      message: 'Unfortunately your redemption request was rejected.${adminRemark != null ? " Reason: $adminRemark" : ""}',
      type: NotificationType.redeemRejected,
      targetUserId: withdrawal.userId,
    );
  }

  /// Mark a redeem code as used by the user
  Future<void> markAsUsed({
    required String withdrawalId,
    required String redeemCode,
  }) async {
    await _firestore.runTransaction((tx) async {
      // 1. Update withdrawal
      final withdrawalRef = _firestore
          .collection(AppConstants.withdrawalsCollection)
          .doc(withdrawalId);
      final withdrawalDoc = await tx.get(withdrawalRef);

      if (!withdrawalDoc.exists) {
        throw const FirestoreException(message: 'Withdrawal not found.');
      }

      tx.update(withdrawalRef, {
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update redeem code status to 'used'
      final codeQuery = await _firestore
          .collection(AppConstants.redeemCodesCollection)
          .where('code', isEqualTo: redeemCode)
          .limit(1)
          .get();

      if (codeQuery.docs.isNotEmpty) {
        tx.update(codeQuery.docs.first.reference, {
          'status': 'used',
        });
      }
    });
  }
}

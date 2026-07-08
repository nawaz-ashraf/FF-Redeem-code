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

  Future<WithdrawalModel> submitWithdrawal({
    required String userId,
    required String freeFireUID,
    required String package,
    required int coinCost,
    required String packageValue,
  }) async {
    // 1. Check for existing pending request OUTSIDE transaction
    final existingPending = await _firestore
        .collection(AppConstants.withdrawalsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingPending.docs.isNotEmpty) {
      throw const ValidationException(
        message: 'You already have a redemption request under review.',
      );
    }

    WithdrawalModel? withdrawal;

    await _firestore.runTransaction((tx) async {
      // 2. READS
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) throw const AuthException(message: 'User not found.');

      final userData = userDoc.data()!;
      final currentCoins = (userData['coins'] ?? 0).toInt();
      final isBanned = userData['isBanned'] == true;

      if (isBanned) {
        throw const ValidationException(message: 'User is banned from redemptions.');
      }

      if (currentCoins < coinCost) {
        throw const ValidationException(
          message: 'Insufficient coins.',
        );
      }

      // 3. WRITES
      final docRef = _firestore.collection(AppConstants.withdrawalsCollection).doc();

      withdrawal = WithdrawalModel(
        withdrawalId: docRef.id,
        userId: userId,
        freeFireUID: freeFireUID,
        package: package,
        coinCost: coinCost,
        packageValue: packageValue,
        status: WithdrawalStatus.pending,
        requestedAt: DateTime.now(),
      );

      tx.update(userRef, {
        'coins': FieldValue.increment(-coinCost),
        'totalRedeemedCoins': FieldValue.increment(coinCost),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(docRef, withdrawal!.toFirestore());

      final txRef = _firestore.collection(AppConstants.transactionsCollection).doc();
      tx.set(txRef, {
        'userId': userId,
        'type': 'Redeem Request',
        'rewardAmount': -coinCost,
        'coins': -coinCost,
        'balanceBefore': currentCoins,
        'balanceAfter': currentCoins - coinCost,
        'referenceId': docRef.id,
        'description': 'Redemption request for $package - $packageValue',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    });

    await FirebaseService.logEvent('withdrawal_submitted', parameters: {
      'package': package,
      'coins': coinCost,
    });

    return withdrawal!;
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

  /// Approve a withdrawal: assign redeem code, update statuses (coins already deducted)
  Future<void> approveWithdrawal({
    required String withdrawalId,
    String? redeemCode,
    String? adminRemark,
  }) async {
    String? codeToAssign = redeemCode;
    DocumentReference? codeRefToAssign;

    // 1. Fetch required data OUTSIDE the transaction
    if (codeToAssign == null || codeToAssign.isEmpty) {
      final tempWithdrawalDoc = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .doc(withdrawalId)
          .get();
          
      if (!tempWithdrawalDoc.exists) {
        throw const FirestoreException(message: 'Withdrawal not found.');
      }
      final tempWithdrawal = WithdrawalModel.fromFirestore(tempWithdrawalDoc);
      
      if (tempWithdrawal.status != WithdrawalStatus.pending) {
        throw const ValidationException(
            message: 'This request has already been processed.');
      }

      final codeQuery = await _firestore
          .collection(AppConstants.redeemCodesCollection)
          .where('package', isEqualTo: tempWithdrawal.package)
          .where('status', isEqualTo: 'available')
          .limit(1)
          .get();

      if (codeQuery.docs.isEmpty) {
        throw const ValidationException(
            message: 'No available redeem codes for this package.');
      }

      codeToAssign = codeQuery.docs.first.data()['code'];
      codeRefToAssign = codeQuery.docs.first.reference;
    } else {
      final codeQuery = await _firestore
          .collection(AppConstants.redeemCodesCollection)
          .where('code', isEqualTo: codeToAssign)
          .limit(1)
          .get();
      if (codeQuery.docs.isNotEmpty) {
        codeRefToAssign = codeQuery.docs.first.reference;
      }
    }
    
    String targetUserId = '';

    await _firestore.runTransaction((tx) async {
      // ==========================================
      // PHASE 1: READS
      // ==========================================
      
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
      
      targetUserId = withdrawal.userId;
      
      if (codeRefToAssign != null) {
        final codeDoc = await tx.get(codeRefToAssign);
        if (codeDoc.exists) {
           final data = codeDoc.data() as Map<String, dynamic>?;
           final status = data?['status'];
           if (status != null && status.toString().toLowerCase() != 'available') {
             throw const ValidationException(message: 'Redeem code is no longer available.');
           }
        }
      }

      // ==========================================
      // PHASE 2: WRITES
      // ==========================================

      tx.update(withdrawalRef, {
        'status': 'approved',
        'assignedRedeemCode': codeToAssign,
        'adminRemark': adminRemark,
        'approvedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (codeRefToAssign != null) {
        tx.update(codeRefToAssign, {
          'status': 'Assigned',
          'assignedTo': withdrawal.userId,
          'assignedUser': withdrawal.userId,
          'assignedDate': FieldValue.serverTimestamp(),
        });
      }
    });

    if (targetUserId.isNotEmpty) {
      await _notificationRepo.createNotification(
        title: 'Redemption Approved',
        message: 'Congratulations!\nYour redemption request has been approved.\nYour voucher code is now available.',
        type: NotificationType.redeemApproved,
        targetUserId: targetUserId,
      );
    }
  }

  /// Reject a withdrawal — refund coins to user
  Future<void> rejectWithdrawal({
    required String withdrawalId,
    String? adminRemark,
  }) async {
    String targetUserId = '';
    
    await _firestore.runTransaction((tx) async {
      final withdrawalRef = _firestore
          .collection(AppConstants.withdrawalsCollection)
          .doc(withdrawalId);
      final withdrawalDoc = await tx.get(withdrawalRef);

      if (!withdrawalDoc.exists) {
        throw const FirestoreException(message: 'Withdrawal not found.');
      }

      final withdrawal = WithdrawalModel.fromFirestore(withdrawalDoc);

      if (withdrawal.status != WithdrawalStatus.pending) {
        throw const ValidationException(message: 'This request has already been processed.');
      }
      
      targetUserId = withdrawal.userId;

      final userRef = _firestore.collection(AppConstants.usersCollection).doc(withdrawal.userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) {
        throw const FirestoreException(message: 'User not found.');
      }

      final currentCoins = (userDoc.data()!['coins'] ?? 0).toInt();

      // WRITES
      tx.update(userRef, {
        'coins': FieldValue.increment(withdrawal.coinCost),
        'totalRedeemedCoins': FieldValue.increment(-withdrawal.coinCost),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(withdrawalRef, {
        'status': 'rejected',
        'adminRemark': adminRemark,
        'completedAt': FieldValue.serverTimestamp(),
      });

      final txRef = _firestore.collection(AppConstants.transactionsCollection).doc();
      tx.set(txRef, {
        'userId': withdrawal.userId,
        'type': 'Redeem Refund',
        'rewardAmount': withdrawal.coinCost,
        'coins': withdrawal.coinCost,
        'balanceBefore': currentCoins,
        'balanceAfter': currentCoins + withdrawal.coinCost,
        'referenceId': withdrawalId,
        'description': 'Redeem rejected: ${withdrawal.package}${adminRemark != null ? " - $adminRemark" : ""}',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    });

    if (targetUserId.isNotEmpty) {
      await _notificationRepo.createNotification(
        title: 'Redemption Rejected',
        message: 'Your redemption request was rejected. Your coins have been refunded.',
        type: NotificationType.redeemRejected,
        targetUserId: targetUserId,
      );
    }
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

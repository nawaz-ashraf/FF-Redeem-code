// lib/data/repositories/withdrawal_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_service.dart';
import '../models/withdrawal_model.dart';
import '../models/transaction_model.dart';
import 'user_repository.dart';

class WithdrawalRepository {
  final _firestore = FirebaseService.firestore;
  final _userRepo = UserRepository();

  Future<WithdrawalModel> submitWithdrawal({
    required String userId,
    required String ffUid,
    required String packageName,
    required int coinAmount,
    required String packageValue,
  }) async {
    // Check if user has enough coins
    final user = await _userRepo.getUser(userId);
    if (user == null) throw const AuthException(message: 'User not found.');

    if (user.coins < coinAmount) {
      throw const ValidationException(
        message: 'Insufficient coins for this redemption.',
      );
    }

    // Check for existing pending request
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
      id: docRef.id,
      userId: userId,
      ffUid: ffUid,
      packageName: packageName,
      coinAmount: coinAmount,
      packageValue: packageValue,
      status: WithdrawalStatus.pending,
      createdAt: DateTime.now(),
    );

    await docRef.set(withdrawal.toFirestore());

    // Log transaction
    await _firestore.collection(AppConstants.transactionsCollection).add({
      'userId': userId,
      'type': TransactionType.redeem.name,
      'coins': coinAmount,
      'isCredit': false,
      'description': 'Redemption request for $packageName - $packageValue',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    await FirebaseService.logEvent('withdrawal_submitted', parameters: {
      'package': packageName,
      'coins': coinAmount,
    });

    return withdrawal;
  }

  Stream<List<WithdrawalModel>> watchUserWithdrawals(String userId) {
    return _firestore
        .collection(AppConstants.withdrawalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => WithdrawalModel.fromFirestore(d)).toList());
  }

  Stream<List<WithdrawalModel>> watchAllWithdrawals({String? status}) {
    var ref = _firestore
        .collection(AppConstants.withdrawalsCollection)
        .where('status', isEqualTo: status ?? 'pending')
        .orderBy('createdAt', descending: true);

    return ref
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => WithdrawalModel.fromFirestore(d)).toList());
  }

  Future<void> approveWithdrawal({
    required String withdrawalId,
    required String redeemCode,
    String? adminNotes,
  }) async {
    await _firestore.runTransaction((tx) async {
      final withdrawalRef = _firestore
          .collection(AppConstants.withdrawalsCollection)
          .doc(withdrawalId);
      final withdrawalDoc = await tx.get(withdrawalRef);

      if (!withdrawalDoc.exists) {
        throw const FirestoreException(message: 'Withdrawal not found.');
      }

      final withdrawal = WithdrawalModel.fromFirestore(withdrawalDoc);

      // Deduct coins from user
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(withdrawal.userId);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) {
        throw const FirestoreException(message: 'User not found.');
      }

      final currentCoins = (userDoc.data()!['coins'] ?? 0).toInt();
      if (currentCoins < withdrawal.coinAmount) {
        throw const ValidationException(message: 'User has insufficient coins.');
      }

      tx.update(userRef, {
        'coins': FieldValue.increment(-withdrawal.coinAmount),
        'totalRedeemed': FieldValue.increment(withdrawal.coinAmount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      tx.update(withdrawalRef, {
        'status': 'approved',
        'redeemCode': redeemCode,
        'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectWithdrawal({
    required String withdrawalId,
    String? adminNotes,
  }) async {
    await _firestore
        .collection(AppConstants.withdrawalsCollection)
        .doc(withdrawalId)
        .update({
      'status': 'rejected',
      'adminNotes': adminNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

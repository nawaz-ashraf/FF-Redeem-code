// lib/data/repositories/admin_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AdminRepository {
  final _firestore = FirebaseService.firestore;

  /// Fetch comprehensive dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayTimestamp = Timestamp.fromDate(todayStart);

    final results = await Future.wait([
      _firestore.collection(AppConstants.usersCollection).count().get(),
      _firestore
          .collection(AppConstants.usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: todayTimestamp)
          .count()
          .get(),
      _firestore
          .collection(AppConstants.withdrawalsCollection)
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
      _firestore
          .collection(AppConstants.withdrawalsCollection)
          .where('status', isEqualTo: 'approved')
          .count()
          .get(),
      _firestore
          .collection(AppConstants.withdrawalsCollection)
          .where('status', isEqualTo: 'rejected')
          .count()
          .get(),
      _firestore
          .collection(AppConstants.adRewardsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: todayTimestamp)
          .count()
          .get(),
      _firestore
          .collection(AppConstants.redeemCodesCollection)
          .where('status', isEqualTo: 'available')
          .count()
          .get(),
    ]);

    final totalUsers = results[0].count ?? 0;
    final todayUsers = results[1].count ?? 0;
    final pendingWithdrawals = results[2].count ?? 0;
    final approvedWithdrawals = results[3].count ?? 0;
    final rejectedWithdrawals = results[4].count ?? 0;
    final todayAds = results[5].count ?? 0;
    final availableCodes = results[6].count ?? 0;

    final totalWithdrawals =
        pendingWithdrawals + approvedWithdrawals + rejectedWithdrawals;
    final conversionRate = totalWithdrawals > 0
        ? ((approvedWithdrawals / totalWithdrawals) * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'totalUsers': totalUsers,
      'todayUsers': todayUsers,
      'pendingWithdrawals': pendingWithdrawals,
      'approvedWithdrawals': approvedWithdrawals,
      'rejectedWithdrawals': rejectedWithdrawals,
      'todayAds': todayAds,
      'availableCodes': availableCodes,
      'conversionRate': conversionRate,
    };
  }

  /// Ban a user
  Future<void> banUser(String userId, {String? reason}) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'accountStatus': 'banned',
      'isBanned': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add to banned users collection
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (userDoc.exists) {
      final deviceId = userDoc.data()?['deviceId'];
      if (deviceId != null) {
        await _firestore
            .collection(AppConstants.bannedUsersCollection)
            .doc(deviceId)
            .set({
          'userId': userId,
          'deviceId': deviceId,
          'reason': reason,
          'bannedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await _logAdminAction('ban_user', userId, reason);
  }

  /// Unban a user
  Future<void> unbanUser(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'accountStatus': 'active',
      'isBanned': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Remove from banned users collection
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (userDoc.exists) {
      final deviceId = userDoc.data()?['deviceId'];
      if (deviceId != null) {
        await _firestore
            .collection(AppConstants.bannedUsersCollection)
            .doc(deviceId)
            .delete();
      }
    }

    await _logAdminAction('unban_user', userId, null);
  }

  /// Delete a user completely
  Future<void> deleteUser(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .delete();
    await _logAdminAction('delete_user', userId, null);
  }

  /// Reset a user's coins to zero
  Future<void> resetCoins(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'coins': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logAdminAction('reset_coins', userId, null);
  }

  /// Adjust user coins with logging
  Future<void> adjustCoins(String userId, int amount) async {
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!userDoc.exists) return;
    final currentCoins = (userDoc.data()!['coins'] ?? 0).toInt();

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'coins': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log admin transaction
    await _firestore.collection(AppConstants.transactionsCollection).add({
      'userId': userId,
      'type': amount >= 0 ? 'adminCredit' : 'adminDebit',
      'rewardAmount': amount.abs(),
      'balanceBefore': currentCoins,
      'balanceAfter': currentCoins + amount,
      'description':
          'Admin adjustment: ${amount >= 0 ? "+$amount" : "$amount"} coins',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    });

    await _logAdminAction('adjust_coins', userId, 'Amount: $amount');
  }

  /// Search users by name, email, or Game UID
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    // Search by name (prefix)
    final nameResults = await _firestore
        .collection(AppConstants.usersCollection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    // Search by FF UID (exact)
    final uidResults = await _firestore
        .collection(AppConstants.usersCollection)
        .where('freeFireUID', isEqualTo: query)
        .limit(5)
        .get();

    // Merge results (deduplicate by doc ID)
    final Map<String, UserModel> merged = {};
    for (final doc in nameResults.docs) {
      merged[doc.id] = UserModel.fromFirestore(doc);
    }
    for (final doc in uidResults.docs) {
      merged[doc.id] = UserModel.fromFirestore(doc);
    }

    return merged.values.toList();
  }

  /// Get all users paginated
  Future<List<UserModel>> getUsers({
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// Log admin action for audit trail
  Future<void> _logAdminAction(
    String action,
    String targetUserId,
    String? details,
  ) async {
    await _firestore.collection(AppConstants.adminLogsCollection).add({
      'action': action,
      'targetUserId': targetUserId,
      'adminId': FirebaseService.currentUserId,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

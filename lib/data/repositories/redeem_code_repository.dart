// lib/data/repositories/redeem_code_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_service.dart';
import '../models/redeem_code_model.dart';

class RedeemCodeRepository {
  final _firestore = FirebaseService.firestore;

  /// Add a single redeem code (admin)
  Future<void> addSingleCode({
    required String code,
    required String package,
    required String value,
    required String createdBy,
  }) async {
    // Check if code already exists
    final existing = await _firestore
        .collection(AppConstants.redeemCodesCollection)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw const ValidationException(
        message: 'This redeem code already exists.',
      );
    }

    final model = RedeemCodeModel(
      code: code,
      package: package,
      value: value,
      status: RedeemCodeStatus.available,
      createdDate: DateTime.now(),
      createdBy: createdBy,
    );

    await _firestore
        .collection(AppConstants.redeemCodesCollection)
        .doc()
        .set(model.toFirestore());
  }

  /// Upload multiple codes in bulk (from CSV parsing)
  Future<int> uploadCodes({
    required List<Map<String, String>> codes,
    required String createdBy,
  }) async {
    final batch = _firestore.batch();
    int count = 0;

    for (final entry in codes) {
      final code = entry['code'] ?? '';
      final package = entry['package'] ?? '';
      final value = entry['value'] ?? '';

      if (code.isEmpty || package.isEmpty) continue;

      final ref =
          _firestore.collection(AppConstants.redeemCodesCollection).doc();
      batch.set(ref, {
        'code': code,
        'package': package,
        'value': value,
        'status': 'available',
        'assignedUser': null,
        'assignedDate': null,
        'createdDate': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });
      count++;

      // Firestore batch limit is 500
      if (count % 450 == 0) {
        await batch.commit();
      }
    }

    if (count % 450 != 0) {
      await batch.commit();
    }

    return count;
  }

  /// Delete a redeem code by document ID
  Future<void> deleteCode(String docId) async {
    await _firestore
        .collection(AppConstants.redeemCodesCollection)
        .doc(docId)
        .delete();
  }

  /// Search codes by code string
  Future<List<RedeemCodeModel>> searchCode(String query) async {
    final snap = await _firestore
        .collection(AppConstants.redeemCodesCollection)
        .where('code', isGreaterThanOrEqualTo: query.toUpperCase())
        .where('code', isLessThanOrEqualTo: '${query.toUpperCase()}\uf8ff')
        .limit(20)
        .get();

    return snap.docs
        .map((d) => RedeemCodeModel.fromFirestore(d))
        .toList();
  }

  /// Get codes filtered by package and/or status
  Stream<List<RedeemCodeModel>> watchCodes({
    String? packageFilter,
    String? statusFilter,
    int limit = 50,
  }) {
    Query query =
        _firestore.collection(AppConstants.redeemCodesCollection);

    if (packageFilter != null && packageFilter.isNotEmpty) {
      query = query.where('package', isEqualTo: packageFilter);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query
        .orderBy('createdDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RedeemCodeModel.fromFirestore(d)).toList());
  }

  /// Get an available code for a specific package (used during approval)
  Future<RedeemCodeModel?> getAvailableCodeForPackage(String package) async {
    final snap = await _firestore
        .collection(AppConstants.redeemCodesCollection)
        .where('package', isEqualTo: package)
        .where('status', isEqualTo: 'available')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return RedeemCodeModel.fromFirestore(snap.docs.first);
  }

  /// Count available codes per package
  Future<Map<String, int>> getAvailableCodeCounts() async {
    final snap = await _firestore
        .collection(AppConstants.redeemCodesCollection)
        .where('status', isEqualTo: 'available')
        .get();

    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final package = doc.data()['package'] as String? ?? 'unknown';
      counts[package] = (counts[package] ?? 0) + 1;
    }
    return counts;
  }
}

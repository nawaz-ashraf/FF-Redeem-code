// lib/presentation/providers/admin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/redeem_code_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/redeem_code_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final redeemCodeRepositoryProvider = Provider<RedeemCodeRepository>((ref) {
  return RedeemCodeRepository();
});

/// Dashboard stats (refresh on demand)
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardStats();
});

/// Redeem codes stream with optional filters
final redeemCodesProvider = StreamProvider.family<List<RedeemCodeModel>,
    Map<String, String?>>((ref, filters) {
  final repo = ref.watch(redeemCodeRepositoryProvider);
  return repo.watchCodes(
    packageFilter: filters['package'],
    statusFilter: filters['status'],
  );
});

/// User search results
final userSearchProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.searchUsers(query);
});

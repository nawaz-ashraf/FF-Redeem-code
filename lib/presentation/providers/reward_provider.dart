// lib/presentation/providers/reward_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/withdrawal_repository.dart';
import '../../data/models/withdrawal_model.dart';
import 'auth_provider.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository();
});

final withdrawalRepositoryProvider = Provider<WithdrawalRepository>((ref) {
  return WithdrawalRepository();
});

// Daily limits
final dailyLimitsProvider = FutureProvider<Map<String, int>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  if (userId == null) return {};

  final repo = ref.watch(rewardRepositoryProvider);
  return repo.getDailyLimits(userId);
});

// Withdrawals stream
final userWithdrawalsProvider =
    StreamProvider<List<WithdrawalModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  if (userId == null) return Stream.value([]);

  final repo = ref.watch(withdrawalRepositoryProvider);
  return repo.watchUserWithdrawals(userId);
});

// All withdrawals (admin)
final allWithdrawalsProvider =
    StreamProvider.family<List<WithdrawalModel>, String?>((ref, status) {
  final repo = ref.watch(withdrawalRepositoryProvider);
  if (status == null) {
    // Return all - in practice we still filter
    return ref.watch(withdrawalRepositoryProvider).watchAllWithdrawals(
      status: 'pending',
    ).map((l) => l);
  }
  return repo.watchAllWithdrawals(status: status);
});

// Reward action state
class RewardState {
  final bool isLoading;
  final String? error;
  final int? lastReward;

  const RewardState({
    this.isLoading = false,
    this.error,
    this.lastReward,
  });

  RewardState copyWith({
    bool? isLoading,
    String? error,
    int? lastReward,
  }) {
    return RewardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastReward: lastReward ?? this.lastReward,
    );
  }
}

class RewardNotifier extends StateNotifier<RewardState> {
  final RewardRepository _repo;
  final String userId;

  RewardNotifier(this._repo, this.userId) : super(const RewardState());

  Future<int?> claimAdReward(String rewardId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final coins = await _repo.claimAdReward(userId, rewardId);
      state = state.copyWith(isLoading: false, lastReward: coins);
      return coins;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<int?> claimScratchReward(String rewardId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final coins = await _repo.claimScratchReward(userId, rewardId);
      state = state.copyWith(isLoading: false, lastReward: coins);
      return coins;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<int?> claimSpinReward(String rewardId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final coins = await _repo.claimSpinReward(userId, rewardId);
      state = state.copyWith(isLoading: false, lastReward: coins);
      return coins;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> claimDailyLogin() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.claimDailyLogin(userId);
      state = state.copyWith(isLoading: false, lastReward: result['coins']);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final rewardNotifierProvider =
    StateNotifierProvider<RewardNotifier, RewardState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid ?? '';
  return RewardNotifier(ref.watch(rewardRepositoryProvider), userId);
});

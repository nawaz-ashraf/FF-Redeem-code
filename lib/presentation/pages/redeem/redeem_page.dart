// lib/presentation/pages/redeem/redeem_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../../data/repositories/withdrawal_repository.dart';

class RedeemPage extends ConsumerStatefulWidget {
  const RedeemPage({super.key});

  @override
  ConsumerState<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends ConsumerState<RedeemPage> {
  final List<_RedeemPackage> _packages = [
    _RedeemPackage(
      name: '₹100 Reward Code',
      coins: 2500,
      value: '₹100',
      emoji: '💎',
      gradient: AppColors.blueGradient,
      popular: false,
    ),
    _RedeemPackage(
      name: '₹200 Reward Code',
      coins: 5000,
      value: '₹200',
      emoji: '💎💎',
      gradient: AppColors.purpleGradient,
      popular: true,
    ),
    _RedeemPackage(
      name: '₹400 Reward Code',
      coins: 10000,
      value: '₹400',
      emoji: '💎💎💎',
      gradient: AppColors.goldGradient,
      popular: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final withdrawals = ref.watch(userWithdrawalsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: false,
                title: Text(
                  'Redeem Coins',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coin balance
                      userAsync.when(
                        data: (user) => user != null
                            ? _buildCoinBalance(user.coins)
                            : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 20),
                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Text('ℹ️', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Rewards are subject to availability. Codes are assigned by admin after review.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Packages
                      Text(
                        'Choose Your Package',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        _packages.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RedeemPackageCard(
                            package: _packages[i],
                            userCoins: userAsync.value?.coins ?? 0,
                            onRedeem: () => _showConfirmDialog(
                              context,
                              _packages[i],
                              userAsync.value?.id ?? '',
                              userAsync.value?.ffUid ?? '',
                            ),
                          )
                              .animate(delay: (i * 100).ms)
                              .slideX(begin: 0.3, duration: 400.ms)
                              .fade(duration: 400.ms),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Request History
                      Text(
                        'My Requests',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 12),
                      withdrawals.when(
                        data: (list) => list.isEmpty
                            ? _buildEmptyRequests()
                            : Column(
                                children: list
                                    .map((w) => _WithdrawalCard(
                                        withdrawal: w))
                                    .toList(),
                              ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinBalance(int coins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A42), Color(0xFF0F1A32)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Balance',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$coins Coins',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequests() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No requests yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Submit a redeem request above',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    _RedeemPackage package,
    String userId,
    String ffUid,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Confirm Redemption',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package: ${package.name}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cost: ${package.coins} coins',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              '⚠️ Your request will be reviewed by admin. Coins are deducted only after approval.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitRequest(package, userId, ffUid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest(
      _RedeemPackage package, String userId, String ffUid) async {
    try {
      final repo = ref.read(withdrawalRepositoryProvider);
      await repo.submitWithdrawal(
        userId: userId,
        ffUid: ffUid,
        packageName: package.name,
        coinAmount: package.coins,
        packageValue: package.value,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Redemption request submitted! Pending admin review.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _RedeemPackage {
  final String name;
  final int coins;
  final String value;
  final String emoji;
  final LinearGradient gradient;
  final bool popular;

  const _RedeemPackage({
    required this.name,
    required this.coins,
    required this.value,
    required this.emoji,
    required this.gradient,
    required this.popular,
  });
}

class _RedeemPackageCard extends StatelessWidget {
  final _RedeemPackage package;
  final int userCoins;
  final VoidCallback onRedeem;

  const _RedeemPackageCard({
    required this.package,
    required this.userCoins,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = userCoins >= package.coins;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: package.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: package.gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                package.emoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('🪙',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${package.coins} coins',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: canAfford ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: package.gradient.colors.first,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor:
                      Colors.white.withOpacity(0.3),
                ),
                child: Text(
                  canAfford ? 'Redeem' : 'Need More',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (package.popular)
          Positioned(
            top: -8,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⭐ Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalModel withdrawal;

  const _WithdrawalCard({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusEmoji;
    switch (withdrawal.status) {
      case WithdrawalStatus.approved:
        statusColor = AppColors.success;
        statusEmoji = '✅';
        break;
      case WithdrawalStatus.rejected:
        statusColor = AppColors.error;
        statusEmoji = '❌';
        break;
      default:
        statusColor = AppColors.warning;
        statusEmoji = '⏳';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(statusEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  withdrawal.packageName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  withdrawal.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${withdrawal.coinAmount} coins',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              Text(
                withdrawal.createdAt.toLocal().toString().substring(0, 10),
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
          if (withdrawal.status == WithdrawalStatus.approved &&
              withdrawal.redeemCode != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            Text(
              '🎁 Your Reward Code:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      withdrawal.redeemCode!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                  onPressed: () {
                    // Copy to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied! ✅')),
                    );
                  },
                ),
              ],
            ),
          ],
          if (withdrawal.adminNotes != null &&
              withdrawal.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📝 ${withdrawal.adminNotes}',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

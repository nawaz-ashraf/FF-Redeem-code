// lib/presentation/pages/redeem/redeem_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/reward_provider.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/repositories/withdrawal_repository.dart';

class RedeemPage extends ConsumerStatefulWidget {
  const RedeemPage({super.key});

  @override
  ConsumerState<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends ConsumerState<RedeemPage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

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
                      
                      // History Button
                      _buildHistoryButton(context),
                      
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
                      settingsAsync.when(
                        data: (settings) {
                          final packages = settings.redeemPackages;
                          if (packages.isEmpty) {
                            return const Center(child: Text('No packages available'));
                          }
                          return Column(
                            children: List.generate(
                              packages.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _RedeemPackageCard(
                                  package: packages[i],
                                  userCoins: userAsync.value?.coins ?? 0,
                                  onRedeem: () => _showConfirmDialog(
                                    context,
                                    packages[i],
                                    userAsync.value?.uid ?? '',
                                  ),
                                )
                                    .animate(delay: (i * 100).ms)
                                    .slideX(begin: 0.3, duration: 400.ms)
                                    .fade(duration: 400.ms),
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _buildHistoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/redemption-history'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Redemption History',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    RedeemPackageModel package,
    String userId,
  ) {
    final uidController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
        content: Form(
          key: formKey,
          child: Column(
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
              TextFormField(
                controller: uidController,
                decoration: InputDecoration(
                  labelText: 'Enter your Game UID',
                  hintText: 'e.g. 123456789',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Game UID is required';
                  }
                  return null;
                },
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx);
                await _submitRequest(package, userId, uidController.text.trim());
              }
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
      RedeemPackageModel package, String userId, String ffUid) async {
    try {
      final repo = ref.read(withdrawalRepositoryProvider);
      await repo.submitWithdrawal(
        userId: userId,
        freeFireUID: ffUid,
        package: package.name,
        coinCost: package.coins,
        packageValue: package.value,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Redemption request submitted! Pending admin review.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/redemption-history');
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

class _RedeemPackageCard extends StatelessWidget {
  final RedeemPackageModel package;
  final int userCoins;
  final VoidCallback onRedeem;

  const _RedeemPackageCard({
    required this.package,
    required this.userCoins,
    required this.onRedeem,
  });

  LinearGradient _getGradient() {
    switch (package.gradientColors.toLowerCase()) {
      case 'purple':
        return AppColors.purpleGradient;
      case 'gold':
        return AppColors.goldGradient;
      case 'blue':
      default:
        return AppColors.blueGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = userCoins >= package.coins;
    final gradient = _getGradient();

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                package.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '🪙 ',
                            style: TextStyle(fontSize: 14),
                          ),
                          TextSpan(
                            text: '${package.coins} coins',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: canAfford ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: gradient.colors.first,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor:
                      Colors.white.withOpacity(0.3),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    canAfford ? 'Redeem' : 'Need More',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
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

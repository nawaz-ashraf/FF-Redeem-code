// lib/presentation/pages/admin/admin_user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../../data/repositories/withdrawal_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../../core/extensions/extensions.dart';

class AdminUserDetailPage extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailPage> createState() =>
      _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends ConsumerState<AdminUserDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStream = ref.watch(userRepositoryProvider).watchUser(widget.userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Transactions'),
            Tab(text: 'Withdrawals'),
          ],
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _ProfileTab(user: user, onAction: _handleAction),
              _TransactionsTab(userId: widget.userId),
              _WithdrawalsTab(userId: widget.userId),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAction(String action, UserModel user) async {
    final adminRepo = ref.read(adminRepositoryProvider);

    switch (action) {
      case 'ban':
        final confirm = await _showConfirmDialog(
          'Ban ${user.name}?',
          'This will prevent the user from logging in.',
        );
        if (confirm) {
          await adminRepo.banUser(user.uid, reason: 'Admin action');
        }
        break;
      case 'unban':
        await adminRepo.unbanUser(user.uid);
        break;
      case 'delete':
        final confirm = await _showConfirmDialog(
          'Delete ${user.name}?',
          'This is permanent and cannot be undone.',
        );
        if (confirm) {
          await adminRepo.deleteUser(user.uid);
          if (mounted) Navigator.pop(context);
        }
        break;
      case 'resetCoins':
        final confirm = await _showConfirmDialog(
          'Reset coins for ${user.name}?',
          'This will set their coin balance to 0.',
        );
        if (confirm) await adminRepo.resetCoins(user.uid);
        break;
      case 'adjustCoins':
        _showAdjustCoinsDialog(user);
        break;
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAdjustCoinsDialog(UserModel user) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Adjust Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current balance: ${user.coins}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (use negative to deduct)',
                hintText: 'e.g., 100 or -50',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text);
              if (amount != null && amount != 0) {
                await ref
                    .read(adminRepositoryProvider)
                    .adjustCoins(user.uid, amount);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Coins adjusted by ${amount.withSign}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(String, UserModel) onAction;

  const _ProfileTab({required this.user, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    user.name.initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'FF UID: ${user.freeFireUID}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isBanned
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isBanned ? 'BANNED' : 'ACTIVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: user.isBanned
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip('💰 Coins', '${user.coins}'),
              _statChip('📈 Earned', '${user.totalEarnedCoins}'),
              _statChip('🎁 Redeemed', '${user.totalRedeemedCoins}'),
              _statChip('📺 Ads', '${user.totalAdsWatched}'),
              _statChip('👥 Referrals', '${user.referralCount}'),
              _statChip('🔥 Streak', '${user.dailyStreak}'),
            ],
          ),

          const SizedBox(height: 24),

          // Admin actions
          _adminButton(
            'Adjust Coins',
            Icons.account_balance_wallet_outlined,
            AppColors.accent2,
            () => onAction('adjustCoins', user),
          ),
          _adminButton(
            'Reset Coins',
            Icons.restart_alt,
            AppColors.warning,
            () => onAction('resetCoins', user),
          ),
          _adminButton(
            user.isBanned ? 'Unban User' : 'Ban User',
            user.isBanned
                ? Icons.lock_open_outlined
                : Icons.block_outlined,
            user.isBanned ? AppColors.success : AppColors.error,
            () => onAction(user.isBanned ? 'unban' : 'ban', user),
          ),
          _adminButton(
            'Delete User',
            Icons.delete_forever_outlined,
            AppColors.error,
            () => onAction('delete', user),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 18),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  final String userId;
  const _TransactionsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<TransactionModel>>(
      stream: ref.watch(userRepositoryProvider).watchTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, i) {
            final tx = transactions[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(tx.type.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.type.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          tx.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${tx.isCredit ? "+" : "-"}${tx.rewardAmount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: tx.isCredit
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _WithdrawalsTab extends ConsumerWidget {
  final String userId;
  const _WithdrawalsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<WithdrawalModel>>(
      stream: WithdrawalRepository().watchUserWithdrawals(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final withdrawals = snapshot.data ?? [];
        if (withdrawals.isEmpty) {
          return const Center(child: Text('No withdrawals'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: withdrawals.length,
          itemBuilder: (context, i) {
            final w = withdrawals[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${w.package} - ${w.packageValue}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${w.coinCost} coins',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(w.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      w.status.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _statusColor(w.status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return AppColors.warning;
      case WithdrawalStatus.approved:
        return AppColors.success;
      case WithdrawalStatus.rejected:
        return AppColors.error;
    }
  }
}

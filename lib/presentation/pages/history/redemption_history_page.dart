// lib/presentation/pages/history/redemption_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';
import '../../../data/repositories/withdrawal_repository.dart';

class RedemptionHistoryPage extends ConsumerStatefulWidget {
  const RedemptionHistoryPage({super.key});

  @override
  ConsumerState<RedemptionHistoryPage> createState() =>
      _RedemptionHistoryPageState();
}

class _RedemptionHistoryPageState extends ConsumerState<RedemptionHistoryPage>
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
    final withdrawalsAsync = ref.watch(userWithdrawalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Redemption History'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: withdrawalsAsync.when(
          data: (list) {
            final pendingList = list
                .where((w) => w.status == WithdrawalStatus.pending)
                .toList();
            final approvedList = list
                .where((w) => w.status == WithdrawalStatus.approved)
                .toList();
            final rejectedList = list
                .where((w) => w.status == WithdrawalStatus.rejected)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(pendingList, context),
                _buildList(approvedList, context),
                _buildList(rejectedList, context),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Could not load request history.\n$e',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<WithdrawalModel> list, BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No requests found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        return _RedemptionCard(withdrawal: list[i]);
      },
    );
  }
}

class _RedemptionCard extends ConsumerWidget {
  final WithdrawalModel withdrawal;

  const _RedemptionCard({required this.withdrawal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final isUsed = withdrawal.completedAt != null &&
        withdrawal.status == WithdrawalStatus.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  withdrawal.package,
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
                  color: isUsed
                      ? AppColors.info.withOpacity(0.15)
                      : statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUsed ? 'Used' : withdrawal.status.label,
                  style: TextStyle(
                    color: isUsed ? AppColors.info : statusColor,
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
                '${withdrawal.coinCost} coins',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              Text(
                withdrawal.requestedAt.toLocal().toString().substring(0, 10),
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
          
          if (withdrawal.status == WithdrawalStatus.pending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Waiting for admin approval.',
                style: TextStyle(color: AppColors.warning, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          if (withdrawal.status == WithdrawalStatus.rejected &&
              withdrawal.adminRemark != null &&
              withdrawal.adminRemark!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rejection Reason: ${withdrawal.adminRemark}',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],

          if (withdrawal.status == WithdrawalStatus.approved &&
              withdrawal.assignedRedeemCode != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            if (withdrawal.approvedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Approval Date: ${withdrawal.approvedAt!.toLocal().toString().substring(0, 10)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (withdrawal.adminRemark != null && withdrawal.adminRemark!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Admin Remark: ${withdrawal.adminRemark}',
                  style: const TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '🎁 Your Redeem Code:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUsed ? null : AppColors.goldGradient,
                color: isUsed ? AppColors.surfaceLight : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      withdrawal.assignedRedeemCode!,
                      style: TextStyle(
                        color: isUsed ? AppColors.textHint : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        decoration: isUsed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: isUsed ? AppColors.textHint : Colors.white,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: withdrawal.assignedRedeemCode!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied! ✅')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(
                        'Here is my redeem code: ${withdrawal.assignedRedeemCode!}',
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                if (!isUsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsUsed(context, ref),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark Used'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _markAsUsed(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Mark as Used?'),
        content: const Text(
          'Have you successfully redeemed this code? Once marked as used, it cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(withdrawalRepositoryProvider);
                await repo.markAsUsed(
                  withdrawalId: withdrawal.withdrawalId,
                  redeemCode: withdrawal.assignedRedeemCode!,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code marked as used!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Yes, I used it'),
          ),
        ],
      ),
    );
  }
}

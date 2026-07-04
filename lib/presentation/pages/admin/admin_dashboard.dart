// lib/presentation/pages/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/reward_provider.dart';
import '../../../data/repositories/withdrawal_repository.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _withdrawalFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user == null || !user.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Admin access required'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: 'Redeem Codes',
            onPressed: () => context.push('/admin/redeem-codes'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Requests'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.notifications), text: 'Notify'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildWithdrawalsTab(),
          _buildUsersTab(),
          _buildNotificationsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard Overview',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(dashboardStatsProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats grid
          ref.watch(dashboardStatsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (stats) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    '👥 Total Users',
                    stats['totalUsers'].toString(),
                    AppColors.accent2,
                    subtitle: '+${stats['todayUsers']} today',
                  ),
                  _buildStatCard(
                    '⏳ Pending',
                    stats['pendingWithdrawals'].toString(),
                    AppColors.warning,
                  ),
                  _buildStatCard(
                    '✅ Approved',
                    stats['approvedWithdrawals'].toString(),
                    AppColors.success,
                    subtitle: 'Conv: ${stats['conversionRate']}%',
                  ),
                  _buildStatCard(
                    '❌ Rejected',
                    stats['rejectedWithdrawals'].toString(),
                    AppColors.error,
                  ),
                  _buildStatCard(
                    '🎫 Codes Available',
                    stats['availableCodes'].toString(),
                    AppColors.gold,
                  ),
                  _buildStatCard(
                    '📺 Today\'s Ads',
                    stats['todayAds'].toString(),
                    AppColors.primary,
                  ),
                ],
              ).animate().fade().scaleXY(begin: 0.9, duration: 400.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWithdrawalsTab() {
    return Column(
      children: [
        // Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: ['pending', 'approved', 'rejected'].map((status) {
              final isSelected = _withdrawalFilter == status;
              Color color = status == 'pending'
                  ? AppColors.warning
                  : status == 'approved'
                      ? AppColors.success
                      : AppColors.error;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _withdrawalFilter = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? color : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // List
        Expanded(
          child: StreamBuilder<List<WithdrawalModel>>(
            stream: WithdrawalRepository()
                .watchAllWithdrawals(status: _withdrawalFilter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!;
              if (docs.isEmpty) {
                return Center(
                  child: Text('No $_withdrawalFilter requests'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  return _AdminWithdrawalCard(withdrawal: docs[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or FF UID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (val) {
              // Trigger search via provider if needed, or navigate to full list
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: ref.read(adminRepositoryProvider).getUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return InkWell(
                    onTap: () => context.push('/admin/user/${user.uid}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: user.isBanned
                              ? AppColors.error.withOpacity(0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: user.isBanned
                                  ? const LinearGradient(colors: [
                                      AppColors.error,
                                      Color(0xFFB71C1C)
                                    ])
                                  : AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'UID: ${user.freeFireUID} • ${user.coins} coins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    NotificationType _selectedType = NotificationType.announcement;

    return StatefulBuilder(builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Push Notification',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  prefixIcon: Icon(Icons.message),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NotificationType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Notification Type',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('${type.icon} ${type.label}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send to All Users'),
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    await ref
                        .read(notificationRepositoryProvider)
                        .sendBroadcast(
                          title: titleCtrl.text.trim(),
                          message: bodyCtrl.text.trim(),
                          type: _selectedType,
                        );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification sent successfully ✅'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      titleCtrl.clear();
                      bodyCtrl.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AdminWithdrawalCard extends ConsumerWidget {
  final WithdrawalModel withdrawal;

  const _AdminWithdrawalCard({required this.withdrawal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${withdrawal.package} - ${withdrawal.packageValue}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FF UID: ${withdrawal.freeFireUID}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${withdrawal.coinCost} coins • ${withdrawal.requestedAt.toLocal().toString().substring(0, 10)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (withdrawal.status == WithdrawalStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    onPressed: () =>
                        _showApproveDialog(context, ref, withdrawal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    onPressed: () =>
                        _showRejectDialog(context, ref, withdrawal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (withdrawal.status == WithdrawalStatus.approved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Code: ${withdrawal.assignedRedeemCode ?? "N/A"}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          ],
          if (withdrawal.status == WithdrawalStatus.rejected && withdrawal.adminRemark != null) ...[
             const SizedBox(height: 8),
             Text(
               'Reason: ${withdrawal.adminRemark}',
               style: const TextStyle(color: AppColors.error, fontSize: 12),
             ),
          ]
        ],
      ),
    );
  }

  void _showApproveDialog(
      BuildContext context, WidgetRef ref, WithdrawalModel w) {
    final codeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Approve Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder(
              future: ref.read(redeemCodeRepositoryProvider).getAvailableCodeForPackage(w.package),
              builder: (context, snapshot) {
                 return const SizedBox.shrink(); // Using AdminRepository for manual code entry currently
              },
            ),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Redeem Code *',
                hintText: 'Enter the redeem code',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
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
              if (codeCtrl.text.isEmpty) return;
              try {
                await ref.read(withdrawalRepositoryProvider).approveWithdrawal(
                      withdrawalId: w.withdrawalId,
                      redeemCode: codeCtrl.text.trim(),
                      adminRemark: notesCtrl.text.isEmpty
                          ? null
                          : notesCtrl.text,
                    );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('Approve & Send Code'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, WidgetRef ref, WithdrawalModel w) {
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject Withdrawal'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (shown to user)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(withdrawalRepositoryProvider).rejectWithdrawal(
                    withdrawalId: w.withdrawalId,
                    adminRemark: notesCtrl.text.isEmpty
                        ? null
                        : notesCtrl.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

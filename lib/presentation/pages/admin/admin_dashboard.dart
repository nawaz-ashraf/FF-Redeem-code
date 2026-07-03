// lib/presentation/pages/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/withdrawal_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';

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
          Text(
            'Dashboard Overview',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          // Stats grid
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = snapshot.data!;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('👥 Total Users',
                      stats['totalUsers'].toString(), AppColors.accent2),
                  _buildStatCard('⏳ Pending',
                      stats['pendingWithdrawals'].toString(),
                      AppColors.warning),
                  _buildStatCard('✅ Approved',
                      stats['approvedWithdrawals'].toString(),
                      AppColors.success),
                  _buildStatCard('❌ Rejected',
                      stats['rejectedWithdrawals'].toString(), AppColors.error),
                  _buildStatCard('🪙 Codes Available',
                      stats['availableCodes'].toString(), AppColors.gold),
                  _buildStatCard('📺 Today\'s Ads',
                      stats['todayAds'].toString(), AppColors.primary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final fs = FirebaseService.firestore;
    final today = DateTime.now();
    final todayStart =
        DateTime(today.year, today.month, today.day);

    final results = await Future.wait([
      fs.collection(AppConstants.usersCollection).count().get(),
      fs
          .collection(AppConstants.withdrawalsCollection)
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
      fs
          .collection(AppConstants.withdrawalsCollection)
          .where('status', isEqualTo: 'approved')
          .count()
          .get(),
      fs
          .collection(AppConstants.withdrawalsCollection)
          .where('status', isEqualTo: 'rejected')
          .count()
          .get(),
      fs
          .collection(AppConstants.redeemCodesCollection)
          .where('status', isEqualTo: 'available')
          .count()
          .get(),
      fs
          .collection(AppConstants.adRewardsCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(todayStart))
          .count()
          .get(),
    ]);

    return {
      'totalUsers': results[0].count,
      'pendingWithdrawals': results[1].count,
      'approvedWithdrawals': results[2].count,
      'rejectedWithdrawals': results[3].count,
      'availableCodes': results[4].count,
      'todayAds': results[5].count,
    };
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
            ),
          ),
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
                  onTap: () =>
                      setState(() => _withdrawalFilter = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? color.withOpacity(0.2) : AppColors.surface,
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection(AppConstants.withdrawalsCollection)
                .where('status', isEqualTo: _withdrawalFilter)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text('No $_withdrawalFilter requests'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final w = WithdrawalModel.fromFirestore(docs[i]);
                  return _AdminWithdrawalCard(withdrawal: w);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection(AppConstants.usersCollection)
          .orderBy('registrationDate', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final user = UserModel.fromFirestore(docs[i]);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: user.status == 'banned'
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
                      gradient: user.status == 'banned'
                          ? const LinearGradient(
                              colors: [AppColors.error, Color(0xFFB71C1C)])
                          : AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'UID: ${user.ffUid} • ${user.coins} coins',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: AppColors.surfaceLight,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'ban', child: Text('Ban User')),
                      const PopupMenuItem(
                          value: 'unban', child: Text('Unban User')),
                      const PopupMenuItem(
                          value: 'adjust', child: Text('Adjust Coins')),
                    ],
                    onSelected: (action) =>
                        _handleUserAction(action, user),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send to All Users'),
              onPressed: () async {
                // Save notification to Firestore for FCM to pick up
                await FirebaseService.firestore
                    .collection(AppConstants.notificationsCollection)
                    .add({
                  'title': titleCtrl.text,
                  'body': bodyCtrl.text,
                  'type': 'broadcast',
                  'createdAt': FieldValue.serverTimestamp(),
                  'sentBy': FirebaseService.currentUserId,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification queued for sending ✅'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'ban':
        await FirebaseService.firestore
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .update({'status': 'banned'});
        break;
      case 'unban':
        await FirebaseService.firestore
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .update({'status': 'active'});
        break;
      case 'adjust':
        _showAdjustCoinsDialog(user);
        break;
    }
  }

  void _showAdjustCoinsDialog(UserModel user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Adjust Coins for ${user.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Amount (+/-)',
            hintText: 'e.g. +100 or -50',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(ctrl.text) ?? 0;
              await FirebaseService.firestore
                  .collection(AppConstants.usersCollection)
                  .doc(user.id)
                  .update({
                'coins': FieldValue.increment(amount),
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
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
                      withdrawal.packageName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FF UID: ${withdrawal.ffUid}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${withdrawal.coinAmount} coins • ${withdrawal.createdAt.toLocal().toString().substring(0, 10)}',
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
              await ref.read(withdrawalRepositoryProvider).approveWithdrawal(
                    withdrawalId: w.id,
                    redeemCode: codeCtrl.text.trim(),
                    adminNotes: notesCtrl.text.isEmpty
                        ? null
                        : notesCtrl.text,
                  );
              if (context.mounted) Navigator.pop(context);
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
                    withdrawalId: w.id,
                    adminNotes: notesCtrl.text.isEmpty
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

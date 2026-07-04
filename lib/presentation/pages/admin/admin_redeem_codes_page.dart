// lib/presentation/pages/admin/admin_redeem_codes_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/redeem_code_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminRedeemCodesPage extends ConsumerStatefulWidget {
  const AdminRedeemCodesPage({super.key});

  @override
  ConsumerState<AdminRedeemCodesPage> createState() =>
      _AdminRedeemCodesPageState();
}

class _AdminRedeemCodesPageState extends ConsumerState<AdminRedeemCodesPage> {
  String? _packageFilter;
  String? _statusFilter;


  @override
  Widget build(BuildContext context) {
    final filters = {'package': _packageFilter, 'status': _statusFilter};
    final codesAsync = ref.watch(redeemCodesProvider(filters));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Redeem Codes'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            onPressed: _showAddCodeDialog,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Single Code',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _packageFilter,
                    decoration: const InputDecoration(
                      labelText: 'Package',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                          value: '₹100 Code', child: Text('₹100')),
                      DropdownMenuItem(
                          value: '₹200 Code', child: Text('₹200')),
                      DropdownMenuItem(
                          value: '₹400 Code', child: Text('₹400')),
                    ],
                    onChanged: (val) =>
                        setState(() => _packageFilter = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                          value: 'available', child: Text('Available')),
                      DropdownMenuItem(
                          value: 'assigned', child: Text('Assigned')),
                      DropdownMenuItem(value: 'used', child: Text('Used')),
                    ],
                    onChanged: (val) =>
                        setState(() => _statusFilter = val),
                  ),
                ),
              ],
            ),
          ),

          // Codes list
          Expanded(
            child: codesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (codes) {
                if (codes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎫', style: TextStyle(fontSize: 56)),
                        SizedBox(height: 12),
                        Text('No codes found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: codes.length,
                  itemBuilder: (context, i) => _CodeCard(code: codes[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCodeDialog() {
    final codeCtrl = TextEditingController();
    final packageCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Redeem Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration:
                  const InputDecoration(labelText: 'Redeem Code'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Package'),
              items: const [
                DropdownMenuItem(
                    value: '₹100 Code', child: Text('₹100 Code')),
                DropdownMenuItem(
                    value: '₹200 Code', child: Text('₹200 Code')),
                DropdownMenuItem(
                    value: '₹400 Code', child: Text('₹400 Code')),
              ],
              onChanged: (val) => packageCtrl.text = val ?? '',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(
                  labelText: 'Value (e.g., ₹100)'),
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
              if (codeCtrl.text.isNotEmpty &&
                  packageCtrl.text.isNotEmpty) {
                final userId =
                    ref.read(currentUserProvider).value?.uid ?? '';
                await ref
                    .read(redeemCodeRepositoryProvider)
                    .addSingleCode(
                      code: codeCtrl.text.trim(),
                      package: packageCtrl.text,
                      value: valueCtrl.text.trim(),
                      createdBy: userId,
                    );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code added successfully')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

}

class _CodeCard extends StatelessWidget {
  final RedeemCodeModel code;

  const _CodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.vpn_key, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${code.package} • ${code.value}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code.status.label,
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (code.status) {
      case RedeemCodeStatus.available:
        return AppColors.success;
      case RedeemCodeStatus.assigned:
        return AppColors.warning;
      case RedeemCodeStatus.used:
        return AppColors.textHint;
    }
  }
}

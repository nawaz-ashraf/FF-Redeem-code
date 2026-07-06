// lib/presentation/widgets/common/update_dialog.dart
//
// Material dialog for force and optional app updates.
// Called from SplashPage before normal navigation.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_update_status.dart';
import 'gradient_button.dart';

/// Shows an update dialog and returns whether splash may continue routing.
///
/// - **Force update:** blocking dialog (no back, no dismiss). Always returns false.
/// - **Optional update:** returns true only when user taps "Later".
/// - **Update button:** opens [AppUpdateStatus.storeUrl] in external browser/Play Store.
Future<bool> showUpdateDialog(
  BuildContext context,
  AppUpdateStatus status,
) async {
  if (status.forceUpdate) {
    // Hard gate: user cannot enter the app until they update.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false, // Blocks Android back button.
        child: _UpdateDialogContent(status: status, forceUpdate: true),
      ),
    );
    return false;
  }

  // Soft prompt: user can skip and continue into the app.
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _UpdateDialogContent(status: status, forceUpdate: false),
  );
  // null (dismissed outside) or false (Update tapped) → stay on splash.
  return result ?? false;
}

class _UpdateDialogContent extends StatelessWidget {
  final AppUpdateStatus status;
  final bool forceUpdate;

  const _UpdateDialogContent({
    required this.status,
    required this.forceUpdate,
  });

  Future<void> _openStore() async {
    final uri = Uri.parse(status.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              forceUpdate ? 'Update Required' : 'Update Available',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'v${status.currentVersion} → v${status.latestVersion}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (status.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.releaseNotes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            GradientButton(
              text: 'Update',
              gradient: AppColors.primaryGradient,
              onPressed: _openStore,
              icon: Icons.download_rounded,
            ),
            if (!forceUpdate) ...[
              const SizedBox(height: 12),
              TextButton(
                // pop(true) tells SplashPage to continue normal routing.
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Later',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

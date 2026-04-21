import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/migration/migration_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:velmora/l10n/app_localizations.dart';

/// A standalone widget that provides the "Migration Data" button
/// and handles all user interaction, confirmation dialogs, progress,
/// and success states for the Firebase upload migration.
class MigrationWidget extends StatefulWidget {
  const MigrationWidget({super.key});

  @override
  State<MigrationWidget> createState() => _MigrationWidgetState();
}

class _MigrationWidgetState extends State<MigrationWidget> {
  final MigrationService _migrationService = MigrationService();
  bool _isMigrating = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF2C9C6A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _migrateData() async {
    final l10n = AppLocalizations.of(context);

    // ── Confirmation dialog ───────────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: const Color(0xFF2C9C6A),
              size: 28.adaptSize,
            ),
            SizedBox(width: 10.w),
            Text(AppLocalizations.of(context).translate('migration_data')),
          ],
        ),
        content: Text(l10n.translate('migration_confirmation_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C9C6A),
            ),
            child: Text(
              l10n.translate('upload'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // ── Progress dialog ───────────────────────────────────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: EdgeInsets.all(16.adaptSize),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2C9C6A)),
              SizedBox(height: 20.h),
              Text(
                l10n.translate('uploading_to_firebase'),
                style: TextStyle(
                  fontSize: 16.fSize,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                l10n.translate('migration_syncing_collections'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => _isMigrating = true);

    try {
      final result = await _migrationService.uploadMigrationData();
      if (mounted) Navigator.pop(context); // close progress
      if (mounted) _showMigrationSuccess(result);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('${l10n.translate('migration_failed')}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isMigrating = false);
    }
  }

  void _showMigrationSuccess(dynamic result) {
    final l10n = AppLocalizations.of(context);
    // result is a MigrationResult from migration_service.dart
    final uploaded = (result.uploadedCollections as List<String>).join('\n• ');
    final hasErrors = result.hasErrors as bool;
    final errors = (result.errors as List<String>).join('\n• ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              hasErrors ? Icons.warning_amber_rounded : Icons.cloud_done,
              color: hasErrors ? Colors.orange : Colors.green,
              size: 28.adaptSize,
            ),
            SizedBox(width: 10.w),
            Text(
              hasErrors
                  ? l10n.translate('uploaded_with_warnings')
                  : l10n.translate('upload_complete'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n
                    .translate('documents_uploaded_to_firebase')
                    .replaceAll('{count}', '${result.totalDocuments}'),
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              if (uploaded.isNotEmpty) ...[
                Text(
                  l10n.translate('collections_synced'),
                  style: TextStyle(
                    fontSize: 13.fSize,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.adaptSize),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C9C6A).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2C9C6A).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '• $uploaded',
                    style: TextStyle(
                      fontSize: 13.fSize,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              if (hasErrors) ...[
                SizedBox(height: 10.h),
                Text(
                  l10n.translate('warnings'),
                  style: TextStyle(
                    fontSize: 13.fSize,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '• $errors',
                  style: TextStyle(
                    fontSize: 12.fSize,
                    color: Colors.orange.shade800,
                    height: 1.5,
                  ),
                ),
              ],
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.adaptSize,
                      color: Colors.blueGrey.shade400,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '${l10n.translate('source')}: lib/migration/migration.json',
                        style: TextStyle(
                          fontSize: 11.fSize,
                          color: Colors.blueGrey.shade500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C9C6A),
            ),
            child: Text(l10n.done, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isMigrating ? null : _migrateData,
        icon: _isMigrating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload_outlined, size: 18),
        label: Text(
          _isMigrating
              ? l10n.translate('uploading')
              : l10n.translate('migrate_new_data'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C9C6A), // distinct teal-green
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2C9C6A).withOpacity(0.6),
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.adaptSize),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF2C9C6A).withOpacity(0.4),
        ),
      ),
    );
  }
}

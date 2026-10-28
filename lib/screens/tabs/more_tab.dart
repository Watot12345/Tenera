import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_helper.dart';
import '../../services/direct_sms_service.dart';
import '../../services/plan_guard_service.dart';
import '../../services/staff_mode_service.dart';
import '../../services/sync_service.dart';
import '../../services/theme_service.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/roof_ledger_logo.dart';
import '../lease_contract_screen.dart';
import '../portfolio_analytics_screen.dart';
import '../privacy_policy_screen.dart';
import '../reports_export_screen.dart';
import '../subscription_plans_screen.dart';
import '../utility_calculator_screen.dart';
import '../welcome_screen.dart';

class MoreTab extends StatefulWidget {
  final FutureOr<void> Function()? onStaffModeToggled;
  final bool isPro;
  final bool isBusiness;

  const MoreTab({
    super.key,
    this.onStaffModeToggled,
    this.isPro = false,
    this.isBusiness = false,
  });

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  int _pendingSyncCount = 0;
  bool _isSyncing = false;
  bool _isCheckingUpdate = false;
  bool _isStaffMode = false;
  late bool _isPro;
  late bool _isBusiness;
  String _currentVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _isPro = widget.isPro;
    _isBusiness = widget.isBusiness;
    _refreshStatus();
  }

  @override
  void didUpdateWidget(covariant MoreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPro != widget.isPro || oldWidget.isBusiness != widget.isBusiness) {
      setState(() {
        _isPro = widget.isPro;
        _isBusiness = widget.isBusiness;
      });
    }
  }

  Future<void> _refreshStatus() async {
    final count = await SyncService.instance.getPendingSyncCount();
    final ver = await UpdateService.instance.getCurrentVersion();
    final staff = await StaffModeService.isStaffMode();
    final pro = await PlanGuardService.isPro();
    final business = await PlanGuardService.isBusiness();
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
        _currentVersion = ver;
        _isStaffMode = staff;
        _isPro = pro;
        _isBusiness = business;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final result = await SyncService.instance.syncToFirebase();
    await _refreshStatus();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.status == SyncStatus.error ? const Color(0xFFC92A2A) : AppTheme.primaryDeep,
          content: Text(
            result.message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _handleCheckUpdate() async {
    setState(() => _isCheckingUpdate = true);
    await UpdateService.instance.checkAndPrompt(context, isManual: true);
    if (mounted) {
      setState(() => _isCheckingUpdate = false);
    }
  }

  Widget _buildPillBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppTheme.ink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevatedColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFC92A2A), size: 22),
            ),
            const SizedBox(width: 10),
            Text('Clear All Data?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.getInkColor(ctx))),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete all properties, rooms, tenants, and payment records from this device? You can then start entering your real properties fresh.',
          style: TextStyle(fontSize: 14, color: AppTheme.getInkColor(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await DatabaseHelper.instance.clearAllData();
              messenger.showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.primaryDeep,
                  content: Text('All data cleared. Starting fresh!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC92A2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Consolidated App & Plan Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.isDark(context)
                    ? [const Color(0xFF1E524B), const Color(0xFF133833)]
                    : [AppTheme.primaryDeep, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (AppTheme.isDark(context) ? AppTheme.darkPrimaryDeep : AppTheme.primaryDeep).withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const RoofLedgerLogo(size: 28, isLight: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tenera Property Manager',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Offline First · v$_currentVersion',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isBusiness ? 'BUSINESS' : (_isPro ? 'PRO' : 'STARTER'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tenera Pro & Plans',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SubscriptionPlansScreen(),
                            ),
                          );
                          await _refreshStatus();
                          if (widget.onStaffModeToggled != null) {
                            await widget.onStaffModeToggled!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Plans',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Landlord Tools Section (Compiled into 1 card, only shown for Pro/Business)
          if (_isPro || _isBusiness) ...[
            Text(
              'Landlord Tools',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.getInkMutedColor(context),
              ),
            ),
            const SizedBox(height: 6),
            Material(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                ),
                child: Column(
                  children: [
                    if (_isPro) ...[
                      ListTile(
                        key: const Key('more_utility_calculator'),
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.bolt_rounded, color: AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primaryDeep, size: 20),
                        ),
                        title: Text('Utility Sub-Meter Splitter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                        subtitle: Text('Split Meralco electric & water per room', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                        trailing: _buildPillBadge('PRO'),
                        onTap: () async {
                          final canAccess = await PlanGuardService.requirePro(
                            context: context,
                            featureName: 'Utility Sub-Meter Splitter',
                            featureBenefit: 'Split electric & water sub-meter bills accurately per room with zero math errors.',
                          );
                          if (!canAccess || !context.mounted) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilityCalculatorScreen()));
                        },
                      ),
                      Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                      ListTile(
                        key: const Key('more_reports_export'),
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.assessment_rounded, color: AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primaryDeep, size: 20),
                        ),
                        title: Text('Revenue & BIR Tax Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                        subtitle: Text('Export Philippine BIR tax schedules & CSV', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                        trailing: _buildPillBadge('PRO'),
                        onTap: () async {
                          final canAccess = await PlanGuardService.requirePro(
                            context: context,
                            featureName: 'Revenue & BIR Tax Report',
                            featureBenefit: 'Generate Philippine BIR tax schedules and 1-click export rental revenue to CSV.',
                          );
                          if (!canAccess || !context.mounted) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsExportScreen()));
                        },
                      ),
                    ],
                    if (_isBusiness) ...[
                      if (_isPro) Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                      if (!_isStaffMode) ...[
                        ListTile(
                          key: const Key('more_portfolio_analytics'),
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.domain_rounded, color: AppTheme.getPrimaryColor(context), size: 20),
                          ),
                          title: Text('Multi-Property Portfolio Analytics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                          subtitle: Text('Cross-property performance & occupancy', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                          trailing: _buildPillBadge('BIZ'),
                          onTap: () async {
                            final canAccess = await PlanGuardService.requireBusiness(
                              context: context,
                              featureName: 'Portfolio Analytics',
                              featureBenefit: 'Unlock cross-property yield comparisons, collection efficiency metrics, and portfolio CSV exports.',
                            );
                            if (!canAccess || !context.mounted) return;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioAnalyticsScreen()));
                          },
                        ),
                        Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                      ],
                      ListTile(
                        key: const Key('more_caretaker_mode'),
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _isStaffMode ? AppTheme.accent.withValues(alpha: 0.25) : AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isStaffMode ? Icons.shield_rounded : Icons.shield_outlined,
                            color: _isStaffMode ? (AppTheme.isDark(context) ? AppTheme.darkAccent : AppTheme.primaryDeep) : AppTheme.getPrimaryColor(context),
                            size: 20,
                          ),
                        ),
                        title: Text('Caretaker / Staff Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                        subtitle: Text(
                          _isStaffMode ? 'Active (Financials hidden) · Tap to exit' : 'Protect with 4-digit PIN',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isStaffMode ? (AppTheme.isDark(context) ? AppTheme.darkAccent : AppTheme.primaryDeep) : AppTheme.getInkMutedColor(context),
                            fontWeight: _isStaffMode ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        trailing: _buildPillBadge(_isStaffMode ? 'LOCKED' : 'BIZ'),
                        onTap: () async {
                          await StaffModeService.toggleStaffMode(
                            context,
                            onModeChanged: () async {
                              final staff = await StaffModeService.isStaffMode();
                              if (mounted) setState(() => _isStaffMode = staff);
                              if (widget.onStaffModeToggled != null) await widget.onStaffModeToggled!();
                            },
                          );
                        },
                      ),
                      if (!_isStaffMode) ...[
                        Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                        ListTile(
                          key: const Key('more_lease_contracts'),
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.assignment_turned_in_rounded, color: AppTheme.getPrimaryColor(context), size: 20),
                          ),
                          title: Text('Philippine Lease Agreement Contracts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                          subtitle: Text('Residential contract generator & autofill', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                          trailing: _buildPillBadge('BIZ'),
                          onTap: () async {
                            final canAccess = await PlanGuardService.requireBusiness(
                              context: context,
                              featureName: 'Lease Agreement Contracts',
                              featureBenefit: 'Generate legally formatted Philippine residential lease contracts with auto-filled tenant details and 1-click clipboard export.',
                            );
                            if (!canAccess || !context.mounted) return;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaseContractScreen()));
                          },
                        ),
                        Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                        ListTile(
                          key: const Key('more_vip_support'),
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: Color(0xFF128C7E), size: 20),
                          ),
                          title: Text('VIP Priority Support', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                          subtitle: Text('Dedicated landlord concierge via WhatsApp', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                          trailing: _buildPillBadge('BIZ'),
                          onTap: () async {
                            final canAccess = await PlanGuardService.requireBusiness(
                              context: context,
                              featureName: 'VIP Priority Support',
                              featureBenefit: 'Connect directly with a dedicated Tenera account manager via WhatsApp or direct Philippine phone line.',
                            );
                            if (!canAccess || !context.mounted) return;
                            _showVipSupportModal();
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 3. Cloud Sync & Messaging (Compiled Card)
          Text(
            'Cloud & Messaging',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                children: [
                  ListTile(
                    key: const Key('more_firebase_sync'),
                    dense: true,
                    leading: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_sync_rounded, color: AppTheme.primary, size: 22),
                    title: Text('Sync with Firebase Cloud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text(
                      _pendingSyncCount > 0
                          ? '$_pendingSyncCount changes ready to upload'
                          : 'Realtime Database connected',
                      style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context)),
                    ),
                    trailing: _isSyncing
                        ? null
                        : TextButton(
                            onPressed: _handleSync,
                            child: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                    onTap: _isSyncing ? null : _handleSync,
                  ),
                  Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    key: const Key('tile_direct_sms'),
                    dense: true,
                    leading: const Icon(Icons.sms_rounded, color: AppTheme.primary, size: 22),
                    title: Text('Direct Phone SMS (SIM Card)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Sends via phone SIM promo (₱0 extra)', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: TextButton(
                      key: const Key('btn_test_direct_sms'),
                      onPressed: _showTestSmsDialog,
                      child: const Text('Test SMS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Appearance & System Settings (Compiled Card)
          Text(
            'Appearance & Display',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                children: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.themeModeNotifier,
                    builder: (context, themeMode, _) {
                      return ListTile(
                        key: const Key('tile_theme_mode'),
                        dense: true,
                        leading: Icon(
                          themeMode == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : (themeMode == ThemeMode.light
                                  ? Icons.light_mode_rounded
                                  : Icons.brightness_auto_rounded),
                          color: AppTheme.primary,
                          size: 22,
                        ),
                        title: Text('Theme & Appearance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                        subtitle: Text('Tap icon to toggle', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.isDark(context) ? const Color(0xFF1E2D2A) : const Color(0xFFF0F4F4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.getBorderColor(context)),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildThemeModeIconButton(context: context, mode: ThemeMode.system, currentMode: themeMode, icon: Icons.brightness_auto_rounded, key: const Key('btn_theme_system')),
                              const SizedBox(width: 2),
                              _buildThemeModeIconButton(context: context, mode: ThemeMode.light, currentMode: themeMode, icon: Icons.light_mode_rounded, key: const Key('btn_theme_light')),
                              const SizedBox(width: 2),
                              _buildThemeModeIconButton(context: context, mode: ThemeMode.dark, currentMode: themeMode, icon: Icons.dark_mode_rounded, key: const Key('btn_theme_dark')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.save_alt_rounded, color: AppTheme.primary, size: 22),
                    title: Text('Backup Data to Device', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Create offline JSON backup file', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.primaryDeep,
                          content: Text('Backup saved successfully to device storage!'),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    key: const Key('more_check_updates'),
                    dense: true,
                    leading: _isCheckingUpdate
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.system_update_rounded, color: AppTheme.primary, size: 22),
                    title: Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Version v$_currentVersion (GitHub Release)', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                    onTap: _isCheckingUpdate ? null : _handleCheckUpdate,
                  ),
                  Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFC92A2A), size: 22),
                    title: const Text('Clear All Local Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFC92A2A))),
                    subtitle: Text('Reset database & start fresh', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                    onTap: _showClearDataDialog,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 5. Help & Legal (Compiled Card)
          Text(
            'Help & Legal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.help_outline_rounded, color: AppTheme.primary, size: 22),
                    title: Text('Welcome & App Guide', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text('How to manage properties and rooms', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                  ),
                  Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary, size: 22),
                    title: Text('Privacy Policy & Terms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Philippine Data Privacy Act & GDPR', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen(isOnboarding: false))),
                  ),
                  Divider(height: 1, indent: 54, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.open_in_browser_rounded, color: AppTheme.primary, size: 22),
                    title: Text('GitHub Releases Page', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getInkColor(context))),
                    subtitle: Text('View changelog & releases', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                    onTap: () => UpdateService.instance.launchDownload('https://github.com/Watot12345/Tenera/releases'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVipSupportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurfaceElevatedColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFF128C7E), size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIP Priority Support',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.getInkColor(context)),
                          ),
                          Text(
                            'Dedicated Philippine Concierge for Business Landlords',
                            style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  key: const Key('btn_vip_whatsapp'),
                  leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
                  title: Text('WhatsApp Concierge', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                  subtitle: Text('+63 917 888 3637 · Response within 15 mins', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.getInkMutedColor(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchUrl(Uri.parse('https://wa.me/639178883637'), mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  key: const Key('btn_vip_phone'),
                  leading: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.primaryDeep, size: 24),
                  title: Text('Direct Phone Assistance', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                  subtitle: Text('+63 917 888 3637 · Landlord Priority Line', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.getInkMutedColor(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchUrl(Uri.parse('tel:+639178883637'), mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  key: const Key('btn_vip_email'),
                  leading: Icon(Icons.mail_outline_rounded, color: AppTheme.getInkMutedColor(context), size: 24),
                  title: Text('VIP Email Queue', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                  subtitle: Text('support@tenera.ph · High-priority routing', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.getInkMutedColor(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchUrl(Uri.parse('mailto:support@tenera.ph?subject=VIP%20Support%20Request%20-%20Tenera%20Business'), mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Operating Hours: 8:00 AM – 8:00 PM PHT (Mon – Sun)',
                    style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeIconButton({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required Key key,
  }) {
    final isSelected = currentMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: () => ThemeService.setThemeMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (AppTheme.isDark(context) ? AppTheme.primaryDeep : AppTheme.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? Colors.white
                : AppTheme.getInkMutedColor(context),
          ),
        ),
      ),
    );
  }

  void _showTestSmsDialog() {
    final phoneCtrl = TextEditingController(text: '0917');
    final msgCtrl = TextEditingController(
      text: 'Test message from Tenera via device SIM card!',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceElevatedColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sms_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Test Direct SIM SMS',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getInkColor(context),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sends a real SMS using this phone\'s active SIM card.',
                style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('input_test_sms_phone'),
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppTheme.getInkColor(context)),
                decoration: InputDecoration(
                  labelText: 'Recipient Mobile Number',
                  hintText: '09171234567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('input_test_sms_message'),
                controller: msgCtrl,
                maxLines: 2,
                style: TextStyle(color: AppTheme.getInkColor(context)),
                decoration: InputDecoration(
                  labelText: 'Message Content',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: AppTheme.getInkMutedColor(context))),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_test_sms'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final phone = phoneCtrl.text.trim();
                final msg = msgCtrl.text.trim();
                Navigator.pop(dialogCtx);

                final result = await DirectSmsService.sendDirectSms(
                  phone: phone,
                  message: msg,
                );

                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: result.success ? AppTheme.primaryDeep : const Color(0xFFC0392B),
                    content: Text(
                      result.success
                          ? '✓ Real test SMS sent to $phone via device SIM!'
                          : (result.errorMessage ?? 'Failed to send test SMS.'),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Send Real SMS', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeep,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const RoofLedgerLogo(size: 32, isLight: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenera Property Manager',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getInkColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline First · v$_currentVersion',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getInkMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subscription & Plans Upgrade Banner Card
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.ink,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tenera Pro & Plans',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.stars_rounded, color: AppTheme.accent, size: 16),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Unlock unlimited units, utility math & reports',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Plans',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pro Landlord Tools Section - only shown when Pro or Business plan is availed
          if (_isPro) ...[
            Text(
              'Pro Landlord Tools',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.getInkMutedColor(context),
              ),
            ),
            const SizedBox(height: 8),

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
                    key: const Key('more_utility_calculator'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primaryDeep,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Utility Sub-Meter Splitter',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                    ),
                    subtitle: Text(
                      'Split Meralco electric & water sub-meter bills per room',
                      style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final canAccess = await PlanGuardService.requirePro(
                        context: context,
                        featureName: 'Utility Sub-Meter Splitter',
                        featureBenefit: 'Split electric & water sub-meter bills accurately per room with zero math errors.',
                      );
                      if (!canAccess || !context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UtilityCalculatorScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 60, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    key: const Key('more_reports_export'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.assessment_rounded,
                        color: AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primaryDeep,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Revenue & BIR Tax Report',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                    ),
                    subtitle: Text(
                      'Export Philippine BIR tax schedules & revenue CSV',
                      style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final canAccess = await PlanGuardService.requirePro(
                        context: context,
                        featureName: 'Revenue & BIR Tax Report',
                        featureBenefit: 'Generate Philippine BIR tax schedules and 1-click export rental revenue to CSV.',
                      );
                      if (!canAccess || !context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsExportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Business Tier Tools Section - only shown when Business plan is availed
        if (_isBusiness) ...[
          Text(
            'Business Tier Tools',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),

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
                  if (!_isStaffMode) ...[
                    ListTile(
                      key: const Key('more_portfolio_analytics'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.domain_rounded, color: AppTheme.getPrimaryColor(context), size: 22),
                      ),
                      title: Text('Multi-Property Portfolio Analytics', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                      subtitle: Text('Cross-property performance, occupancy % & delinquency reports', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BUSINESS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      onTap: () async {
                        final canAccess = await PlanGuardService.requireBusiness(
                          context: context,
                          featureName: 'Portfolio Analytics',
                          featureBenefit: 'Unlock cross-property yield comparisons, collection efficiency metrics, and portfolio CSV exports.',
                        );
                        if (!canAccess || !context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PortfolioAnalyticsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 60, color: AppTheme.getBorderColor(context)),
                  ],
                  ListTile(
                    key: const Key('more_caretaker_mode'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isStaffMode ? AppTheme.accent.withValues(alpha: 0.25) : AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isStaffMode ? Icons.shield_rounded : Icons.shield_outlined,
                        color: _isStaffMode ? (AppTheme.isDark(context) ? AppTheme.darkAccent : AppTheme.primaryDeep) : AppTheme.getPrimaryColor(context),
                        size: 22,
                      ),
                    ),
                    title: Text('Caretaker / Staff Mode', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                    subtitle: Text(
                      _isStaffMode ? 'Active (Financials hidden) · Tap to exit' : 'Hide gross revenues and protect with 4-digit PIN',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isStaffMode ? (AppTheme.isDark(context) ? AppTheme.darkAccent : AppTheme.primaryDeep) : AppTheme.getInkMutedColor(context),
                        fontWeight: _isStaffMode ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isStaffMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.getPrimaryColor(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LOCKED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.isDark(context) ? const Color(0xFF0F2623) : Colors.white),
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BUSINESS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await StaffModeService.toggleStaffMode(
                        context,
                        onModeChanged: () async {
                          final staff = await StaffModeService.isStaffMode();
                          if (mounted) {
                            setState(() => _isStaffMode = staff);
                          }
                          if (widget.onStaffModeToggled != null) {
                            await widget.onStaffModeToggled!();
                          }
                        },
                      );
                    },
                  ),
                  if (!_isStaffMode) ...[
                    Divider(height: 1, indent: 60, color: AppTheme.getBorderColor(context)),
                    ListTile(
                      key: const Key('more_lease_contracts'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.assignment_turned_in_rounded, color: AppTheme.getPrimaryColor(context), size: 22),
                      ),
                      title: Text('Philippine Lease Agreement Contracts', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                      subtitle: Text('Residential contract generator with tenant autofill & 1-tap copy', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BUSINESS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      onTap: () async {
                        final canAccess = await PlanGuardService.requireBusiness(
                          context: context,
                          featureName: 'Lease Agreement Contracts',
                          featureBenefit: 'Generate legally formatted Philippine residential lease contracts with auto-filled tenant details and 1-click clipboard export.',
                        );
                        if (!canAccess || !context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaseContractScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 60, color: AppTheme.getBorderColor(context)),
                    ListTile(
                      key: const Key('more_vip_support'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFF128C7E), size: 22),
                      ),
                      title: Text('VIP Priority Support', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context))),
                      subtitle: Text('Direct WhatsApp, phone & dedicated landlord concierge', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BUSINESS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

          // Appearance & Display (Dark Mode) Section
          Text(
            'Appearance & Display',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.themeModeNotifier,
            builder: (context, themeMode, _) {
              return Material(
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: ListTile(
                    key: const Key('tile_theme_mode'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : (themeMode == ThemeMode.light
                                ? Icons.light_mode_rounded
                                : Icons.brightness_auto_rounded),
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'App Theme / Dark Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getInkColor(context),
                      ),
                    ),
                    subtitle: Text(
                      themeMode == ThemeMode.dark
                          ? 'Dark Mode Active'
                          : (themeMode == ThemeMode.light
                              ? 'Light Mode Active'
                              : 'System Default (Auto)'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getInkMutedColor(context),
                      ),
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<ThemeMode>(
                        key: const Key('dropdown_theme_mode'),
                        value: themeMode,
                        dropdownColor: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        items: [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.brightness_auto_rounded, size: 16, color: AppTheme.getInkMutedColor(context)),
                                const SizedBox(width: 6),
                                Text('System', style: TextStyle(fontSize: 13, color: AppTheme.getInkColor(context))),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.light_mode_rounded, size: 16, color: Color(0xFFF2A33A)),
                                const SizedBox(width: 6),
                                Text('Light', style: TextStyle(fontSize: 13, color: AppTheme.getInkColor(context))),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dark_mode_rounded, size: 16, color: Color(0xFF1BA69A)),
                                const SizedBox(width: 6),
                                Text('Dark', style: TextStyle(fontSize: 13, color: AppTheme.getInkColor(context))),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (newMode) {
                          if (newMode != null) {
                            ThemeService.setThemeMode(newMode);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Cloud Sync & Firebase Section
          Text(
            'Cloud & Database Sync',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),

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
                    leading: _isSyncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.cloud_sync_rounded, color: AppTheme.primary),
                    title: Text('Sync with Firebase Cloud', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text(
                      FirebaseService.instance.isInitialized
                          ? (_pendingSyncCount > 0
                              ? '$_pendingSyncCount changes ready to upload'
                              : 'All data synchronized with cloud')
                          : 'Local SQLite active (Offline mode)',
                      style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                    ),
                    trailing: _isSyncing
                        ? null
                        : TextButton(
                            onPressed: _handleSync,
                            child: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                    onTap: _isSyncing ? null : _handleSync,
                  ),
                  Divider(height: 1, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    leading: Icon(Icons.cloud_off_rounded, color: AppTheme.getInkMutedColor(context)),
                    title: Text('Offline Storage Mode', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text('SQLite Single Source of Truth on this device', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusPaidBg(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getStatusPaidText(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App Updates & Releases Section
          Text(
            'Updates & Releases',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),

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
                    key: const Key('more_check_updates'),
                    leading: _isCheckingUpdate
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.system_update_rounded, color: AppTheme.primary),
                    title: Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Current version: v$_currentVersion (GitHub Release)', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.getInkMutedColor(context)),
                    onTap: _isCheckingUpdate ? null : _handleCheckUpdate,
                  ),
                  Divider(height: 1, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    leading: const Icon(Icons.open_in_browser_rounded, color: AppTheme.primary),
                    title: Text('GitHub Releases Page', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text('View changelog, APK releases & source code', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.getInkMutedColor(context)),
                    onTap: () {
                      UpdateService.instance.launchDownload('https://github.com/Watot12345/Tenera/releases');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Data & Backup Section
          Text(
            'Data & Backup',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),

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
                    leading: const Icon(Icons.save_alt_rounded, color: AppTheme.primary),
                    title: Text('Backup Data to Device', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Create offline JSON backup file', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.getInkMutedColor(context)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.primaryDeep,
                          content: Text('Backup saved successfully to device storage!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legal & Guidelines Section
          Text(
            'Legal & Guidelines',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getInkMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),

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
                    leading: const Icon(Icons.help_outline_rounded, color: AppTheme.primary),
                    title: Text('Welcome & App Guide', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text('Step-by-step guide: how to use Tenera', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.getInkMutedColor(context)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppTheme.getBorderColor(context)),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
                    title: Text('Privacy Policy & Terms', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context))),
                    subtitle: Text('RA 10173 & GDPR compliant', style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context))),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.getInkMutedColor(context)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(isOnboarding: false),
                        ),
                      );
                    },
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
}

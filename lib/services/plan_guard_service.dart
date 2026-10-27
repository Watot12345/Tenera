import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/subscription_plans_screen.dart';
import '../theme/app_theme.dart';

class PlanGuardService {
  static const int starterUnitLimit = 15;

  /// Returns true if the user has an active Tenera Pro or Business subscription.
  static Future<bool> isPro() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString(SubscriptionPlansScreen.prefKeyCurrentPlan) ?? 'starter';
    return plan == 'pro' || plan == 'business';
  }

  /// Returns true if the user can add the requested number of units.
  /// Starter plan (and Starter trial) supports up to 15 units.
  /// 16+ units requires Tenera Pro.
  static Future<bool> canAddUnits({
    required BuildContext context,
    required int currentTotalUnits,
    int incomingUnits = 1,
  }) async {
    final hasPro = await isPro();
    if (hasPro) {
      return true;
    }

    // Starter limit check (15 units max)
    if (currentTotalUnits + incomingUnits > starterUnitLimit) {
      if (!context.mounted) return false;
      showUpgradeDialog(
        context: context,
        currentUnits: currentTotalUnits,
        attemptedUnits: incomingUnits,
      );
      return false;
    }

    return true;
  }

  /// Guards a Pro-only feature (e.g. Utility Splitter, BIR Tax Export).
  /// If the landlord is not subscribed to Tenera Pro, displays an upgrade modal and returns false.
  static Future<bool> requirePro({
    required BuildContext context,
    required String featureName,
    required String featureBenefit,
  }) async {
    final hasPro = await isPro();
    if (hasPro) return true;

    if (!context.mounted) return false;
    showProUpgradeDialog(
      context: context,
      featureName: featureName,
      featureBenefit: featureBenefit,
    );
    return false;
  }

  /// Displays the Starter plan 15-unit limit upgrade dialog
  static Future<void> showUpgradeDialog({
    required BuildContext context,
    required int currentUnits,
    int attemptedUnits = 1,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.primaryDeep,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Starter Plan Limit Reached',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Current Units: $currentUnits / $starterUnitLimit Max',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDeep,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'The Starter Plan supports up to 15 rental units. Upgrade to Tenera Pro for unlimited properties, rooms, BIR tax schedules, and sub-meter splitters.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('btn_upgrade_to_pro_modal'),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text(
                    'Upgrade to Tenera Pro',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Displays the Pro Upgrade dialog when accessing a Pro tool
  static Future<void> showProUpgradeDialog({
    required BuildContext context,
    required String featureName,
    required String featureBenefit,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDeep, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      featureName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                ],
              ),
              const SizedBox(height: 10),
              Text(
                featureBenefit,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: AppTheme.primaryDeep, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This tool is exclusive to Tenera Pro subscribers (₱199/month). Upgrade to unlock.',
                        style: TextStyle(fontSize: 11, color: AppTheme.ink, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('btn_upgrade_pro_feature_modal'),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text(
                    'Upgrade to Tenera Pro',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

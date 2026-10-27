import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/subscription_plans_screen.dart';
import '../theme/app_theme.dart';

class PlanGuardService {
  static const int starterUnitLimit = 15;

  /// Returns true if the user can add the requested number of units.
  /// If the Starter limit is exceeded and no trial or Pro plan is active,
  /// displays an upgrade dialog and returns false.
  static Future<bool> canAddUnits({
    required BuildContext context,
    required int currentTotalUnits,
    int incomingUnits = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString(SubscriptionPlansScreen.prefKeyCurrentPlan) ?? 'starter';

    // Pro or Business subscribers enjoy unlimited units
    if (plan == 'pro' || plan == 'business') {
      return true;
    }

    // Check if 14-day free trial is currently active
    var trialStartStr = prefs.getString(SubscriptionPlansScreen.prefKeyTrialStartDate);
    if (trialStartStr == null) {
      trialStartStr = DateTime.now().toIso8601String();
      await prefs.setString(SubscriptionPlansScreen.prefKeyTrialStartDate, trialStartStr);
      return true;
    }

    final trialDate = DateTime.tryParse(trialStartStr);
    if (trialDate != null && DateTime.now().difference(trialDate).inDays < 14) {
      return true;
    }

    // Check if adding incomingUnits would exceed Starter limit
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

  /// Displays the Starter plan unit limit upgrade dialog
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
}

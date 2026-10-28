import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/trial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/roof_ledger_logo.dart';
import 'home_screen.dart';

/// Full-screen unbypassable paywall displayed when the 14-day free trial has expired.
/// - Back navigation is completely disabled (canPop: false).
/// - Landlords can view plans, toggle annual/monthly, and activate immediately to unlock.
class TrialExpiredScreen extends StatefulWidget {
  const TrialExpiredScreen({super.key});

  @override
  State<TrialExpiredScreen> createState() => _TrialExpiredScreenState();
}

class _TrialExpiredScreenState extends State<TrialExpiredScreen> {
  bool _isAnnual = true;
  bool _isActivating = false;

  void _showCheckoutDialog(String planTitle, String planId, String priceText) {
    String selectedMethod = 'GCash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.lock_open_rounded, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlock Tenera: $planTitle',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                              Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodOption(
                      title: 'GCash e-Wallet',
                      subtitle: 'Fast 1-tap Philippine e-wallet',
                      icon: Icons.account_balance_wallet_rounded,
                      value: 'GCash',
                      groupValue: selectedMethod,
                      onChanged: (val) => setModalState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodOption(
                      title: 'Maya e-Wallet',
                      subtitle: 'Instant Maya QR or wallet payment',
                      icon: Icons.credit_card_rounded,
                      value: 'Maya',
                      groupValue: selectedMethod,
                      onChanged: (val) => setModalState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodOption(
                      title: 'Bank Transfer / OTC',
                      subtitle: 'BDO, BPI, UnionBank, or 7-Eleven',
                      icon: Icons.account_balance_rounded,
                      value: 'Bank',
                      groupValue: selectedMethod,
                      onChanged: (val) => setModalState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('btn_confirm_trial_unlock'),
                        onPressed: _isActivating
                            ? null
                            : () async {
                                Navigator.pop(modalCtx);
                                setState(() => _isActivating = true);
                                await TrialService.markSubscriptionPaid(planId);
                                await AdService.refreshAdStatus();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.primaryDeep,
                                    duration: const Duration(seconds: 3),
                                    content: Text('🎉 Congratulations! $planTitle activated. Tenera is now unlocked!'),
                                  ),
                                );

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (route) => false,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Confirm & Unlock with $selectedMethod',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.inkMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppTheme.primary : AppTheme.inkMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopScope prevents Android back button or gesture navigation from bypassing paywall
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Lock Badge + Logo
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const RoofLedgerLogo(size: 64),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusOverdue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '14-Day Free Trial Ended',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your properties, rooms, tenants, and payment records are 100% safe. Choose a plan to unlock Tenera and continue managing your rentals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.inkMuted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),

                // Annual vs Monthly Billing Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isAnnual = false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isAnnual ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Monthly Billing',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !_isAnnual ? Colors.white : AppTheme.inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isAnnual = true),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isAnnual ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Annual Plan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isAnnual ? Colors.white : AppTheme.inkMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isAnnual ? AppTheme.accent : AppTheme.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'SAVE 33%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: _isAnnual ? AppTheme.primaryDeep : AppTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Featured Plan: Pro
                _buildPlanCard(
                  title: 'Tenera Pro',
                  subtitle: 'Most popular for landlords managing up to 3 properties',
                  price: _isAnnual ? '₱1,499' : '₱199',
                  period: _isAnnual ? '/ year (only ₱125/mo)' : '/ month',
                  badge: 'LANDLORD CHOICE',
                  isFeatured: true,
                  features: const [
                    '100% Ad-Free Experience',
                    'Up to 3 Properties (Unlimited Units)',
                    'Electric & Water Sub-Meter Splitter',
                    '1-Tap Polite SMS & Messenger Reminders',
                    'Works 100% Offline Anywhere',
                  ],
                  buttonKey: 'btn_unlock_pro',
                  onSelect: () => _showCheckoutDialog(
                    'Tenera Pro',
                    'pro',
                    _isAnnual ? '₱1,499 / year' : '₱199 / month',
                  ),
                ),
                const SizedBox(height: 16),

                // Plan 1: Starter
                _buildPlanCard(
                  title: 'Starter Plan',
                  subtitle: 'Ideal for 1 property with up to 15 units',
                  price: _isAnnual ? '₱399' : '₱49',
                  period: _isAnnual ? '/ year (only ₱33/mo)' : '/ month',
                  isFeatured: false,
                  features: const [
                    '1 Property (Up to 15 Units & Tenants)',
                    'Offline Local Device SQLite Ledger',
                    'Visual Room Grid & Overdue Alerts',
                    'GCash / Bank Reference Tracking',
                  ],
                  buttonKey: 'btn_unlock_starter',
                  onSelect: () => _showCheckoutDialog(
                    'Starter Plan',
                    'starter',
                    _isAnnual ? '₱399 / year' : '₱49 / month',
                  ),
                ),
                const SizedBox(height: 16),

                // Plan 3: Business
                _buildPlanCard(
                  title: 'Business Plan',
                  subtitle: 'For dorm chains & commercial portfolios (unlimited properties)',
                  price: _isAnnual ? '₱3,999' : '₱499',
                  period: _isAnnual ? '/ year (only ₱333/mo)' : '/ month',
                  badge: 'UNLIMITED',
                  isFeatured: false,
                  features: const [
                    '100% Ad-Free Experience',
                    'Unlimited Properties & Units',
                    'Multi-Property Portfolio Analytics',
                    'Caretaker / Staff Mode',
                    'Printable Lease Agreement Contracts',
                  ],
                  buttonKey: 'btn_unlock_business',
                  onSelect: () => _showCheckoutDialog(
                    'Business Plan',
                    'business',
                    _isAnnual ? '₱3,999 / year' : '₱499 / month',
                  ),
                ),
                const SizedBox(height: 24),

                // Restore Purchase / Refresh Check
                TextButton.icon(
                  onPressed: () async {
                    setState(() => _isActivating = true);
                    final expired = await TrialService.isTrialExpired();
                    if (!mounted) return;
                    setState(() => _isActivating = false);

                    if (!expired) {
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No active subscription found. Please select a plan to unlock.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Already Paid? Restore Subscription'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? badge,
    required bool isFeatured,
    required List<String> features,
    required String buttonKey,
    required VoidCallback onSelect,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFeatured ? AppTheme.accent : AppTheme.border,
          width: isFeatured ? 2.0 : 1.0,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isFeatured ? AppTheme.accent : AppTheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isFeatured ? AppTheme.primaryDeep : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          period,
                          style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.statusPaid),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(fontSize: 12, color: AppTheme.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: Key(buttonKey),
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFeatured ? AppTheme.accent : AppTheme.primary,
                      foregroundColor: isFeatured ? AppTheme.primaryDeep : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Choose $title',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

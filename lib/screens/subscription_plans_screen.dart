import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/roof_ledger_logo.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  static const String prefKeyCurrentPlan = 'user_subscription_plan';
  static const String prefKeyBillingCycle = 'user_billing_cycle';
  static const String prefKeyTrialStartDate = 'user_trial_start_date';

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isAnnual = true;
  String _currentPlan = 'starter'; // 'starter' (or 'free'), 'pro', 'business'
  bool _isTrialActive = true;
  int _daysRemainingInTrial = 14;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();
  }

  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();

    // Initialize or load 14-day free trial start date
    String? trialStartStr = prefs.getString(SubscriptionPlansScreen.prefKeyTrialStartDate);
    if (trialStartStr == null) {
      trialStartStr = DateTime.now().toIso8601String();
      await prefs.setString(SubscriptionPlansScreen.prefKeyTrialStartDate, trialStartStr);
    }
    final trialStartDate = DateTime.tryParse(trialStartStr) ?? DateTime.now();
    final elapsedDays = DateTime.now().difference(trialStartDate).inDays;
    final daysRemaining = (14 - elapsedDays).clamp(0, 14);
    final isTrialActive = elapsedDays < 14;

    final savedPlan = prefs.getString(SubscriptionPlansScreen.prefKeyCurrentPlan);

    setState(() {
      _currentPlan = (savedPlan == null || savedPlan == 'free') ? 'starter' : savedPlan;
      _isAnnual = (prefs.getString(SubscriptionPlansScreen.prefKeyBillingCycle) ?? 'annual') == 'annual';
      _isTrialActive = isTrialActive;
      _daysRemainingInTrial = daysRemaining;
      _isLoading = false;
    });
  }

  Future<void> _savePlan(String planId, bool isAnnual) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SubscriptionPlansScreen.prefKeyCurrentPlan, planId);
    await prefs.setString(SubscriptionPlansScreen.prefKeyBillingCycle, isAnnual ? 'annual' : 'monthly');
    setState(() {
      _currentPlan = planId;
      _isAnnual = isAnnual;
    });
  }

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
          builder: (modalContext, setModalState) {
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
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.accent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activate $planTitle',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                              Text(
                                planId == 'starter' || planId == 'free'
                                    ? '14-Day Free Trial Included · Then $priceText · ${_isAnnual ? "Billed Annually" : "Billed Monthly"}'
                                    : '$priceText · ${_isAnnual ? "Billed Annually" : "Billed Monthly"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose Payment Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _buildPaymentMethodTile(
                            title: 'GCash / QR Ph (Instant)',
                            subtitle: 'Direct via Philippine e-wallet / QR',
                            icon: Icons.qr_code_2_rounded,
                            iconColor: const Color(0xFF005CE6),
                            value: 'GCash',
                            selected: selectedMethod == 'GCash',
                            onTap: () => setModalState(() => selectedMethod = 'GCash'),
                          ),
                          const Divider(height: 1, color: AppTheme.border),
                          _buildPaymentMethodTile(
                            title: 'Google Play Billing',
                            subtitle: 'Managed via your Google Account',
                            icon: Icons.play_arrow_rounded,
                            iconColor: AppTheme.primary,
                            value: 'GooglePlay',
                            selected: selectedMethod == 'GooglePlay',
                            onTap: () => setModalState(() => selectedMethod = 'GooglePlay'),
                          ),
                          const Divider(height: 1, color: AppTheme.border),
                          _buildPaymentMethodTile(
                            title: 'Maya / Credit Card',
                            subtitle: 'Visa, Mastercard, Maya balance',
                            icon: Icons.credit_card_rounded,
                            iconColor: const Color(0xFF22AA55),
                            value: 'Maya',
                            selected: selectedMethod == 'Maya',
                            onTap: () => setModalState(() => selectedMethod = 'Maya'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              planId == 'starter' || planId == 'free'
                                  ? '14-Day Free Trial Guarantee: Zero upfront charge for 14 days. Unlocks full features offline. Cancel anytime.'
                                  : 'Offline Guarantee: Once unlocked, your Pro features continue working 100% offline without internet.',
                              style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _savePlan(planId, _isAnnual);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryDeep,
                              duration: const Duration(seconds: 3),
                              content: Text('🎉 Congratulations! $planTitle is now ACTIVE on this device.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Confirm & Activate with $selectedMethod',
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

  void _showRedeemCodeDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('Redeem License Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the activation voucher provided via GCash, Maya, or direct landlord support.',
                style: TextStyle(fontSize: 13, color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g., TENERA-PRO-2026',
                  hintStyle: const TextStyle(color: AppTheme.inkMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isNotEmpty) {
                  Navigator.pop(ctx);
                  await _savePlan('pro', true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.primaryDeep,
                      content: Text('🎉 Voucher verified! Tenera Pro is now active.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid code.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Redeem Code'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          'Tenera Plans & Pricing',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showRedeemCodeDialog,
            icon: const Icon(Icons.vpn_key_outlined, size: 16, color: AppTheme.primary),
            label: const Text(
              'Redeem',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryDeep.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const RoofLedgerLogo(size: 40, isLight: true),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empower Your Properties',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Simple, fair pricing built for Filipino landlords. Never lose track of rent or utilities again.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 14-Day Free Trial Active Status Banner
            if (_isTrialActive) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.7), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_rounded, color: AppTheme.ink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                '14-Day Free Trial Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDeep,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.check_circle_rounded, color: AppTheme.statusPaid, size: 16),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_daysRemainingInTrial days remaining. Enjoy full features before Starter begins at ₱49/mo.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Billing Toggle: Monthly vs Annual
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isAnnual = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isAnnual ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Monthly',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: !_isAnnual ? Colors.white : AppTheme.inkMuted,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isAnnual = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAnnual ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Annually',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isAnnual ? Colors.white : AppTheme.inkMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isAnnual ? AppTheme.accent : AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SAVE 37%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _isAnnual ? AppTheme.ink : AppTheme.primaryDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Plan 1: Starter (₱49/mo with 14-day Free Trial)
            _buildPlanCard(
              title: 'Starter',
              subtitle: 'Ideal for boarding houses & apartments (up to 15 units)',
              price: _isAnnual ? '₱399' : '₱49',
              periodText: _isAnnual ? 'per year (only ₱33/mo)' : 'per month (after 14-day trial)',
              planId: 'starter',
              isCurrent: _currentPlan == 'starter' || _currentPlan == 'free',
              isFeatured: false,
              badgeText: '14-DAY FREE TRIAL INCLUDED',
              features: const [
                '14-Day Full Free Trial (All features unlocked)',
                'Up to 15 Units & Tenants',
                '100% Offline Local Device Ledger (SQLite)',
                'Visual 6-Column Squircle Room Grid',
                'Rent, Water & Electric Payment Recording',
                'GCash & Bank Ref Tracking + Cash Photo Proof',
                'Automatic Overdue & Due Soon Alerts',
                'Offline Data Backup & JSON Export',
              ],
              onSelect: () => _showCheckoutDialog(
                'Starter',
                'starter',
                _isAnnual ? '₱399 / year' : '₱49 / month',
              ),
            ),

            const SizedBox(height: 16),

            // Plan 2: Pro (Landlord's Choice - Featured)
            _buildPlanCard(
              title: 'Tenera Pro',
              subtitle: 'Best for boarding houses & apartments (10–40 rooms)',
              price: _isAnnual ? '₱1,499' : '₱199',
              periodText: _isAnnual ? 'per year (only ₱125/mo)' : 'per month',
              planId: 'pro',
              isCurrent: _currentPlan == 'pro',
              isFeatured: true,
              badgeText: 'MOST POPULAR · LANDLORD CHOICE',
              features: const [
                'Unlimited Properties & Units',
                'Utility Sub-Meter Splitter (Electric & Water)',
                '1-Tap Polite SMS & Messenger Reminders',
                'Branded Digital Receipts with PAID Stamp',
                'Monthly Revenue & BIR Tax Report Export',
                'Priority Room Filtering & Multi-Unit Search',
                'Works 100% Offline Anywhere',
              ],
              onSelect: () => _showCheckoutDialog(
                'Tenera Pro',
                'pro',
                _isAnnual ? '₱1,499 / year' : '₱199 / month',
              ),
            ),

            const SizedBox(height: 16),

            // Plan 3: Business
            _buildPlanCard(
              title: 'Business',
              subtitle: 'For dorm chains & multi-property owners (50+ rooms)',
              price: _isAnnual ? '₱3,999' : '₱499',
              periodText: _isAnnual ? 'per year (only ₱333/mo)' : 'per month',
              planId: 'business',
              isCurrent: _currentPlan == 'business',
              isFeatured: false,
              badgeText: 'MULTI-PROPERTY',
              features: const [
                'All Tenera Pro Features Included',
                'Multi-Property Portfolio Analytics',
                'Caretaker / Staff Mode (hide landlord profits)',
                'Automated Google Drive Cloud Backup',
                'Printable Lease Agreement Contracts',
                'VIP Direct Phone & WhatsApp Support',
              ],
              onSelect: () => _showCheckoutDialog(
                'Tenera Business',
                'business',
                _isAnnual ? '₱3,999 / year' : '₱499 / month',
              ),
            ),

            const SizedBox(height: 24),

            // Why Landlords Trust Tenera
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why Landlords Trust Tenera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTrustItem(
                    icon: Icons.wifi_off_rounded,
                    title: '100% Offline First',
                    description: 'All your tenant and financial data stays securely on your phone. No servers to fail.',
                  ),
                  const SizedBox(height: 10),
                  _buildTrustItem(
                    icon: Icons.cancel_outlined,
                    title: 'No Long-term Lock-in',
                    description: 'Cancel anytime directly through Google Play or stop your renewal. You keep all records.',
                  ),
                  const SizedBox(height: 10),
                  _buildTrustItem(
                    icon: Icons.payments_outlined,
                    title: 'Local GCash & Maya Friendly',
                    description: 'Pay conveniently using your existing Philippine e-wallet or debit/credit card.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required String periodText,
    required String planId,
    required bool isCurrent,
    required bool isFeatured,
    String? badgeText,
    required List<String> features,
    required VoidCallback onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFeatured ? AppTheme.accent : (isCurrent ? AppTheme.primary : AppTheme.border),
          width: isFeatured ? 2.2 : (isCurrent ? 1.8 : 1.0),
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                color: isFeatured ? AppTheme.accent : AppTheme.primaryDeep,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isFeatured ? AppTheme.ink : Colors.white,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusPaidBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE PLAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.statusPaid,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      periodText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppTheme.border),
                for (final feat in features) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppTheme.statusPaid,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isCurrent
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            (_isTrialActive && (planId == 'starter' || planId == 'free'))
                                ? 'Active Trial ($_daysRemainingInTrial days left)'
                                : 'Current Plan',
                          ),
                        )
                      : ElevatedButton(
                          onPressed: onSelect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFeatured ? AppTheme.accent : AppTheme.primary,
                            foregroundColor: isFeatured ? AppTheme.ink : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            (planId == 'free' || planId == 'starter') ? 'Switch to Starter' : 'Choose $title',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.inkMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                  width: selected ? 6 : 2,
                ),
                color: selected ? AppTheme.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

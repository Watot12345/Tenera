import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/roof_ledger_logo.dart';
import 'welcome_screen.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final bool isOnboarding;

  const PrivacyPolicyScreen({
    super.key,
    this.isOnboarding = true,
  });

  static const String prefKeyAccepted = 'has_accepted_privacy_policy';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasAgreed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptAndProceed() async {
    if (!_hasAgreed || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Save acceptance asynchronously in background without blocking screen transition
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(PrivacyPolicyScreen.prefKeyAccepted, true);
      }).catchError((e) {
        debugPrint('SharedPreferences set error: $e');
      });
    } catch (e) {
      debugPrint('SharedPreferences init error: $e');
    }

    if (!mounted) return;

    // Immediately navigate to Welcome onboarding!
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isOnboarding,
        title: const Text(
          'Privacy & Terms',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Use'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPrivacyTab(),
                  _buildTermsTab(),
                ],
              ),
            ),

            // Bottom acceptance bar (only in onboarding mode)
            if (widget.isOnboarding) _buildAcceptanceBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeroHeader(
            title: 'Tenera Privacy Policy',
            subtitle: 'Local-first property management. Your data never leaves your device without your consent.',
            badge: 'Effective: October 2026',
          ),
          const SizedBox(height: 20),

          _buildLegalSection(
            icon: Icons.storage_rounded,
            title: '1. Local-First Data Ownership (RA 10173 & GDPR)',
            paragraphs: [
              'Tenera is built from the ground up as an offline-first mobile application. All properties, rental units, tenant personal details, lease agreements, meter readings, and rent ledgers are stored strictly in an encrypted SQLite database inside your device’s private storage.',
              'We do not harvest, monetize, transmit, or sell your tenant records, payment histories, or property financial data to remote servers or third-party advertisers.',
            ],
          ),

          _buildLegalSection(
            icon: Icons.shield_outlined,
            title: '2. Protection of Tenant & Landlord Data',
            paragraphs: [
              'Tenant privacy is paramount. Diagnostic logging and crash reporting within the application exclude Personally Identifiable Information (PII) such as tenant names, contact numbers, emergency details, and uploaded identification documents.',
              'You retain 100% legal ownership and control over your records at all times.',
            ],
          ),

          _buildLegalSection(
            icon: Icons.phonelink_setup_rounded,
            title: '3. Device Permissions & Purpose',
            paragraphs: [
              '• Storage & Files: Required solely to export PDF receipts, rent summaries, and full SQLite database backup archives to your chosen destinations.',
              '• Camera & Photo Library (Optional): Used only when you choose to take utility meter reading snapshots or attach proof of payment receipts.',
              '• Notifications (Optional): Used exclusively for scheduled local notifications alerting you when rent is due or overdue.',
            ],
          ),

          _buildLegalSection(
            icon: Icons.cloud_off_rounded,
            title: '4. Backup & Data Deletion',
            paragraphs: [
              'You have full control to generate exportable backup archives at any time. If you wish to delete all data, you can reset the database from within app settings or uninstall the app to permanently remove all local records.',
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(
            title: 'Terms of Use',
            subtitle: 'Guidelines and agreement for small landowners and property managers using Tenera.',
            badge: 'Version 1.0',
          ),
          const SizedBox(height: 20),

          _buildLegalSection(
            icon: Icons.handshake_outlined,
            title: '1. App Purpose & License',
            paragraphs: [
              'Tenera is a software tool provided to assist landlords and property managers with recording leases, utility allocations, payments, and arrears.',
              'Tenera is not a banking service, escrow agent, or legal advisor. You are granted a personal, non-exclusive, non-transferable license to use the app for property management.',
            ],
          ),

          _buildLegalSection(
            icon: Icons.account_balance_wallet_outlined,
            title: '2. Financial Accuracy & Ledger Responsibilities',
            paragraphs: [
              'All charges, payment receipts, utility splits, and late fee calculations entered into Tenera are manual or automated records maintained by you.',
              'You are solely responsible for verifying that rent amounts, grace periods, utility allocations, and issued receipts comply with your local rental housing laws and contractual lease agreements.',
            ],
          ),

          _buildLegalSection(
            icon: Icons.security_rounded,
            title: '3. Data Backup Responsibility',
            paragraphs: [
              'Because Tenera operates offline without a cloud backend in its core tier, you are responsible for maintaining regular backups of your records. Tenera is not liable for data loss caused by hardware damage, factory resets, or device theft.',
            ],
          ),

          _buildLegalSection(
            icon: Icons.gavel_rounded,
            title: '4. Limitation of Liability',
            paragraphs: [
              'To the maximum extent permitted by applicable law, Tenera is provided "as is" without warranty of any kind. In no event shall the developer be liable for indirect, incidental, or consequential damages resulting from lost records or landlord-tenant disputes.',
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeroHeader({
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const RoofLedgerLogo(
              size: 38,
              isLight: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.statusPaidBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppTheme.statusPaid,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection({
    required IconData icon,
    required String title,
    required List<String> paragraphs,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                p,
                style: const TextStyle(
                  color: AppTheme.inkMuted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _hasAgreed = !_hasAgreed;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _hasAgreed,
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _hasAgreed = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Tenera Terms of Use & Privacy Policy.',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _hasAgreed && !_isSaving ? _acceptAndProceed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.border,
              disabledForegroundColor: AppTheme.inkMuted,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Text('Accept & Continue'),
          ),
        ],
      ),
    );
  }
}

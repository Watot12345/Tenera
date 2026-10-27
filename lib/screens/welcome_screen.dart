import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/roof_ledger_logo.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _activeCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        centerTitle: false,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoofLedgerLogo(
              size: 28,
              isLight: false,
            ),
            SizedBox(width: 10),
            Text(
              'Tenera App Guide',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.inkMuted),
            tooltip: 'Close Guide',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HOW TO USE TENERA',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Simple Rental Guide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Master room management, rent collections, and receipts in 5 easy steps.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const RoofLedgerLogo(
                        size: 48,
                        isLight: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Rooms & Grid',
                    'Tenants',
                    'Payments',
                    'Reminders',
                    'Offline & Backup',
                  ].map((category) {
                    final isSelected = _activeCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            _activeCategory = category;
                          });
                        },
                        selectedColor: AppTheme.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.ink,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Guide Steps
              if (_activeCategory == 'All' || _activeCategory == 'Rooms & Grid') ...[
                _buildStepCard(
                  stepNumber: '01',
                  stepTitle: 'Manage Properties & Room Grid',
                  icon: Icons.holiday_village_rounded,
                  iconColor: AppTheme.primary,
                  description:
                      'Tap the "Properties" tab to see your total portfolio. Tap "View Rooms" on any property to see its live squircle grid visualizer.',
                  bulletPoints: const [
                    '🟢 Green block: Occupied and paid on time.',
                    '🔴 Red block with (!): Rent is overdue.',
                    '⚪ Dashed border: Unit is vacant and ready to rent.',
                    'Tap "+ Add Room" button to create new units and set monthly rent.',
                  ],
                ),
                const SizedBox(height: 14),
              ],

              if (_activeCategory == 'All' || _activeCategory == 'Tenants') ...[
                _buildStepCard(
                  stepNumber: '02',
                  stepTitle: 'Assigning & Removing Tenants',
                  icon: Icons.people_alt_rounded,
                  iconColor: AppTheme.primary,
                  description:
                      'Tap any vacant room to assign a tenant, or use the "+" button in the Tenants tab to add tenant details and monthly rent.',
                  bulletPoints: const [
                    'Use the search bar in the Tenants tab to find anyone by name, room, or building.',
                    '💡 Press & Hold to Remove: To vacate an occupied unit, press and hold on "Tenant Assigned" or the room block in the grid.',
                    'Confirming in the dialog marks the unit vacant immediately and clears rent arrears.',
                  ],
                  highlightNotice:
                      'Press & Hold gesture prevents accidental tenant deletion while keeping it quick to vacate rooms.',
                ),
                const SizedBox(height: 14),
              ],

              if (_activeCategory == 'All' || _activeCategory == 'Payments') ...[
                _buildStepCard(
                  stepNumber: '03',
                  stepTitle: 'Recording Payments & Receipts',
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppTheme.statusPaid,
                  description:
                      'Whenever a tenant pays cash, GCash, or bank transfer, log it in 1 tap to keep your accounting accurate.',
                  bulletPoints: const [
                    'Tap "+ Record payment" on the Dashboard or on any tenant card.',
                    'Select the payment method: Cash, GCash, or Bank Transfer.',
                    'Tenera generates an official printable/shareable digital receipt instantly.',
                    'Tap "Receipt" anytime from the Tenants tab to view or export proof.',
                  ],
                ),
                const SizedBox(height: 14),
              ],

              if (_activeCategory == 'All' || _activeCategory == 'Reminders') ...[
                _buildStepCard(
                  stepNumber: '04',
                  stepTitle: 'Sending Friendly Rent Reminders',
                  icon: Icons.mark_chat_unread_rounded,
                  iconColor: AppTheme.statusOverdue,
                  description:
                      'Avoid awkward collection talks with pre-written, polite reminder text messages.',
                  bulletPoints: const [
                    'Tap the Message icon next to any overdue or due-soon tenant.',
                    'Choose English or Tagalog message templates.',
                    'Includes exact rent balance and your GCash payment instructions.',
                    'Opens your default phone SMS app ready to send with one tap.',
                  ],
                ),
                const SizedBox(height: 14),
              ],

              if (_activeCategory == 'All' || _activeCategory == 'Offline & Backup') ...[
                _buildStepCard(
                  stepNumber: '05',
                  stepTitle: '100% Offline & Private on Your Device',
                  icon: Icons.shield_rounded,
                  iconColor: AppTheme.primaryDeep,
                  description:
                      'Your rental data belongs entirely to you. Tenera never uploads your tenant details to third-party cloud servers.',
                  bulletPoints: const [
                    'Works completely without internet or cellular reception.',
                    'Go to "More > Backup Data to Device" anytime to export an offline JSON file.',
                    'Fast, secure, and compliant with RA 10173 Philippine Data Privacy.',
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Quick Tips Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: AppTheme.accent, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Landlord Pro Tips',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow(
                      Icons.phone_outlined,
                      'Tap the phone icon next to any tenant to call them directly.',
                    ),
                    const SizedBox(height: 8),
                    _buildTipRow(
                      Icons.search_rounded,
                      'Use the search bar in the Tenants tab to instantly filter overdue, paid, or specific room units.',
                    ),
                    const SizedBox(height: 8),
                    _buildTipRow(
                      Icons.touch_app_rounded,
                      'Press and hold on any room block to quickly remove or vacate a tenant.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Get Started Action Button
              ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const HomeScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text(
                  'Get Started & Open Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String stepTitle,
    required IconData icon,
    required Color iconColor,
    required String description,
    required List<String> bulletPoints,
    String? highlightNotice,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP $stepNumber',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stepTitle,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.inkMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),
          ...bulletPoints.map((bp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                  Expanded(
                    child: Text(
                      bp,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (highlightNotice != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      highlightNotice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF795548),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.ink,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tenant.dart';
import '../../theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  final String month;
  final double progress;
  final int collectedAmount;
  final int expectedAmount;
  final int overdueTotal;
  final int overdueCount;
  final int vacantUnits;
  final int totalUnits;
  final List<TenantBill> overdueTenants;
  final List<TenantBill> dueSoonTenants;
  final VoidCallback onRecordPaymentQuick;
  final VoidCallback onAddTenantQuick;
  final VoidCallback onAddPropertyQuick;
  final VoidCallback onRemindOverdueQuick;
  final Function(TenantBill) onTenantTap;
  final Function(TenantBill) onSendReminder;

  const HomeTab({
    super.key,
    required this.month,
    required this.progress,
    required this.collectedAmount,
    required this.expectedAmount,
    required this.overdueTotal,
    required this.overdueCount,
    required this.vacantUnits,
    required this.totalUnits,
    required this.overdueTenants,
    required this.dueSoonTenants,
    required this.onRecordPaymentQuick,
    required this.onAddTenantQuick,
    required this.onAddPropertyQuick,
    required this.onRemindOverdueQuick,
    required this.onTenantTap,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Card ("Collected in October")
          _buildHeroCard(),

          const SizedBox(height: 12),

          // 2. Overdue and Vacant Units (Side by Side)
          Row(
            children: [
              Expanded(child: _buildOverdueCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildVacantCard()),
            ],
          ),

          const SizedBox(height: 20),

          // 3. In-Page Quick Actions Bar (Icon Logo Only)
          _buildQuickActionsRow(),

          const SizedBox(height: 24),

          // 4. Overdue Section with direct tap-to-pay
          _buildOverdueSection(),

          const SizedBox(height: 24),

          // 5. Due soon Section with direct tap-to-pay
          _buildDueSoonSection(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final currencyFormat = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collected in $month',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${currencyFormat.format(collectedAmount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Progress Bar with Amber active fill
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'of ₱${currencyFormat.format(expectedAmount)} expected this month',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCard() {
    final currencyFormat = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppTheme.statusOverdue,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Overdue',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₱${currencyFormat.format(overdueTotal)}',
            style: const TextStyle(
              color: AppTheme.statusOverdue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.home_outlined,
                color: AppTheme.inkMuted,
                size: 19,
              ),
              SizedBox(width: 6),
              Text(
                'Vacant units',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$vacantUnits of $totalUnits',
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.payments_rounded,
                tooltip: 'Record payment',
                key: const Key('quick_action_record_payment'),
                onTap: onRecordPaymentQuick,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.person_add_alt_1_rounded,
                tooltip: 'Add Tenant',
                key: const Key('quick_action_add_tenant'),
                onTap: onAddTenantQuick,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.domain_add_rounded,
                tooltip: 'Add Property',
                key: const Key('quick_action_add_property'),
                onTap: onAddPropertyQuick,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Remind Tenants',
                key: const Key('quick_action_remind'),
                onTap: onRemindOverdueQuick,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueSection() {
    final unpaidOverdue = overdueTenants.where((t) => !t.isPaid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overdue',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.statusOverdueBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$overdueCount tenants',
                style: const TextStyle(
                  color: AppTheme.statusOverdue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (unpaidOverdue.isEmpty)
          _buildEmptyCard('No overdue rent. All caught up!')
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaidOverdue.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.6)),
              itemBuilder: (context, index) {
                final tenant = unpaidOverdue[index];
                return _buildTenantTile(tenant);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDueSoonSection() {
    final unpaidDueSoon = dueSoonTenants.where((t) => !t.isPaid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Due soon',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.statusDueSoonBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${unpaidDueSoon.length} this week',
                style: const TextStyle(
                  color: AppTheme.statusDueSoon,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (unpaidDueSoon.isEmpty)
          _buildEmptyCard('No upcoming rent due this week.')
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaidDueSoon.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.6)),
              itemBuilder: (context, index) {
                final tenant = unpaidDueSoon[index];
                return _buildTenantTile(tenant);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTenantTile(TenantBill tenant) {
    final currencyFormat = NumberFormat('#,###');

    return InkWell(
      onTap: () => onTenantTap(tenant),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(
                tenant.initials,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tenant.location,
                    style: const TextStyle(
                      color: AppTheme.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${currencyFormat.format(tenant.amount)}',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tenant.isOverdue) ...[
                      Tooltip(
                        message: 'Remind ${tenant.name}',
                        child: InkWell(
                          onTap: () => onSendReminder(tenant),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tenant.isOverdue
                            ? AppTheme.statusOverdueBg
                            : AppTheme.statusDueSoonBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tenant.isOverdue
                                ? Icons.error_outline_rounded
                                : Icons.access_time_rounded,
                            size: 12,
                            color: tenant.isOverdue
                                ? AppTheme.statusOverdue
                                : AppTheme.statusDueSoon,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tenant.statusText,
                            style: TextStyle(
                              color: tenant.isOverdue
                                  ? AppTheme.statusOverdue
                                  : AppTheme.statusDueSoon,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppTheme.inkMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

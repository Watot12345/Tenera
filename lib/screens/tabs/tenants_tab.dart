import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tenant.dart';
import '../../theme/app_theme.dart';

class TenantsTab extends StatefulWidget {
  final List<TenantBill> tenants;
  final Function(TenantBill) onRecordPayment;
  final Function(TenantBill) onSendReminder;
  final Function(TenantBill) onShowReceipt;
  final Function(TenantBill)? onCallTenant;

  const TenantsTab({
    super.key,
    required this.tenants,
    required this.onRecordPayment,
    required this.onSendReminder,
    required this.onShowReceipt,
    this.onCallTenant,
  });

  @override
  State<TenantsTab> createState() => _TenantsTabState();
}

class _TenantsTabState extends State<TenantsTab> {
  String _tenantFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final query = _searchController.text.trim().toLowerCase();

    List<TenantBill> filteredTenants;
    if (_tenantFilter == 'Overdue') {
      filteredTenants = widget.tenants.where((t) => t.isOverdue && !t.isPaid).toList();
    } else if (_tenantFilter == 'Due Soon') {
      filteredTenants = widget.tenants.where((t) => !t.isOverdue && !t.isPaid).toList();
    } else if (_tenantFilter == 'Paid') {
      filteredTenants = widget.tenants.where((t) => t.isPaid).toList();
    } else {
      filteredTenants = widget.tenants;
    }

    if (query.isNotEmpty) {
      filteredTenants = filteredTenants.where((t) {
        final matchName = t.name.toLowerCase().contains(query);
        final matchLocation = t.location.toLowerCase().contains(query);
        final matchAmount = t.amount.toString().contains(query);
        return matchName || matchLocation || matchAmount;
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              key: const Key('tenants_search_field'),
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search tenant name, room, or location...',
                hintStyle: const TextStyle(
                  color: AppTheme.inkMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.inkMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Overdue', 'Due Soon', 'Paid'].map((f) {
                final isSelected = _tenantFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _tenantFilter = f;
                      });
                    },
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.ink,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (filteredTenants.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Icon(
                    query.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
                    size: 48,
                    color: AppTheme.inkMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isNotEmpty
                        ? 'No tenants found for "$query"'
                        : 'No ${_tenantFilter.toLowerCase()} tenants',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    query.isNotEmpty
                        ? 'Try searching by a different name, room, or location.'
                        : 'Tenants in this category will appear here.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.inkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (query.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Clear Search'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else

          Column(
            children: [
              for (int index = 0; index < filteredTenants.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final tenant = filteredTenants[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                child: Text(
                                  tenant.initials,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenant.name,
                                      style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontSize: 16,
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
                                  const SizedBox(height: 2),
                                  Text(
                                    tenant.isPaid ? 'Paid' : tenant.statusText,
                                    style: TextStyle(
                                      color: tenant.isPaid
                                          ? AppTheme.statusPaid
                                          : (tenant.isOverdue
                                              ? AppTheme.statusOverdue
                                              : AppTheme.statusDueSoon),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppTheme.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.phone_outlined, size: 18),
                                    onPressed: () {
                                      if (widget.onCallTenant != null) {
                                        widget.onCallTenant!(tenant);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Calling ${tenant.name}...'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.message_outlined, size: 18),
                                    onPressed: () => widget.onSendReminder(tenant),
                                  ),
                                ],
                              ),
                              if (!tenant.isPaid)
                                FilledButton.icon(
                                  onPressed: () => widget.onRecordPayment(tenant),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('Record Payment'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () => widget.onShowReceipt(tenant),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                  label: const Text('Receipt'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

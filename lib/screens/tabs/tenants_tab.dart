import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tenant.dart';
import '../../theme/app_theme.dart';

class TenantsTab extends StatefulWidget {
  final List<TenantBill> tenants;
  final Function(TenantBill) onRecordPayment;
  final Function(TenantBill) onSendReminder;
  final Function(TenantBill) onShowReceipt;
  final Function(TenantBill)? onCallTenant;
  final VoidCallback? onAddTenant;

  const TenantsTab({
    super.key,
    required this.tenants,
    required this.onRecordPayment,
    required this.onSendReminder,
    required this.onShowReceipt,
    this.onCallTenant,
    this.onAddTenant,
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

  Future<void> _openMessenger(TenantBill tenant) async {
    final handle = (tenant.messenger ?? '').trim();
    if (handle.isEmpty) return;
    final clean = handle
        .replaceAll('https://m.me/', '')
        .replaceAll('http://m.me/', '')
        .replaceAll('m.me/', '')
        .replaceAll('@', '')
        .trim();

    final formattedAmount = NumberFormat('#,###').format(tenant.amount);
    final roomDisplay = tenant.location.split('·')[0].trim();
    final reminderText =
        'Hello ${tenant.name}, this is a gentle reminder regarding your rent of ₱$formattedAmount for $roomDisplay (${tenant.statusText}). Thank you!';

    await Clipboard.setData(ClipboardData(text: reminderText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0084FF),
          content: Text('💬 Opening Messenger for ${tenant.name}! (Reminder text copied)'),
        ),
      );
    }

    final uri = Uri.parse('https://m.me/$clean');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  Future<void> _callPhone(TenantBill tenant) async {
    if (widget.onCallTenant != null) {
      widget.onCallTenant!(tenant);
      return;
    }

    final phone = (tenant.phone ?? '').trim();
    if (phone.isNotEmpty) {
      final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final uri = Uri.parse('tel:$clean');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${tenant.name}...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
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
        final matchPhone = (t.phone ?? '').toLowerCase().contains(query);
        final matchMessenger = (t.messenger ?? '').toLowerCase().contains(query);
        return matchName || matchLocation || matchAmount || matchPhone || matchMessenger;
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar + Add Tenant Button Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
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
                      hintText: 'Search tenant, room...',
                      hintStyle: const TextStyle(
                        color: AppTheme.inkMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.inkMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('btn_add_tenant_bar'),
                  onPressed: widget.onAddTenant,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text(
                    'Add Tenant',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
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
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                children: [
                  Icon(
                    query.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
                    size: 48,
                    color: AppTheme.getInkMutedColor(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isNotEmpty
                        ? 'No tenants found for "$query"'
                        : 'No ${_tenantFilter.toLowerCase()} tenants',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getInkColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    query.isNotEmpty
                        ? 'Try searching by a different name, room, or location.'
                        : 'Tenants in this category will appear here.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getInkMutedColor(context),
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
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.8)),
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
                                      style: TextStyle(
                                        color: AppTheme.getInkColor(context),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tenant.location,
                                      style: TextStyle(
                                        color: AppTheme.getInkMutedColor(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                    if ((tenant.phone != null && tenant.phone!.isNotEmpty) ||
                                        (tenant.messenger != null && tenant.messenger!.isNotEmpty)) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        children: [
                                          if (tenant.phone != null && tenant.phone!.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.phone_android_rounded, size: 12, color: AppTheme.inkMuted),
                                                const SizedBox(width: 3),
                                                Text(
                                                  tenant.phone!,
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          if (tenant.messenger != null && tenant.messenger!.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.chat_bubble_rounded, size: 12, color: Color(0xFF0084FF)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'm.me/${tenant.messenger!.replaceAll('https://m.me/', '').replaceAll('m.me/', '')}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF0084FF), fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₱${currencyFormat.format(tenant.amount)}',
                                    style: TextStyle(
                                      color: AppTheme.getInkColor(context),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tenant.isPaid ? 'Paid' : tenant.statusText,
                                    style: TextStyle(
                                      color: tenant.isPaid
                                          ? AppTheme.getStatusPaidText(context)
                                          : (tenant.isOverdue
                                              ? AppTheme.getStatusOverdueText(context)
                                              : AppTheme.getStatusDueSoonText(context)),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Divider(height: 20, color: AppTheme.getBorderColor(context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.phone_outlined, size: 18),
                                    tooltip: 'Call Tenant',
                                    onPressed: () => _callPhone(tenant),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.message_outlined, size: 18),
                                    tooltip: 'Send Reminder',
                                    onPressed: () => widget.onSendReminder(tenant),
                                  ),
                                  if (tenant.messenger != null && tenant.messenger!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    IconButton.filledTonal(
                                      key: Key('btn_messenger_${tenant.id}'),
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF0084FF)),
                                      tooltip: 'Message on FB Messenger',
                                      onPressed: () => _openMessenger(tenant),
                                    ),
                                  ],
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

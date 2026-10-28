import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tenant.dart';
import '../../services/database_helper.dart';
import '../../services/landlord_profile_service.dart';
import '../../theme/app_theme.dart';

class TenantsTab extends StatefulWidget {
  final List<TenantBill> tenants;
  final Function(TenantBill) onRecordPayment;
  final Function(TenantBill) onSendReminder;
  final Function(TenantBill) onShowReceipt;
  final Function(TenantBill)? onCallTenant;
  final VoidCallback? onAddTenant;
  final Future<void> Function(TenantBill updatedTenant)? onEditTenant;
  final Future<void> Function(TenantBill tenant)? onDeleteTenant;

  const TenantsTab({
    super.key,
    required this.tenants,
    required this.onRecordPayment,
    required this.onSendReminder,
    required this.onShowReceipt,
    this.onCallTenant,
    this.onAddTenant,
    this.onEditTenant,
    this.onDeleteTenant,
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

  void _showEditTenantDialog(TenantBill tenant) {
    final nameCtrl = TextEditingController(text: tenant.name);
    final phoneCtrl = TextEditingController(text: tenant.phone ?? '');
    final messengerCtrl = TextEditingController(text: tenant.messenger ?? '');
    final amountCtrl = TextEditingController(text: tenant.amount.toString());
    final locationCtrl = TextEditingController(text: tenant.location);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text('Edit Tenant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.getInkColor(dialogCtx))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update tenant profile and billing info:', style: TextStyle(fontSize: 13, color: AppTheme.getInkMutedColor(dialogCtx))),
              const SizedBox(height: 14),
              TextField(
                key: const Key('input_edit_tenant_name'),
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Tenant Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_edit_tenant_amount'),
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Rent (₱)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_edit_tenant_phone'),
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '09xxxxxxxxx',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_edit_tenant_messenger'),
                controller: messengerCtrl,
                decoration: InputDecoration(
                  labelText: 'Messenger Username / Link',
                  hintText: '@username or m.me/handle',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_edit_tenant_location'),
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Unit / Property Assignment',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('btn_save_edit_tenant'),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              final newAmount = int.tryParse(amountCtrl.text.trim()) ?? tenant.amount;
              final newPhone = phoneCtrl.text.trim();
              final newMessenger = messengerCtrl.text.trim();
              final newLoc = locationCtrl.text.trim();

              final updated = tenant.copyWith(
                name: newName,
                initials: newName.length >= 2 ? newName.substring(0, 2).toUpperCase() : newName.toUpperCase(),
                amount: newAmount,
                phone: newPhone.isNotEmpty ? newPhone : null,
                messenger: newMessenger.isNotEmpty ? newMessenger : null,
                location: newLoc.isNotEmpty ? newLoc : tenant.location,
              );

              Navigator.pop(dialogCtx);
              widget.onEditTenant?.call(updated);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.primaryDeep,
                  content: Text('Tenant $newName updated successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTenant(TenantBill tenant) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFC92A2A), size: 22),
            ),
            const SizedBox(width: 10),
            Text('Delete Tenant?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.getInkColor(dialogCtx))),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${tenant.name} from ${tenant.location}? This record will be permanently deleted.',
          style: TextStyle(fontSize: 14, color: AppTheme.getInkColor(dialogCtx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_tenant'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onDeleteTenant?.call(tenant);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFC92A2A),
                  content: Text('Tenant ${tenant.name} deleted.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC92A2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Tenant'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatementOfAccount(TenantBill tenant) async {
    final payments = await DatabaseHelper.instance.getPayments();
    if (!mounted) return;

    final tenantPayments = payments.where((p) {
      return p.tenantName.trim().toLowerCase() == tenant.name.trim().toLowerCase() ||
          p.location.trim().toLowerCase() == tenant.location.trim().toLowerCase();
    }).toList();

    final landlord = LandlordProfileService.currentProfile;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurfaceElevatedColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statement of Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.getInkColor(ctx),
                                ),
                              ),
                              Text(
                                tenant.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.getInkMutedColor(ctx),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.getSurfaceColor(ctx),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.getBorderColor(ctx)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENT BALANCE DUE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: AppTheme.getInkMutedColor(ctx),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${NumberFormat('#,###').format(tenant.amount)}',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: tenant.isPaid
                                            ? AppTheme.getStatusPaidText(ctx)
                                            : (tenant.isOverdue
                                                ? AppTheme.getStatusOverdueText(ctx)
                                                : AppTheme.getStatusDueSoonText(ctx)),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: tenant.isPaid
                                        ? AppTheme.getStatusPaidBg(ctx)
                                        : (tenant.isOverdue
                                            ? AppTheme.getStatusOverdueBg(ctx)
                                            : AppTheme.getStatusDueSoonBg(ctx)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tenant.isPaid ? 'Paid' : tenant.statusText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tenant.isPaid
                                          ? AppTheme.getStatusPaidText(ctx)
                                          : (tenant.isOverdue
                                              ? AppTheme.getStatusOverdueText(ctx)
                                              : AppTheme.getStatusDueSoonText(ctx)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.home_work_outlined, size: 16, color: AppTheme.inkMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tenant.location,
                                    style: TextStyle(fontSize: 13, color: AppTheme.getInkColor(ctx), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            if (tenant.phone != null && tenant.phone!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.phone_android_rounded, size: 16, color: AppTheme.inkMuted),
                                  const SizedBox(width: 8),
                                  Text(
                                    tenant.phone!,
                                    style: TextStyle(fontSize: 13, color: AppTheme.getInkColor(ctx)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'PAYMENT & BILLING HISTORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppTheme.getInkMutedColor(ctx),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (tenantPayments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceColor(ctx),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.getBorderColor(ctx)),
                          ),
                          child: Text(
                            'No payment records found yet for this tenant.',
                            style: TextStyle(fontSize: 13, color: AppTheme.getInkMutedColor(ctx)),
                          ),
                        )
                      else
                        ...tenantPayments.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.getSurfaceColor(ctx),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: p.isVoided
                                    ? const Color(0xFFC92A2A).withValues(alpha: 0.3)
                                    : AppTheme.getBorderColor(ctx),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: p.isVoided
                                        ? const Color(0xFFFFECEB)
                                        : AppTheme.statusPaid.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    p.isVoided ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: p.isVoided ? const Color(0xFFC92A2A) : AppTheme.statusPaid,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.method,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.getInkColor(ctx),
                                          decoration: p.isVoided ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.dateFormatted}${p.referenceNo != null ? " · Ref: ${p.referenceNo}" : ""}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.getInkMutedColor(ctx),
                                        ),
                                      ),
                                      if (p.isVoided && p.voidReason != null)
                                        Text(
                                          'Voided: ${p.voidReason}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFC92A2A), fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₱${NumberFormat('#,###').format(p.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: p.isVoided ? AppTheme.getInkMutedColor(ctx) : AppTheme.statusPaid,
                                    decoration: p.isVoided ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: ElevatedButton.icon(
                    key: const Key('btn_share_soa'),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share / Copy Statement of Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final buffer = StringBuffer();
                      buffer.writeln('========================================');
                      buffer.writeln('STATEMENT OF ACCOUNT (SOA)');
                      buffer.writeln(landlord.businessName.isNotEmpty ? landlord.businessName : 'Tenera Property Management');
                      if (landlord.phone.isNotEmpty) {
                        buffer.writeln('Landlord Contact: ${landlord.phone}');
                      }
                      buffer.writeln('Date: ${DateFormat('MMMM d, y').format(DateTime.now())}');
                      buffer.writeln('========================================');
                      buffer.writeln('Tenant: ${tenant.name}');
                      buffer.writeln('Assigned Unit: ${tenant.location}');
                      buffer.writeln('Status: ${tenant.isPaid ? "Paid" : tenant.statusText}');
                      buffer.writeln('Current Balance Due: ₱${NumberFormat('#,###').format(tenant.amount)}');
                      buffer.writeln('----------------------------------------');
                      buffer.writeln('PAYMENT TRANSACTIONS:');
                      if (tenantPayments.isEmpty) {
                        buffer.writeln('No previous payments on record.');
                      } else {
                        for (final p in tenantPayments) {
                          if (p.isVoided) {
                            buffer.writeln('• ${p.dateFormatted}: [VOIDED] ₱${NumberFormat('#,###').format(p.amount)} (${p.method})');
                          } else {
                            buffer.writeln('• ${p.dateFormatted}: ₱${NumberFormat('#,###').format(p.amount)} via ${p.method}${p.referenceNo != null ? " (Ref: ${p.referenceNo})" : ""}');
                          }
                        }
                      }
                      buffer.writeln('========================================');
                      if (!tenant.isPaid && tenant.amount > 0) {
                        buffer.writeln('Please settle the balance of ₱${NumberFormat('#,###').format(tenant.amount)} at your earliest convenience.');
                        if (landlord.receiptFooter.isNotEmpty) {
                          buffer.writeln(landlord.receiptFooter);
                        }
                      } else {
                        buffer.writeln('All dues are currently settled. Thank you!');
                      }

                      Clipboard.setData(ClipboardData(text: buffer.toString()));
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.primaryDeep,
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '✓ Statement of Account for ${tenant.name} copied to clipboard!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTenantActionSheet(TenantBill tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevatedColor(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      tenant.name,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.getInkColor(ctx)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tenant.location,
                      style: TextStyle(fontSize: 13, color: AppTheme.getInkMutedColor(ctx)),
                    ),
                  ],
                ),
              ),
              ListTile(
                key: Key('action_soa_tenant_${tenant.id}'),
                leading: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                title: const Text('Statement of Account (SOA)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('View ledger & transaction history', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStatementOfAccount(tenant);
                },
              ),
              ListTile(
                key: Key('action_edit_tenant_${tenant.id}'),
                leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                title: const Text('Edit Tenant Details', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTenantDialog(tenant);
                },
              ),
              ListTile(
                key: Key('action_delete_tenant_${tenant.id}'),
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC92A2A)),
                title: const Text('Delete Tenant', style: TextStyle(color: Color(0xFFC92A2A), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTenant(tenant);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
                width: 48,
                child: ElevatedButton(
                  key: const Key('btn_add_tenant_bar'),
                  onPressed: widget.onAddTenant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.person_add_rounded, size: 22, color: Colors.white),
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
                    backgroundColor: AppTheme.getSurfaceColor(context),
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.getBorderColor(context),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        _tenantFilter = f;
                      });
                    },
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.getInkColor(context),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
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
                    return Dismissible(
                      key: Key('dismiss_tenant_${tenant.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _showEditTenantDialog(tenant);
                          return false;
                        } else {
                          _confirmDeleteTenant(tenant);
                          return false;
                        }
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC92A2A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            SizedBox(width: 8),
                            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: Key('tenant_card_${tenant.id}'),
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showStatementOfAccount(tenant),
                          onLongPress: () => _showTenantActionSheet(tenant),
                          child: Container(
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                        IconButton(
                                          key: Key('btn_tenant_options_${tenant.id}'),
                                          icon: Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.getInkMutedColor(context)),
                                          tooltip: 'Tenant Options',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showTenantActionSheet(tenant),
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
                          ),
                        ),
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

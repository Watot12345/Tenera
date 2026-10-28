import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';

class PaymentsTab extends StatefulWidget {
  final List<PaymentRecord> paymentRecords;
  final int collectedAmount;
  final VoidCallback onRecordPayment;
  final Function(PaymentRecord) onShowReceipt;
  final bool isStaffMode;

  const PaymentsTab({
    super.key,
    required this.paymentRecords,
    required this.collectedAmount,
    required this.onRecordPayment,
    required this.onShowReceipt,
    this.isStaffMode = false,
  });

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  String _paymentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

    List<PaymentRecord> filtered = widget.paymentRecords;
    if (_paymentFilter != 'All') {
      filtered = widget.paymentRecords.where((p) => p.method == _paymentFilter).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Collected Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.isDark(context)
                    ? [const Color(0xFF1E524B), const Color(0xFF133833)]
                    : [AppTheme.primary, AppTheme.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Collections (${DateFormat('MMMM').format(DateTime.now())})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isStaffMode ? '••••••' : '₱${currencyFormat.format(widget.collectedAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onRecordPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.ink,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text(
                    '+ Record New Payment',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filter by Payment Method
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Cash', 'GCash', 'Bank Transfer'].map((m) {
                final isSelected = _paymentFilter == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(m),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _paymentFilter = m;
                      });
                    },
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.getInkColor(context),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Receipts',
                style: TextStyle(
                  color: AppTheme.getInkColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${filtered.length} entries',
                style: TextStyle(
                  color: AppTheme.getInkMutedColor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.8)),
              ),
              child: Center(
                child: Text(
                  'No payment records matching this filter.',
                  style: TextStyle(
                    color: AppTheme.getInkMutedColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (int index = 0; index < filtered.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  InkWell(
                    key: Key('btn_receipt_${filtered[index].id}'),
                    onTap: () => widget.onShowReceipt(filtered[index]),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.getStatusPaidBg(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              filtered[index].method == 'GCash'
                                  ? Icons.phone_android_rounded
                                  : (filtered[index].method == 'Cash'
                                      ? Icons.payments_outlined
                                      : Icons.account_balance_outlined),
                              color: AppTheme.getStatusPaidText(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filtered[index].tenantName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.getInkColor(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${filtered[index].location} · ${filtered[index].dateFormatted}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getInkMutedColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+₱${currencyFormat.format(filtered[index].amount)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  decoration: filtered[index].isVoided ? TextDecoration.lineThrough : null,
                                  color: filtered[index].isVoided
                                      ? const Color(0xFFC0392B)
                                      : AppTheme.getStatusPaidText(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (filtered[index].isVoided) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC0392B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'VOID',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFC0392B),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getBackgroundColor(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      filtered[index].method,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.getInkMutedColor(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

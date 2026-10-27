import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

enum BirTaxRegime {
  residentialExempt(
    label: 'Residential Lease Exemption (≤ ₱15k/mo)',
    code: 'EXEMPT',
    rate: 0.0,
    description: 'VAT & Percentage tax exempt under TRAIN Law (RA 10963) for residential rent ≤ ₱15,000/month.',
  ),
  flat8Percent(
    label: '8% Flat Income Tax (TRAIN Law)',
    code: '8% FLAT',
    rate: 0.08,
    description: 'Flat 8% tax in lieu of graduated income tax and Sec. 116 percentage tax for revenue < ₱3M.',
  ),
  cwt5Percent(
    label: '5% Creditable Withholding Tax (BIR Form 2307)',
    code: '5% CWT',
    rate: 0.05,
    description: '5% expanded withholding tax required for commercial or corporate leases under BIR RR 2-98.',
  ),
  percentageTax3Percent(
    label: '3% Percentage Tax (NIRC Sec. 116)',
    code: '3% PERCENTAGE',
    rate: 0.03,
    description: '3% statutory percentage tax on gross quarterly sales/receipts for non-VAT registered landlords.',
  );

  final String label;
  final String code;
  final double rate;
  final String description;

  const BirTaxRegime({
    required this.label,
    required this.code,
    required this.rate,
    required this.description,
  });
}

class ReportsExportScreen extends StatefulWidget {
  final List<PaymentRecord>? initialPayments;
  final List<PropertyItem>? initialProperties;
  final List<TenantBill>? initialTenants;

  const ReportsExportScreen({
    super.key,
    this.initialPayments,
    this.initialProperties,
    this.initialTenants,
  });

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  bool _isLoading = true;
  List<PaymentRecord> _allPayments = [];
  List<PropertyItem> _properties = [];
  List<TenantBill> _tenants = [];

  String _selectedPropertyFilter = 'ALL'; // 'ALL' or property ID
  BirTaxRegime _selectedRegime = BirTaxRegime.flat8Percent;

  final currencyFormatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  final compactCurrency = NumberFormat.compactCurrency(locale: 'en_PH', symbol: '₱');

  @override
  void initState() {
    super.initState();
    if (widget.initialPayments != null && widget.initialProperties != null && widget.initialTenants != null) {
      _allPayments = widget.initialPayments!;
      _properties = widget.initialProperties!;
      _tenants = widget.initialTenants!;
      _isLoading = false;
    } else {
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final payments = await db.getPayments();
    if (!mounted) return;
    final props = await db.getProperties();
    if (!mounted) return;
    final tenants = await db.getTenants();
    if (!mounted) return;

    setState(() {
      _allPayments = payments;
      _properties = props;
      _tenants = tenants;
      _isLoading = false;
    });
  }

  List<PaymentRecord> get _filteredPayments {
    if (_selectedPropertyFilter == 'ALL') {
      return _allPayments;
    }
    final prop = _properties.firstWhere((p) => p.id == _selectedPropertyFilter, orElse: () => _properties.first);
    return _allPayments.where((p) => p.location.contains(prop.name)).toList();
  }

  int get _totalGrossRevenue {
    return _filteredPayments.fold(0, (sum, p) => sum + p.amount);
  }

  double get _totalEstimatedTax {
    return _totalGrossRevenue * _selectedRegime.rate;
  }

  double get _totalNetRevenue {
    return _totalGrossRevenue - _totalEstimatedTax;
  }

  int get _totalOutstandingArrears {
    return _tenants
        .where((t) => !t.isPaid && t.isOverdue)
        .fold(0, (sum, t) => sum + t.amount);
  }

  String _generateCsvString() {
    final buffer = StringBuffer();

    // BIR & Tenera Report Header
    buffer.writeln('"TENERA PROPERTY MANAGER - REVENUE & BIR TAX REPORT"');
    buffer.writeln('"Export Date:","${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}"');
    buffer.writeln('"Tax Regime:","${_selectedRegime.label}"');
    buffer.writeln('"Tax Code:","${_selectedRegime.code}"');
    buffer.writeln('"Property Filter:","${_selectedPropertyFilter == 'ALL' ? 'All Properties' : _properties.firstWhere((p) => p.id == _selectedPropertyFilter).name}"');
    buffer.writeln('"Total Gross Collections:","₱${_totalGrossRevenue.toStringAsFixed(2)}"');
    buffer.writeln('"Estimated Tax Due/Withheld:","₱${_totalEstimatedTax.toStringAsFixed(2)}"');
    buffer.writeln('"Net Rental Revenue:","₱${_totalNetRevenue.toStringAsFixed(2)}"');
    buffer.writeln('"Active Arrears / Uncollected:","₱${_totalOutstandingArrears.toStringAsFixed(2)}"');
    buffer.writeln('');

    // Table Column Headers
    buffer.writeln(
      '"Transaction ID","Date","Tenant Name","Property / Unit","Payment Method","Reference No","Gross Amount (PHP)","Tax Regime","Estimated Tax (PHP)","Net Amount (PHP)"',
    );

    // Records
    for (final p in _filteredPayments) {
      final tax = p.amount * _selectedRegime.rate;
      final net = p.amount - tax;

      final row = [
        _escapeCsv(p.id),
        _escapeCsv(p.dateFormatted),
        _escapeCsv(p.tenantName),
        _escapeCsv(p.location),
        _escapeCsv(p.method),
        _escapeCsv(p.referenceNo ?? 'N/A'),
        p.amount.toStringAsFixed(2),
        _escapeCsv(_selectedRegime.code),
        tax.toStringAsFixed(2),
        net.toStringAsFixed(2),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return '"$value"';
  }

  void _copyCsvToClipboard() {
    final csv = _generateCsvString();
    Clipboard.setData(ClipboardData(text: csv));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Revenue & BIR Tax CSV copied to clipboard (${_filteredPayments.length} records)! Paste directly into Excel or Google Sheets.',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryDeep,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCsvPreviewDialog() {
    final csv = _generateCsvString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CSV Export Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Standard RFC 4180 CSV format compatible with Microsoft Excel, Apple Numbers, and Google Sheets.',
                style: TextStyle(fontSize: 13, color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csv,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _copyCsvToClipboard();
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'BIR Tax & Revenue Reports',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('btn_preview_csv'),
            icon: const Icon(Icons.remove_red_eye_rounded, color: AppTheme.primaryDeep),
            tooltip: 'Preview CSV',
            onPressed: _filteredPayments.isEmpty ? null : _showCsvPreviewDialog,
          ),
          IconButton(
            key: const Key('btn_copy_csv_appbar'),
            icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryDeep),
            tooltip: 'Copy CSV Table',
            onPressed: _filteredPayments.isEmpty ? null : _copyCsvToClipboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filter & Profile Card
                  _buildFilterCard(),
                  const SizedBox(height: 16),

                  // Revenue & Tax Summary KPI Cards
                  _buildKpiSummaryCards(),
                  const SizedBox(height: 20),

                  // Tax Guidance Explainer Banner
                  _buildTaxGuidanceBanner(),
                  const SizedBox(height: 24),

                  // Ledger Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collections Ledger (${_filteredPayments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('btn_export_csv_action'),
                        onPressed: _filteredPayments.isEmpty ? null : _copyCsvToClipboard,
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Transactions List
                  if (_filteredPayments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No payment records found for the selected property filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.inkMuted),
                        ),
                      ),
                    )
                  else
                    ..._filteredPayments.map((p) => _buildPaymentRow(p)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Filters & BIR Profile',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),

          // Property Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedPropertyFilter,
            decoration: InputDecoration(
              labelText: 'Property Selection',
              labelStyle: const TextStyle(fontSize: 13, color: AppTheme.inkMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: [
              const DropdownMenuItem(
                value: 'ALL',
                child: Text('All Properties (Consolidated)'),
              ),
              ..._properties.map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPropertyFilter = val);
              }
            },
          ),
          const SizedBox(height: 14),

          // BIR Tax Regime Selector
          DropdownButtonFormField<BirTaxRegime>(
            initialValue: _selectedRegime,
            decoration: InputDecoration(
              labelText: 'BIR Tax Regime Schedule',
              labelStyle: const TextStyle(fontSize: 13, color: AppTheme.inkMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: BirTaxRegime.values.map((regime) {
              return DropdownMenuItem(
                value: regime,
                child: Text(
                  regime.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedRegime = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Gross Collections',
                value: currencyFormatter.format(_totalGrossRevenue),
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.primaryDeep,
                bgColor: AppTheme.primaryDeep.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Estimated Tax Due',
                value: currencyFormatter.format(_totalEstimatedTax),
                icon: Icons.receipt_long_rounded,
                color: Colors.amber.shade900,
                bgColor: Colors.amber.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Net Revenue',
                value: currencyFormatter.format(_totalNetRevenue),
                icon: Icons.savings_rounded,
                color: AppTheme.statusPaid,
                bgColor: AppTheme.statusPaidBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Active Arrears',
                value: currencyFormatter.format(_totalOutstandingArrears),
                icon: Icons.warning_amber_rounded,
                color: AppTheme.statusOverdue,
                bgColor: AppTheme.statusOverdueBg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxGuidanceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryDeep.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedRegime.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDeep,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedRegime.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.ink,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(PaymentRecord payment) {
    final tax = payment.amount * _selectedRegime.rate;
    final net = payment.amount - tax;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              payment.method.toLowerCase().contains('cash')
                  ? Icons.payments_outlined
                  : Icons.account_balance_wallet_outlined,
              color: AppTheme.primaryDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.tenantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.location} · ${payment.dateFormatted}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted),
                ),
                if (payment.referenceNo != null && payment.referenceNo!.isNotEmpty)
                  Text(
                    'Ref: ${payment.referenceNo}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.primaryDeep, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(payment.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tax: ${currencyFormatter.format(tax)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
              Text(
                'Net: ${currencyFormatter.format(net)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

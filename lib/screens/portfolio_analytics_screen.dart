import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/portfolio_analytics.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class PortfolioAnalyticsScreen extends StatefulWidget {
  final PortfolioAnalyticsSummary? initialSummary;

  const PortfolioAnalyticsScreen({super.key, this.initialSummary});

  @override
  State<PortfolioAnalyticsScreen> createState() => _PortfolioAnalyticsScreenState();
}

class _PortfolioAnalyticsScreenState extends State<PortfolioAnalyticsScreen> {
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
  bool _isLoading = true;
  PortfolioAnalyticsSummary? _summary;

  @override
  void initState() {
    super.initState();
    if (widget.initialSummary != null) {
      _summary = widget.initialSummary;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await DatabaseHelper.instance.getPortfolioAnalytics();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _generateCsvReport() {
    if (_summary == null) return '';
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final buffer = StringBuffer();

    buffer.writeln('TENERA BUSINESS - MULTI-PROPERTY PORTFOLIO ANALYTICS REPORT');
    buffer.writeln('Generated at,$now');
    buffer.writeln('Total Properties,${_summary!.totalProperties}');
    buffer.writeln('Total Rental Units,${_summary!.totalUnits}');
    buffer.writeln('Overall Occupancy Rate,${_summary!.overallOccupancyRate.toStringAsFixed(1)}%');
    buffer.writeln('Total Monthly Potential Rent,${_summary!.totalPotentialMonthlyRent}');
    buffer.writeln('Actual Rent Collected,${_summary!.totalCollected}');
    buffer.writeln('Total Outstanding Arrears,${_summary!.totalArrears}');
    buffer.writeln('Collection Efficiency Rate,${_summary!.overallCollectionRate.toStringAsFixed(1)}%');
    buffer.writeln();
    buffer.writeln('Property Name,Address,Total Units,Occupied,Overdue,Vacant,Occupancy Rate (%),Potential Rent (PHP),Collected (PHP),Arrears (PHP),Collection Rate (%),Portfolio Share (%),Avg Rent Per Unit (PHP)');

    for (final p in _summary!.propertyItems) {
      final safeName = p.propertyName.replaceAll(',', ' ');
      final safeAddress = p.propertyAddress.replaceAll(',', ' ');
      buffer.writeln(
        '$safeName,$safeAddress,${p.totalUnits},${p.occupiedUnits},${p.overdueUnits},${p.vacantUnits},${p.occupancyRate.toStringAsFixed(1)},${p.potentialRevenue},${p.collectedRevenue},${p.arrearsAmount},${p.collectionRate.toStringAsFixed(1)},${p.revenueSharePercent.toStringAsFixed(1)},${p.averageRentPerUnit}',
      );
    }

    return buffer.toString();
  }

  void _copyCsvToClipboard() {
    final csv = _generateCsvReport();
    if (csv.isEmpty) return;

    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.primaryDeep,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Portfolio Analytics CSV copied to clipboard! Ready to paste into Excel or Google Sheets.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showCsvPreviewDialog() {
    final csv = _generateCsvReport();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.table_chart_rounded, color: AppTheme.primaryDeep),
              SizedBox(width: 8),
              Text(
                'CSV Report Preview',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 340,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csv,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppTheme.inkMuted)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _copyCsvToClipboard();
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'Portfolio Analytics',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            SizedBox(width: 8),
            _BusinessBadge(),
          ],
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('btn_preview_portfolio_csv'),
            icon: const Icon(Icons.remove_red_eye_rounded, color: AppTheme.primaryDeep),
            tooltip: 'Preview CSV',
            onPressed: _summary == null ? null : _showCsvPreviewDialog,
          ),
          IconButton(
            key: const Key('btn_copy_portfolio_csv_appbar'),
            icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryDeep),
            tooltip: 'Copy CSV Table',
            onPressed: _summary == null ? null : _copyCsvToClipboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null || _summary!.propertyItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Executive Portfolio Header Card
                      _buildExecutiveHeaderCard(_summary!),
                      const SizedBox(height: 16),

                      // Unit Occupancy Distribution Bar
                      _buildOccupancyDistributionCard(_summary!),
                      const SizedBox(height: 20),

                      // Section Title: Property-by-Property Comparison
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cross-Property Comparison (${_summary!.propertyItems.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('btn_export_portfolio_csv'),
                            onPressed: _copyCsvToClipboard,
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text(
                              'Export CSV',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Property Performance Cards
                      ..._summary!.propertyItems.map((prop) => _buildPropertyCard(prop)),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryDeep, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Properties Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add properties and units in the Properties tab to generate comparative analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeaderCard(PortfolioAnalyticsSummary s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), AppTheme.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PORTFOLIO CASHFLOW & OCCUPANCY',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s.totalProperties} Properties',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormatter.format(s.totalCollected),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Collected this month · Potential: ${_currencyFormatter.format(s.totalPotentialMonthlyRent)}/mo',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Two Primary Performance Meters
          Row(
            children: [
              Expanded(
                child: _buildHeaderMeter(
                  label: 'Occupancy Rate',
                  percentage: s.overallOccupancyRate,
                  caption: '${s.totalOccupied} of ${s.totalUnits} units',
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildHeaderMeter(
                  label: 'Collection Efficiency',
                  percentage: s.overallCollectionRate,
                  caption: '${s.overallCollectionRate.toStringAsFixed(1)}% collected',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 14),

          // Mini Metric Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniHeaderStat('Units', '${s.totalUnits} Total'),
              _buildMiniHeaderStat('Overdue', _currencyFormatter.format(s.totalArrears), isAlert: s.totalArrears > 0),
              _buildMiniHeaderStat('Vacant', '${s.totalVacant} Units'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMeter({
    required String label,
    required double percentage,
    required String caption,
    required Color color,
  }) {
    final clampedProgress = (percentage / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHeaderStat(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isAlert ? const Color(0xFFFF8A80) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOccupancyDistributionCard(PortfolioAnalyticsSummary s) {
    final occupiedPct = s.totalUnits > 0 ? (s.totalOccupied / s.totalUnits) * 100.0 : 0.0;
    final overduePct = s.totalUnits > 0 ? (s.totalOverdue / s.totalUnits) * 100.0 : 0.0;
    final vacantPct = s.totalUnits > 0 ? (s.totalVacant / s.totalUnits) * 100.0 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Unit Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink),
          ),
          const SizedBox(height: 12),

          // Multi-segment Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (s.totalOccupied - s.totalOverdue > 0)
                    Expanded(
                      flex: (s.totalOccupied - s.totalOverdue),
                      child: Container(color: AppTheme.statusPaid),
                    ),
                  if (s.totalOverdue > 0)
                    Expanded(
                      flex: s.totalOverdue,
                      child: Container(color: AppTheme.statusOverdue),
                    ),
                  if (s.totalVacant > 0)
                    Expanded(
                      flex: s.totalVacant,
                      child: Container(color: Colors.grey.shade400),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                color: AppTheme.statusPaid,
                label: 'Paid / On Time',
                count: '${s.totalOccupied - s.totalOverdue} (${(occupiedPct - overduePct).clamp(0, 100).toStringAsFixed(0)}%)',
              ),
              _buildLegendItem(
                color: AppTheme.statusOverdue,
                label: 'Overdue Units',
                count: '${s.totalOverdue} (${overduePct.toStringAsFixed(0)}%)',
              ),
              _buildLegendItem(
                color: Colors.grey.shade500,
                label: 'Vacant',
                count: '${s.totalVacant} (${vacantPct.toStringAsFixed(0)}%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label, required String count}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.inkMuted, fontWeight: FontWeight.w600)),
            Text(count, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyAnalyticsItem p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.propertyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.propertyAddress,
                      style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${p.revenueSharePercent.toStringAsFixed(1)}% Share',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Occupancy Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupancy: ${p.occupiedUnits}/${p.totalUnits} Units (${p.occupancyRate.toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
              ),
              Text(
                'Avg: ${_currencyFormatter.format(p.averageRentPerUnit)}/unit',
                style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (p.occupancyRate / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                p.occupancyRate >= 90
                    ? AppTheme.statusPaid
                    : (p.occupancyRate >= 70 ? Colors.amber.shade700 : AppTheme.statusOverdue),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Financial Matrix Row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPropertySubMetric('Potential', _currencyFormatter.format(p.potentialRevenue), color: AppTheme.ink),
                _buildPropertySubMetric('Collected', _currencyFormatter.format(p.collectedRevenue), color: Colors.green.shade800),
                _buildPropertySubMetric(
                  'Arrears',
                  _currencyFormatter.format(p.arrearsAmount),
                  color: p.arrearsAmount > 0 ? AppTheme.statusOverdue : AppTheme.inkMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySubMetric(String label, String value, {required Color color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.inkMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _BusinessBadge extends StatelessWidget {
  const _BusinessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'BUSINESS',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppTheme.ink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

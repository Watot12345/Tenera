import 'package:intl/intl.dart';
import 'tenant.dart';

class ArrearsAgingItem {
  final TenantBill tenant;
  final int daysOverdue;
  final int amount;

  const ArrearsAgingItem({
    required this.tenant,
    required this.daysOverdue,
    required this.amount,
  });
}

class ArrearsAgingBucket {
  final String label;
  final String subtitle;
  final int minDays;
  final int? maxDays;
  final List<ArrearsAgingItem> items;

  const ArrearsAgingBucket({
    required this.label,
    required this.subtitle,
    required this.minDays,
    this.maxDays,
    required this.items,
  });

  int get totalAmount => items.fold(0, (sum, i) => sum + i.amount);
  int get tenantCount => items.length;
}

class ArrearsAgingReport {
  final int totalArrears;
  final int totalDelinquentTenants;
  final List<ArrearsAgingBucket> buckets;

  const ArrearsAgingReport({
    required this.totalArrears,
    required this.totalDelinquentTenants,
    required this.buckets,
  });

  factory ArrearsAgingReport.fromTenants(List<TenantBill> tenants) {
    final overdueList = tenants.where((t) => t.isOverdue && !t.isPaid).toList();

    final items = overdueList.map((t) {
      int days = 5; // Default estimation
      // Parse days from statusText if present (e.g. "5 days late", "2 days late", "18 days overdue")
      final match = RegExp(r'(\d+)\s*(?:day|days)', caseSensitive: false).firstMatch(t.statusText);
      if (match != null) {
        days = int.tryParse(match.group(1) ?? '5') ?? 5;
      }
      return ArrearsAgingItem(
        tenant: t,
        daysOverdue: days,
        amount: t.amount,
      );
    }).toList();

    final b1 = ArrearsAgingBucket(
      label: '1–7 Days Late',
      subtitle: 'Recent Delinquency (Grace Period)',
      minDays: 1,
      maxDays: 7,
      items: items.where((i) => i.daysOverdue >= 1 && i.daysOverdue <= 7).toList(),
    );

    final b2 = ArrearsAgingBucket(
      label: '8–15 Days Late',
      subtitle: 'Grace Period Exceeded (Follow-up Needed)',
      minDays: 8,
      maxDays: 15,
      items: items.where((i) => i.daysOverdue >= 8 && i.daysOverdue <= 15).toList(),
    );

    final b3 = ArrearsAgingBucket(
      label: '16–30 Days Late',
      subtitle: 'Serious Arrears (Notice of Demand)',
      minDays: 16,
      maxDays: 30,
      items: items.where((i) => i.daysOverdue >= 16 && i.daysOverdue <= 30).toList(),
    );

    final b4 = ArrearsAgingBucket(
      label: '30+ Days Late',
      subtitle: 'Chronic Delinquency (Eviction Risk)',
      minDays: 31,
      maxDays: null,
      items: items.where((i) => i.daysOverdue > 30).toList(),
    );

    final total = items.fold(0, (sum, i) => sum + i.amount);

    return ArrearsAgingReport(
      totalArrears: total,
      totalDelinquentTenants: items.length,
      buckets: [b1, b2, b3, b4],
    );
  }

  String generateReportText({String? propertyName}) {
    final buffer = StringBuffer();
    final fmt = NumberFormat('#,###');
    buffer.writeln('========================================');
    buffer.writeln('TENERA ARREARS & DEBT AGING REPORT');
    if (propertyName != null && propertyName.isNotEmpty) {
      buffer.writeln('Property: $propertyName');
    }
    buffer.writeln('Date: ${DateFormat('MMMM d, y').format(DateTime.now())}');
    buffer.writeln('========================================');
    buffer.writeln('TOTAL OVERDUE ARREARS: ₱${fmt.format(totalArrears)}');
    buffer.writeln('DELINQUENT TENANTS: $totalDelinquentTenants');
    buffer.writeln('----------------------------------------');

    for (final bucket in buckets) {
      final pct = totalArrears > 0 ? (bucket.totalAmount / totalArrears * 100).toStringAsFixed(1) : '0.0';
      buffer.writeln('');
      buffer.writeln('[${bucket.label.toUpperCase()}] - ₱${fmt.format(bucket.totalAmount)} ($pct% of debt)');
      buffer.writeln('Status: ${bucket.subtitle}');
      if (bucket.items.isEmpty) {
        buffer.writeln('• None (All caught up)');
      } else {
        for (final item in bucket.items) {
          buffer.writeln('• ${item.tenant.name} (${item.tenant.location}): ₱${fmt.format(item.amount)} · ${item.daysOverdue} days late');
        }
      }
    }

    buffer.writeln('');
    buffer.writeln('========================================');
    buffer.writeln('Generated via Tenera Property Manager (PRD FR-H3 compliant)');
    return buffer.toString();
  }
}

class TenantBill {
  final String id;
  final String name;
  final String initials;
  final String location;
  final int amount;
  final String statusText;
  final bool isOverdue;
  bool isPaid;
  final String? phone;
  final String? messenger;
  final bool automatedReminders;
  final String? idPhotoPath;
  final int gracePeriodDays;
  final int lateFeeDaily;
  final int lateFeeFlat;
  final bool isLateFeeWaived;

  TenantBill({
    required this.id,
    required this.name,
    required this.initials,
    required this.location,
    required this.amount,
    required this.statusText,
    required this.isOverdue,
    this.isPaid = false,
    this.phone,
    this.messenger,
    this.automatedReminders = true,
    this.idPhotoPath,
    this.gracePeriodDays = 3,
    this.lateFeeDaily = 0,
    this.lateFeeFlat = 0,
    this.isLateFeeWaived = false,
  });

  /// Calculates automated late fee penalty based on grace period and daily/flat rate (PRD FR-D5)
  int calculateLateFee({int? daysOverdue}) {
    if (isLateFeeWaived || !isOverdue || isPaid) return 0;
    if (lateFeeDaily <= 0 && lateFeeFlat <= 0) return 0;

    int days = daysOverdue ?? 0;
    if (days <= 0) {
      final match = RegExp(r'(\d+)\s*(?:day|days)', caseSensitive: false).firstMatch(statusText);
      if (match != null) {
        days = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    if (days <= gracePeriodDays) return 0;

    int fee = lateFeeFlat;
    if (lateFeeDaily > 0) {
      final lateDays = days - gracePeriodDays;
      fee += lateDays * lateFeeDaily;
    }
    return fee;
  }

  /// Total amount due including calculated late fee penalty
  int get totalDueWithLateFee => amount + calculateLateFee();

  TenantBill copyWith({
    String? id,
    String? name,
    String? initials,
    String? location,
    int? amount,
    String? statusText,
    bool? isOverdue,
    bool? isPaid,
    String? phone,
    String? messenger,
    bool? automatedReminders,
    String? idPhotoPath,
    int? gracePeriodDays,
    int? lateFeeDaily,
    int? lateFeeFlat,
    bool? isLateFeeWaived,
  }) {
    return TenantBill(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      location: location ?? this.location,
      amount: amount ?? this.amount,
      statusText: statusText ?? this.statusText,
      isOverdue: isOverdue ?? this.isOverdue,
      isPaid: isPaid ?? this.isPaid,
      phone: phone ?? this.phone,
      messenger: messenger ?? this.messenger,
      automatedReminders: automatedReminders ?? this.automatedReminders,
      idPhotoPath: idPhotoPath ?? this.idPhotoPath,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      lateFeeDaily: lateFeeDaily ?? this.lateFeeDaily,
      lateFeeFlat: lateFeeFlat ?? this.lateFeeFlat,
      isLateFeeWaived: isLateFeeWaived ?? this.isLateFeeWaived,
    );
  }
}

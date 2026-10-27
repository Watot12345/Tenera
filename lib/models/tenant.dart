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
  });

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
    );
  }
}

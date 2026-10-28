class PaymentRecord {
  final String id;
  final String tenantName;
  final String location;
  final int amount;
  final String method;
  final String dateFormatted;
  final String? referenceNo;
  final String? cashImageName;
  final bool isVoided;
  final String? voidReason;

  PaymentRecord({
    required this.id,
    required this.tenantName,
    required this.location,
    required this.amount,
    required this.method,
    required this.dateFormatted,
    this.referenceNo,
    this.cashImageName,
    this.isVoided = false,
    this.voidReason,
  });

  PaymentRecord copyWith({
    String? id,
    String? tenantName,
    String? location,
    int? amount,
    String? method,
    String? dateFormatted,
    String? referenceNo,
    String? cashImageName,
    bool? isVoided,
    String? voidReason,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      tenantName: tenantName ?? this.tenantName,
      location: location ?? this.location,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      referenceNo: referenceNo ?? this.referenceNo,
      cashImageName: cashImageName ?? this.cashImageName,
      isVoided: isVoided ?? this.isVoided,
      voidReason: voidReason ?? this.voidReason,
    );
  }
}

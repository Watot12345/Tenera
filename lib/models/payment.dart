class PaymentRecord {
  final String id;
  final String tenantName;
  final String location;
  final int amount;
  final String method;
  final String dateFormatted;
  final String? referenceNo;
  final String? cashImageName;

  PaymentRecord({
    required this.id,
    required this.tenantName,
    required this.location,
    required this.amount,
    required this.method,
    required this.dateFormatted,
    this.referenceNo,
    this.cashImageName,
  });
}

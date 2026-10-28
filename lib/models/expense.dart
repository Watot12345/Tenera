class ExpenseRecord {
  final String id;
  final String? propertyId;
  final String propertyName;
  final String category;
  final String description;
  final int amount;
  final String dateFormatted;
  final String? receiptRef;
  final int createdAt;

  const ExpenseRecord({
    required this.id,
    this.propertyId,
    required this.propertyName,
    required this.category,
    required this.description,
    required this.amount,
    required this.dateFormatted,
    this.receiptRef,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'property_name': propertyName,
      'category': category,
      'description': description,
      'amount': amount,
      'date_formatted': dateFormatted,
      'receipt_ref': receiptRef,
      'created_at': createdAt,
      'is_synced': 0,
    };
  }

  factory ExpenseRecord.fromMap(Map<String, Object?> map) {
    return ExpenseRecord(
      id: map['id'] as String,
      propertyId: map['property_id'] as String?,
      propertyName: map['property_name'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      amount: map['amount'] as int,
      dateFormatted: map['date_formatted'] as String,
      receiptRef: map['receipt_ref'] as String?,
      createdAt: (map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  ExpenseRecord copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? category,
    String? description,
    int? amount,
    String? dateFormatted,
    String? receiptRef,
    int? createdAt,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      receiptRef: receiptRef ?? this.receiptRef,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

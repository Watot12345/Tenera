class MaintenanceTicket {
  final String id;
  final String propertyId;
  final String propertyName;
  final String roomCode;
  final String title;
  final String description;
  final String category; // Plumbing, Electrical, Carpentry, Appliance, General
  final String priority; // Low, Medium, High, Emergency
  final String status; // Reported, In Progress, Resolved
  final int? cost;
  final String reportedDate;
  final String? resolvedDate;
  final int createdAt;

  const MaintenanceTicket({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.roomCode,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.cost,
    required this.reportedDate,
    this.resolvedDate,
    required this.createdAt,
  });

  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isInProgress => status.toLowerCase() == 'in progress';
  bool get isReported => status.toLowerCase() == 'reported';

  MaintenanceTicket copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? roomCode,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    int? cost,
    String? reportedDate,
    String? resolvedDate,
    int? createdAt,
  }) {
    return MaintenanceTicket(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      roomCode: roomCode ?? this.roomCode,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      reportedDate: reportedDate ?? this.reportedDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'property_name': propertyName,
      'room_code': roomCode,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'cost': cost,
      'reported_date': reportedDate,
      'resolved_date': resolvedDate,
      'created_at': createdAt,
      'is_synced': 0,
    };
  }

  factory MaintenanceTicket.fromMap(Map<String, dynamic> map) {
    return MaintenanceTicket(
      id: map['id'] as String,
      propertyId: map['property_id'] as String? ?? '',
      propertyName: map['property_name'] as String? ?? 'General',
      roomCode: map['room_code'] as String? ?? 'All',
      title: map['title'] as String? ?? 'Repair Request',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Reported',
      cost: map['cost'] as int?,
      reportedDate: map['reported_date'] as String? ?? '',
      resolvedDate: map['resolved_date'] as String?,
      createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

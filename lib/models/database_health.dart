class DatabaseHealthReport {
  final bool isHealthy;
  final String integrityMessage;
  final int propertyCount;
  final int roomCount;
  final int tenantCount;
  final int paymentCount;
  final int expenseCount;
  final int maintenanceCount;
  final int totalRecords;
  final String databaseVersion;
  final DateTime checkedAt;

  const DatabaseHealthReport({
    required this.isHealthy,
    required this.integrityMessage,
    required this.propertyCount,
    required this.roomCount,
    required this.tenantCount,
    required this.paymentCount,
    required this.expenseCount,
    required this.maintenanceCount,
    required this.totalRecords,
    required this.databaseVersion,
    required this.checkedAt,
  });
}

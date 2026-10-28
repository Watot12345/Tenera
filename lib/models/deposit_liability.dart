class DepositLiabilityItem {
  final String roomCode;
  final String propertyName;
  final String? tenantName;
  final int depositHeld;
  final String status;

  const DepositLiabilityItem({
    required this.roomCode,
    required this.propertyName,
    this.tenantName,
    required this.depositHeld,
    required this.status,
  });
}

class DepositLiabilitySummary {
  final int totalDepositLiability;
  final int totalOccupiedUnits;
  final List<DepositLiabilityItem> depositItems;

  const DepositLiabilitySummary({
    required this.totalDepositLiability,
    required this.totalOccupiedUnits,
    required this.depositItems,
  });
}

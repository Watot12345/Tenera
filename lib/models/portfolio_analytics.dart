class PropertyAnalyticsItem {
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final int totalUnits;
  final int occupiedUnits;
  final int overdueUnits;
  final int vacantUnits;
  final int potentialRevenue; // Expected monthly gross rent
  final int collectedRevenue; // Rent collected for this property
  final int arrearsAmount; // Delinquent/overdue balance for this property
  final double occupancyRate; // (occupiedUnits / totalUnits) * 100
  final double collectionRate; // (collectedRevenue / potentialRevenue) * 100
  final double revenueSharePercent; // percentage contribution to portfolio total
  final int averageRentPerUnit; // potentialRevenue / totalUnits

  const PropertyAnalyticsItem({
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.overdueUnits,
    required this.vacantUnits,
    required this.potentialRevenue,
    required this.collectedRevenue,
    required this.arrearsAmount,
    required this.occupancyRate,
    required this.collectionRate,
    required this.revenueSharePercent,
    required this.averageRentPerUnit,
  });
}

class PortfolioAnalyticsSummary {
  final int totalProperties;
  final int totalUnits;
  final int totalOccupied;
  final int totalOverdue;
  final int totalVacant;
  final int totalPotentialMonthlyRent;
  final int totalCollected;
  final int totalArrears;
  final double overallOccupancyRate;
  final double overallCollectionRate;
  final List<PropertyAnalyticsItem> propertyItems;

  const PortfolioAnalyticsSummary({
    required this.totalProperties,
    required this.totalUnits,
    required this.totalOccupied,
    required this.totalOverdue,
    required this.totalVacant,
    required this.totalPotentialMonthlyRent,
    required this.totalCollected,
    required this.totalArrears,
    required this.overallOccupancyRate,
    required this.overallCollectionRate,
    required this.propertyItems,
  });
}

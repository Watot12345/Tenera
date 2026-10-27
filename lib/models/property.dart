enum RoomStatus { occupied, vacant, overdue }

class RoomUnit {
  final String code;
  final RoomStatus status;
  final String? tenantName;
  final int? rentAmount;
  final String? statusText;

  const RoomUnit({
    required this.code,
    required this.status,
    this.tenantName,
    this.rentAmount,
    this.statusText,
  });
}

class PropertyItem {
  final String id;
  final String name;
  final String address;
  final int totalUnits;
  final int occupiedUnits;
  final int monthlyRevenue;
  final List<RoomUnit> rooms;

  PropertyItem({
    required this.id,
    required this.name,
    required this.address,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.monthlyRevenue,
    required this.rooms,
  });

  int get vacantUnits => totalUnits - occupiedUnits;

  PropertyItem copyWith({
    String? id,
    String? name,
    String? address,
    int? totalUnits,
    int? occupiedUnits,
    int? monthlyRevenue,
    List<RoomUnit>? rooms,
  }) {
    return PropertyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      totalUnits: totalUnits ?? this.totalUnits,
      occupiedUnits: occupiedUnits ?? this.occupiedUnits,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      rooms: rooms ?? this.rooms,
    );
  }
}

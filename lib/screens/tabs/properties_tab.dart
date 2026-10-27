import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/property.dart';
import '../../theme/app_theme.dart';

class PropertiesTab extends StatelessWidget {
  final List<PropertyItem> properties;
  final VoidCallback onAddProperty;
  final Function(PropertyItem?) onViewRooms;

  const PropertiesTab({
    super.key,
    required this.properties,
    required this.onAddProperty,
    required this.onViewRooms,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final totalUnits = properties.fold(0, (sum, p) => sum + p.totalUnits);
    final occupiedUnits = properties.fold(0, (sum, p) => sum + p.occupiedUnits);
    final vacantUnits = totalUnits - occupiedUnits;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Overview Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryDeep,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDeep.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppTheme.ink,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Portfolio',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${properties.length} Properties · $totalUnits Units',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$occupiedUnits Occupied · $vacantUnits Vacant',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Properties',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton.filledTonal(
                onPressed: onAddProperty,
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: 'Add Property',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Property Cards List
          Column(
            children: [
              if (properties.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 48,
                        color: AppTheme.inkMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No properties added yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap the + button above to add your first rental building.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.inkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (int index = 0; index < properties.length; index++) ...[
                  if (index > 0) const SizedBox(height: 14),
                  _buildPropertyCard(context, properties[index], currencyFormat),
                ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyItem prop, NumberFormat currencyFormat) {
    final overdueCount = prop.rooms.where((r) => r.status == RoomStatus.overdue).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.domain_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prop.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: overdueCount > 0 ? const Color(0xFFFFECEB) : AppTheme.statusPaidBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${prop.occupiedUnits}/${prop.totalUnits} Units',
                  style: TextStyle(
                    color: overdueCount > 0 ? const Color(0xFFC92A2A) : AppTheme.statusPaid,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expected / Month',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  Text(
                    '₱${currencyFormat.format(prop.monthlyRevenue)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => onViewRooms(prop),
                icon: const Icon(Icons.meeting_room_outlined, size: 16),
                label: const Text('View Rooms'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/property.dart';
import '../../services/plan_guard_service.dart';
import '../../theme/app_theme.dart';
import '../portfolio_analytics_screen.dart';

class PropertiesTab extends StatelessWidget {
  final List<PropertyItem> properties;
  final VoidCallback onAddProperty;
  final Function(PropertyItem?) onViewRooms;
  final Future<void> Function(PropertyItem)? onDeleteProperty;
  final bool isStaffMode;
  final bool isBusiness;

  const PropertiesTab({
    super.key,
    required this.properties,
    required this.onAddProperty,
    required this.onViewRooms,
    this.onDeleteProperty,
    this.isStaffMode = false,
    this.isBusiness = false,
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
              color: AppTheme.isDark(context) ? AppTheme.getHeroCardColor(context) : AppTheme.primaryDeep,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDeep.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            '$occupiedUnits Occupied · $vacantUnits Vacant · ${isStaffMode ? '••••••' : '₱${currencyFormat.format(properties.fold<int>(0, (sum, p) => sum + p.monthlyRevenue))}/mo'}',
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
                if (isBusiness && !isStaffMode) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Colors.white24),
                  const SizedBox(height: 12),
                  InkWell(
                    key: const Key('btn_open_portfolio_analytics'),
                    onTap: () async {
                      final canAccess = await PlanGuardService.requireBusiness(
                        context: context,
                        featureName: 'Portfolio Analytics',
                        featureBenefit: 'Unlock cross-property yield comparisons, collection efficiency metrics, and portfolio CSV exports.',
                      );
                      if (!canAccess || !context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PortfolioAnalyticsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_rounded, color: AppTheme.accent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Multi-Property Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          _PropertiesBusinessBadge(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Properties',
                style: TextStyle(
                  color: AppTheme.getInkColor(context),
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
                    color: AppTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 48,
                        color: AppTheme.getInkMutedColor(context).withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No properties added yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getInkColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the + button above to add your first rental building.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getInkMutedColor(context),
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

  void _confirmDeleteProperty(BuildContext context, PropertyItem prop) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = AppTheme.isDark(dialogCtx);
        final deleteColor = isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A);

        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: deleteColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: deleteColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Property',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.getInkColor(dialogCtx),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${prop.name}"?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getInkColor(dialogCtx),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently delete this property, along with all ${prop.totalUnits} rooms and tenant records from your phone.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.getInkMutedColor(dialogCtx),
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_delete_property'),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                if (onDeleteProperty != null) {
                  await onDeleteProperty!(prop);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: deleteColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Delete Property',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyItem prop, NumberFormat currencyFormat) {
    final overdueCount = prop.rooms.where((r) => r.status == RoomStatus.overdue).length;

    return Material(
      color: AppTheme.getSurfaceColor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('property_card_${prop.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => onViewRooms(prop),
        onLongPress: () => _confirmDeleteProperty(context, prop),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.8)),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getInkColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prop.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getInkMutedColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: overdueCount > 0 ? AppTheme.getStatusOverdueBg(context) : AppTheme.getStatusPaidBg(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${prop.occupiedUnits}/${prop.totalUnits} Units',
                      style: TextStyle(
                        color: overdueCount > 0 ? AppTheme.getStatusOverdueText(context) : AppTheme.getStatusPaidText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: AppTheme.getBorderColor(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected / Month',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getInkMutedColor(context),
                        ),
                      ),
                      Text(
                        isStaffMode ? '••••••' : '₱${currencyFormat.format(prop.monthlyRevenue)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getPrimaryColor(context),
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
        ),
      ),
    );
  }
}

class _PropertiesBusinessBadge extends StatelessWidget {
  const _PropertiesBusinessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'BUSINESS',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppTheme.ink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

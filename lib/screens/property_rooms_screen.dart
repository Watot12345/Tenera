import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../services/database_helper.dart';
import '../services/plan_guard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashed_border_painter.dart';

class PropertyRoomsScreen extends StatefulWidget {
  final List<PropertyItem> properties;
  final PropertyItem? initialProperty;
  final Function(PropertyItem, RoomUnit)? onRoomTap;
  final Function(PropertyItem, RoomUnit)? onRoomAdded;
  final Function(PropertyItem, String roomCode)? onTenantRemoved;
  final Function(TenantBill)? onRecordPayment;
  final Function(TenantBill)? onSendReminder;
  final Function(String location)? onAssignTenant;

  const PropertyRoomsScreen({
    super.key,
    required this.properties,
    this.initialProperty,
    this.onRoomTap,
    this.onRoomAdded,
    this.onTenantRemoved,
    this.onRecordPayment,
    this.onSendReminder,
    this.onAssignTenant,
  });

  @override
  State<PropertyRoomsScreen> createState() => _PropertyRoomsScreenState();
}

class _PropertyRoomsScreenState extends State<PropertyRoomsScreen> {
  late List<PropertyItem> _properties;
  late String _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<void>? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _properties = List.from(widget.properties);
    _selectedFilter = widget.initialProperty?.name ?? 'All';
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _dbSubscription = DatabaseHelper.instance.changes.listen((_) async {
        try {
          final updatedProps = await DatabaseHelper.instance.getProperties();
          if (mounted) {
            setState(() {
              _properties = updatedProps;
            });
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddRoomDialog() async {
    if (_properties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a property before adding rooms.')),
      );
      return;
    }

    final totalCurrentUnits = _properties.fold(0, (sum, p) => sum + p.totalUnits);
    final canAdd = await PlanGuardService.canAddUnits(
      context: context,
      currentTotalUnits: totalCurrentUnits,
      incomingUnits: 1,
    );
    if (!canAdd || !mounted) return;

    final codeController = TextEditingController();
    final rentController = TextEditingController(text: '4000');
    final tenantController = TextEditingController();

    // Default to currently selected property or the first property in list
    PropertyItem targetProp = _properties.firstWhere(
      (p) => p.name == _selectedFilter,
      orElse: () => _properties.first,
    );

    RoomStatus newStatus = RoomStatus.vacant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurfaceElevatedColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.getBorderColor(modalCtx),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_home_rounded, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Room / Unit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.getInkColor(modalCtx),
                                ),
                              ),
                              Text(
                                'Add unit to your property grid',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getInkMutedColor(modalCtx),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Property Selection
                    Text('Property', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(modalCtx))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PropertyItem>(
                      initialValue: targetProp,
                      dropdownColor: AppTheme.getSurfaceColor(modalCtx),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _properties.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(modalCtx))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => targetProp = val);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Room Code Field
                    Text('Room / Unit Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(modalCtx))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'e.g. 3A, Room 7, Unit 102',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.door_front_door_outlined, size: 20),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Monthly Rent Field
                    Text('Monthly Rent (₱)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(modalCtx))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: rentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '4000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Initial Status
                    Text('Initial Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(modalCtx))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => newStatus = RoomStatus.vacant),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: newStatus == RoomStatus.vacant ? AppTheme.primaryDeep : AppTheme.getBackgroundColor(modalCtx),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: newStatus == RoomStatus.vacant ? AppTheme.primaryDeep : AppTheme.getBorderColor(modalCtx),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Vacant',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: newStatus == RoomStatus.vacant ? Colors.white : AppTheme.getInkColor(modalCtx),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => newStatus = RoomStatus.occupied),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: newStatus == RoomStatus.occupied ? AppTheme.primary : AppTheme.getBackgroundColor(modalCtx),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: newStatus == RoomStatus.occupied ? AppTheme.primary : AppTheme.getBorderColor(modalCtx),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Occupied',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: newStatus == RoomStatus.occupied ? Colors.white : AppTheme.getInkColor(modalCtx),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (newStatus == RoomStatus.occupied) ...[
                      const SizedBox(height: 14),
                      Text('Tenant Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(modalCtx))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: tenantController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Juan dela Cruz',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final code = codeController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter a room code.')),
                            );
                            return;
                          }

                          final rent = int.tryParse(rentController.text.trim()) ?? 4000;
                          final tenantName = tenantController.text.trim();

                          final newRoom = RoomUnit(
                            code: code,
                            status: newStatus,
                            tenantName: newStatus == RoomStatus.occupied && tenantName.isNotEmpty
                                ? tenantName
                                : (newStatus == RoomStatus.occupied ? 'Active Tenant' : null),
                            rentAmount: rent,
                            statusText: newStatus == RoomStatus.occupied ? 'Paid' : null,
                          );

                          Navigator.pop(ctx);

                          setState(() {
                            final idx = _properties.indexWhere((p) => p.id == targetProp.id);
                            if (idx != -1) {
                              final updatedRooms = [..._properties[idx].rooms, newRoom];
                              final newOccupied = updatedRooms.where((r) => r.status != RoomStatus.vacant).length;
                              final newRev = updatedRooms.where((r) => r.status != RoomStatus.vacant).fold(0, (sum, r) => sum + (r.rentAmount ?? 0));
                              _properties[idx] = _properties[idx].copyWith(
                                totalUnits: updatedRooms.length,
                                occupiedUnits: newOccupied,
                                monthlyRevenue: newRev,
                                rooms: updatedRooms,
                              );
                            }
                          });

                          widget.onRoomAdded?.call(targetProp, newRoom);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryDeep,
                              content: Text('Room $code successfully added to ${targetProp.name}!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Room to Property', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRemoveTenant(BuildContext modalCtx, PropertyItem prop, RoomUnit room) {
    final currencyFormat = NumberFormat('#,###');
    final int depositHeld = room.rentAmount ?? 3500;
    final deductionsCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final int deductions = int.tryParse(deductionsCtrl.text.replaceAll(',', '').trim()) ?? 0;
            final int netRefund = depositHeld - deductions;

            return AlertDialog(
              backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFECEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.assignment_turned_in_rounded, color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remove Tenant',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.getInkColor(dialogCtx)),
                        ),
                        Text(
                          'Move-Out & Deposit Settlement · Unit ${room.code}',
                          style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(dialogCtx)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to remove ${room.tenantName ?? "the tenant"} from Unit ${room.code} in ${prop.name}?',
                      style: TextStyle(fontSize: 14, color: AppTheme.getInkColor(dialogCtx)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Settle the tenant\'s security deposit and deduct any unpaid bills or repairs (PRD FR-D7):',
                      style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(dialogCtx), height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    // Security deposit summary box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor(dialogCtx),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getBorderColor(dialogCtx)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Security Deposit Held', style: TextStyle(fontSize: 13, color: AppTheme.getInkMutedColor(dialogCtx))),
                              Text('₱${currencyFormat.format(depositHeld)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.getInkColor(dialogCtx))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Deductions', style: TextStyle(fontSize: 13, color: Color(0xFFC0392B))),
                              Text('-₱${currencyFormat.format(deductions)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFC0392B))),
                            ],
                          ),
                          Divider(height: 16, color: AppTheme.getBorderColor(dialogCtx)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(netRefund >= 0 ? 'Net Refund to Tenant' : 'Tenant Balance Due', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(dialogCtx))),
                              Text(
                                '₱${currencyFormat.format(netRefund.abs())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: netRefund >= 0 ? AppTheme.getStatusPaidText(dialogCtx) : const Color(0xFFC0392B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: deductionsCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      style: TextStyle(color: AppTheme.getInkColor(dialogCtx)),
                      decoration: InputDecoration(
                        labelText: 'Deductions Amount (₱)',
                        hintText: 'e.g. 500',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      style: TextStyle(color: AppTheme.getInkColor(dialogCtx)),
                      decoration: InputDecoration(
                        labelText: 'Deductions Itemization / Notes',
                        hintText: 'e.g. Unpaid water bill ₱250, wall cleaning ₱250',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    if (Navigator.canPop(modalCtx)) {
                      Navigator.pop(modalCtx);
                    }
                    _removeTenantFromRoom(
                      prop,
                      room,
                      netRefund: netRefund,
                      deductions: deductions,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC92A2A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Remove Tenant'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeTenantFromRoom(
    PropertyItem prop,
    RoomUnit room, {
    int? netRefund,
    int? deductions,
  }) {
    final currencyFormat = NumberFormat('#,###');
    setState(() {
      final pIdx = _properties.indexWhere((p) => p.id == prop.id);
      if (pIdx != -1) {
        final updatedRooms = _properties[pIdx].rooms.map((r) {
          if (r.code == room.code) {
            return RoomUnit(
              code: r.code,
              status: RoomStatus.vacant,
              tenantName: null,
              rentAmount: r.rentAmount,
              statusText: null,
            );
          }
          return r;
        }).toList();

        final newOccupied = updatedRooms.where((r) => r.status != RoomStatus.vacant).length;
        final newRev = updatedRooms
            .where((r) => r.status != RoomStatus.vacant)
            .fold(0, (sum, r) => sum + (r.rentAmount ?? 0));

        _properties[pIdx] = _properties[pIdx].copyWith(
          occupiedUnits: newOccupied,
          monthlyRevenue: newRev,
          rooms: updatedRooms,
        );
      }
    });

    widget.onTenantRemoved?.call(prop, room.code);

    final refundMsg = netRefund != null
        ? (netRefund >= 0
            ? ' (Refund: ₱${currencyFormat.format(netRefund)})'
            : ' (Balance Due: ₱${currencyFormat.format(netRefund.abs())})')
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryDeep,
        content: Text('✓ Move-out settled for ${room.tenantName ?? "Tenant"}$refundMsg. Unit ${room.code} is now Vacant.'),
      ),
    );
  }

  void _showRoomDetails(PropertyItem prop, RoomUnit room) {
    if (widget.onRoomTap != null) {
      widget.onRoomTap!(prop, room);
      return;
    }

    final currencyFormat = NumberFormat('#,###');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceElevatedColor(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Room Code and Property
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: room.status == RoomStatus.overdue
                          ? (isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFECEB))
                          : (room.status == RoomStatus.occupied
                              ? (isDark ? const Color(0xFF133833) : const Color(0xFFE2F3EF))
                              : (isDark ? const Color(0xFF243633) : AppTheme.getBorderColor(ctx).withValues(alpha: 0.5))),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      room.status == RoomStatus.overdue
                          ? Icons.error_outline_rounded
                          : (room.status == RoomStatus.occupied
                              ? Icons.meeting_room_rounded
                              : Icons.door_front_door_outlined),
                      color: room.status == RoomStatus.overdue
                          ? (isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A))
                          : (room.status == RoomStatus.occupied
                              ? AppTheme.primary
                              : AppTheme.getInkMutedColor(ctx)),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit ${room.code} · ${prop.name}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getInkColor(ctx),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prop.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getInkMutedColor(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppTheme.getInkMutedColor(ctx)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Status Badge Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: room.status == RoomStatus.overdue
                      ? (isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFECEB))
                      : (room.status == RoomStatus.occupied
                          ? AppTheme.getStatusPaidBg(ctx)
                          : AppTheme.getBackgroundColor(ctx)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: room.status == RoomStatus.overdue
                        ? (isDark ? const Color(0xFF6B2B32) : const Color(0xFFFFD4D1))
                        : (room.status == RoomStatus.occupied
                            ? AppTheme.getStatusPaidText(ctx).withValues(alpha: 0.3)
                            : AppTheme.getBorderColor(ctx)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      room.status == RoomStatus.overdue
                          ? Icons.warning_amber_rounded
                          : (room.status == RoomStatus.occupied
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded),
                      size: 18,
                      color: room.status == RoomStatus.overdue
                          ? (isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A))
                          : (room.status == RoomStatus.occupied
                              ? AppTheme.getStatusPaidText(ctx)
                              : AppTheme.getInkMutedColor(ctx)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      room.status == RoomStatus.overdue
                          ? 'STATUS: OVERDUE (${room.statusText ?? "Payment Late"})'
                          : (room.status == RoomStatus.occupied
                              ? 'STATUS: OCCUPIED (${room.statusText ?? "Active Lease"})'
                              : 'STATUS: VACANT (Available for Rent)'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: room.status == RoomStatus.overdue
                            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A))
                            : (room.status == RoomStatus.occupied
                                ? AppTheme.getStatusPaidText(ctx)
                                : AppTheme.getInkMutedColor(ctx)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tenant Details Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(ctx),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorderColor(ctx)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      key: const Key('tenant_assign_row'),
                      onLongPress: room.status != RoomStatus.vacant
                          ? () => _confirmRemoveTenant(ctx, prop, room)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tenant Assigned',
                                  style: TextStyle(color: AppTheme.getInkMutedColor(ctx), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                if (room.status != RoomStatus.vacant)
                                  Text(
                                    'Press & hold to remove tenant',
                                    style: TextStyle(color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  room.status == RoomStatus.vacant
                                      ? 'None (Vacant)'
                                      : (room.tenantName ?? 'Active Tenant'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: room.status == RoomStatus.vacant ? AppTheme.getInkMutedColor(ctx) : AppTheme.getInkColor(ctx),
                                  ),
                                ),
                                if (room.status != RoomStatus.vacant) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.touch_app_rounded, size: 16, color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 20, color: AppTheme.getBorderColor(ctx)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Rent',
                          style: TextStyle(color: AppTheme.getInkMutedColor(ctx), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₱${currencyFormat.format(room.rentAmount ?? 0)} / mo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                    if (room.status != RoomStatus.vacant) ...[
                      Divider(height: 20, color: AppTheme.getBorderColor(ctx)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Details',
                            style: TextStyle(color: AppTheme.getInkMutedColor(ctx), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            room.statusText ?? (room.status == RoomStatus.overdue ? 'Overdue' : 'Paid'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: room.status == RoomStatus.overdue
                                  ? (isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A))
                                  : AppTheme.getStatusPaidText(ctx),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (room.status == RoomStatus.vacant)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.onAssignTenant != null) {
                        widget.onAssignTenant!('Unit ${room.code} · ${prop.name}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Assigning tenant to Unit ${room.code}...')),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text('Assign Tenant to Unit ${room.code}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else if (room.status == RoomStatus.overdue)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (widget.onSendReminder != null) {
                            final tenant = TenantBill(
                              id: 't_${room.code}',
                              name: room.tenantName ?? 'Tenant',
                              initials: (room.tenantName ?? 'TN').substring(0, (room.tenantName ?? 'TN').length >= 2 ? 2 : 1).toUpperCase(),
                              location: 'Unit ${room.code} · ${prop.name}',
                              amount: room.rentAmount ?? 3500,
                              statusText: room.statusText ?? 'Overdue',
                              isOverdue: true,
                            );
                            widget.onSendReminder!(tenant);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.primaryDeep,
                                content: Text('Reminder sent to ${room.tenantName}!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: const Text('Send Reminder'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (widget.onRecordPayment != null) {
                            final tenant = TenantBill(
                              id: 't_${room.code}',
                              name: room.tenantName ?? 'Tenant',
                              initials: (room.tenantName ?? 'TN').substring(0, (room.tenantName ?? 'TN').length >= 2 ? 2 : 1).toUpperCase(),
                              location: 'Unit ${room.code} · ${prop.name}',
                              amount: room.rentAmount ?? 3500,
                              statusText: room.statusText ?? 'Overdue',
                              isOverdue: true,
                            );
                            widget.onRecordPayment!(tenant);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.statusPaid,
                                content: Text('Payment recorded for ${room.tenantName}!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Record Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryDeep,
                              content: Text('Calling ${room.tenantName}...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Contact Tenant'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Paid · Up to date'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusPaidBg,
                          foregroundColor: AppTheme.statusPaid,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              if (room.status != RoomStatus.vacant) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    key: const Key('remove_tenant_button'),
                    onPressed: () => _confirmRemoveTenant(ctx, prop, room),
                    icon: const Icon(Icons.person_remove_rounded, size: 16, color: Color(0xFFC92A2A)),
                    label: const Text(
                      'Remove Tenant (Vacate Room)',
                      style: TextStyle(
                        color: Color(0xFFC92A2A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredProperties = _properties.where((prop) {
      if (_selectedFilter != 'All' && prop.name != _selectedFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final matchName = prop.name.toLowerCase().contains(query);
      final matchRoom = prop.rooms.any((r) => r.code.toLowerCase().contains(query));
      return matchName || matchRoom;
    }).toList();

    final totalUnits = _properties.fold(0, (sum, p) => sum + p.totalUnits);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.getInkColor(context)),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to Properties',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedFilter == 'All' ? 'View Rooms' : _selectedFilter,
              style: TextStyle(
                color: AppTheme.getInkColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _selectedFilter == 'All'
                  ? '${_properties.length} properties · $totalUnits units'
                  : '${_properties.firstWhere((p) => p.name == _selectedFilter, orElse: () => _properties.first).occupiedUnits} occupied units',
              style: TextStyle(
                color: AppTheme.getInkMutedColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_rounded, color: AppTheme.primary),
            tooltip: 'Add Room',
            onPressed: _openAddRoomDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddRoomDialog,
        backgroundColor: AppTheme.primaryDeep,
        elevation: 4,
        icon: const Icon(Icons.add_home_rounded, color: Colors.white),
        label: const Text(
          'Add Room',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  ..._properties.map((p) => p.name),
                ].map((filterName) {
                  final isSelected = _selectedFilter == filterName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filterName),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = filterName;
                        });
                      },
                      selectedColor: AppTheme.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.getInkColor(context),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppTheme.getInkColor(context)),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search property or unit',
                  hintStyle: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.getInkMutedColor(context), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppTheme.getInkMutedColor(context), size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Legend Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32), 'Occupied'),
                  _buildLegendItem(isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A), 'Overdue'),
                  _buildLegendItem(isDark ? const Color(0xFF8EAEA6) : const Color(0xFF546E7A), 'Vacant'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Visual Room Grids
            if (filteredProperties.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'No units found matching "$query"',
                  style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 14),
                ),
              )
            else
              Column(
                children: [
                  for (int index = 0; index < filteredProperties.length; index++) ...[
                    if (index > 0) const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final prop = filteredProperties[index];
                        final overdueCount = prop.rooms.where((r) => r.status == RoomStatus.overdue).length;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prop.name,
                                        style: TextStyle(
                                          color: AppTheme.getInkColor(context),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${prop.occupiedUnits} of ${prop.totalUnits} occupied',
                                        style: TextStyle(
                                          color: AppTheme.getInkMutedColor(context),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (overdueCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFECEB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            size: 13,
                                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$overdueCount overdue',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF133833) : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Up to date',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Room Unit Grid (6 columns per row matching mockup)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const crossAxisCount = 6;
                                  const spacing = 8.0;
                                  final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: prop.rooms.map((room) {
                                      return SizedBox(
                                        width: itemWidth,
                                        height: itemWidth,
                                        child: _buildRoomBlock(context, prop, room),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomBlock(BuildContext context, PropertyItem prop, RoomUnit room) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget content;
    if (room.status == RoomStatus.overdue) {
      content = Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFECEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF6B2B32) : const Color(0xFFFFD4D1), width: 1.2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                room.code,
                style: TextStyle(
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFEF4444) : const Color(0xFFC92A2A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (room.status == RoomStatus.occupied) {
      content = Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF133833) : const Color(0xFFE2F3EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF1E524B) : const Color(0xFFC4E8E0), width: 1.2),
        ),
        child: Center(
          child: Text(
            room.code,
            style: TextStyle(
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0C5A53),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      // Vacant with dashed border
      content = CustomPaint(
        painter: DashedBorderPainter(
          color: isDark ? const Color(0xFF334945) : const Color(0xFF90A4AE),
          radius: 12,
          dashLength: 3.5,
          dashGap: 2.5,
          strokeWidth: 1.2,
        ),
        child: Center(
          child: Text(
            room.code,
            style: TextStyle(
              color: isDark ? const Color(0xFF8EAEA6) : const Color(0xFF546E7A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showRoomDetails(prop, room),
      onLongPress: room.status != RoomStatus.vacant
          ? () => _confirmRemoveTenant(context, prop, room)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.getInkColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

enum UtilityType { electricity, water }

enum SplitMode { actualBill, fixedRate, equalSplit }

class RoomReadingData {
  final String roomCode;
  final String? tenantName;
  final bool isOccupied;
  final TextEditingController prevController;
  final TextEditingController currController;
  bool isIncluded;

  RoomReadingData({
    required this.roomCode,
    this.tenantName,
    required this.isOccupied,
    required this.prevController,
    required this.currController,
    this.isIncluded = true,
  });

  double get previousReading => double.tryParse(prevController.text.trim()) ?? 0.0;
  double get currentReading => double.tryParse(currController.text.trim()) ?? 0.0;

  bool get hasValidReading =>
      currController.text.trim().isNotEmpty && currentReading >= previousReading;

  double get consumption {
    if (currController.text.trim().isEmpty) return 0.0;
    final diff = currentReading - previousReading;
    return diff > 0 ? diff : 0.0;
  }
}

class UtilityCalculatorScreen extends StatefulWidget {
  final String? initialPropertyId;

  const UtilityCalculatorScreen({
    super.key,
    this.initialPropertyId,
  });

  @override
  State<UtilityCalculatorScreen> createState() => _UtilityCalculatorScreenState();
}

class _UtilityCalculatorScreenState extends State<UtilityCalculatorScreen> {
  UtilityType _utilityType = UtilityType.electricity;
  SplitMode _splitMode = SplitMode.actualBill;

  final TextEditingController _masterBillController = TextEditingController(text: '3500');
  final TextEditingController _fixedRateController = TextEditingController(text: '14.00');

  List<PropertyItem> _properties = [];
  PropertyItem? _selectedProperty;
  List<RoomReadingData> _roomReadings = [];
  bool _isLoading = true;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _loadPropertiesAndRooms();
  }

  @override
  void dispose() {
    _masterBillController.dispose();
    _fixedRateController.dispose();
    for (final r in _roomReadings) {
      r.prevController.dispose();
      r.currController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPropertiesAndRooms() async {
    setState(() => _isLoading = true);
    final props = await DatabaseHelper.instance.getProperties();

    if (!mounted) return;

    PropertyItem? chosenProp;
    if (widget.initialPropertyId != null) {
      chosenProp = props.firstWhere(
        (p) => p.id == widget.initialPropertyId,
        orElse: () => props.isNotEmpty ? props.first : PropertyItem(id: 'default', name: 'Main Property', address: '', totalUnits: 0, occupiedUnits: 0, monthlyRevenue: 0, rooms: []),
      );
    } else if (props.isNotEmpty) {
      chosenProp = props.first;
    }

    _properties = props;
    _selectedProperty = chosenProp;

    if (chosenProp != null) {
      await _setupRoomsForProperty(chosenProp);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _setupRoomsForProperty(PropertyItem property) async {
    final prefs = await SharedPreferences.getInstance();
    final typeKey = _utilityType == UtilityType.electricity ? 'electric' : 'water';
    final savedKey = 'utility_saved_readings_${property.id}_$typeKey';
    final savedJsonStr = prefs.getString(savedKey);

    Map<String, double> savedReadings = {};
    if (savedJsonStr != null) {
      try {
        final decoded = jsonDecode(savedJsonStr) as Map<String, dynamic>;
        savedReadings = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }

    // Clean up old controllers
    for (final r in _roomReadings) {
      r.prevController.dispose();
      r.currController.dispose();
    }

    final List<RoomReadingData> newReadings = [];
    for (final room in property.rooms) {
      final isOccupied = room.status != RoomStatus.vacant;
      final lastSavedCurr = savedReadings[room.code] ?? 0.0;
      final prevText = lastSavedCurr > 0 ? (lastSavedCurr % 1 == 0 ? lastSavedCurr.toInt().toString() : lastSavedCurr.toString()) : '0';

      final prevController = TextEditingController(text: prevText);
      final currController = TextEditingController();

      prevController.addListener(_onReadingChanged);
      currController.addListener(_onReadingChanged);

      newReadings.add(RoomReadingData(
        roomCode: room.code,
        tenantName: room.tenantName,
        isOccupied: isOccupied,
        prevController: prevController,
        currController: currController,
        isIncluded: isOccupied,
      ));
    }

    _roomReadings = newReadings;
  }

  void _onReadingChanged() {
    setState(() {});
  }

  void _switchUtilityType(UtilityType type) async {
    if (_utilityType == type) return;
    setState(() {
      _utilityType = type;
      if (type == UtilityType.electricity) {
        _fixedRateController.text = '14.00';
      } else {
        _fixedRateController.text = '45.00';
      }
    });
    if (_selectedProperty != null) {
      await _setupRoomsForProperty(_selectedProperty!);
      setState(() {});
    }
  }

  double get _masterBillAmount => double.tryParse(_masterBillController.text.trim()) ?? 0.0;
  double get _fixedRate => double.tryParse(_fixedRateController.text.trim()) ?? 0.0;

  double get _totalConsumption {
    double sum = 0.0;
    for (final r in _roomReadings) {
      if (r.isIncluded) {
        sum += r.consumption;
      }
    }
    return sum;
  }

  double get _effectiveRatePerUnit {
    if (_splitMode == SplitMode.fixedRate) {
      return _fixedRate;
    }
    if (_splitMode == SplitMode.actualBill) {
      final totalCons = _totalConsumption;
      if (totalCons <= 0 || _masterBillAmount <= 0) return 0.0;
      return _masterBillAmount / totalCons;
    }
    return 0.0;
  }

  int get _includedRoomsCount {
    return _roomReadings.where((r) => r.isIncluded).length;
  }

  double _calculateRoomCharge(RoomReadingData reading) {
    if (!reading.isIncluded) return 0.0;

    if (_splitMode == SplitMode.equalSplit) {
      final count = _includedRoomsCount;
      if (count <= 0) return 0.0;
      return _masterBillAmount / count;
    }

    final rate = _effectiveRatePerUnit;
    return reading.consumption * rate;
  }

  double get _totalAllocatedAmount {
    double total = 0.0;
    for (final r in _roomReadings) {
      total += _calculateRoomCharge(r);
    }
    return total;
  }

  String _formatNumber(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  Future<void> _saveReadings({bool quiet = false}) async {
    if (_selectedProperty == null) return;

    final prefs = await SharedPreferences.getInstance();
    final typeKey = _utilityType == UtilityType.electricity ? 'electric' : 'water';
    final savedKey = 'utility_saved_readings_${_selectedProperty!.id}_$typeKey';

    final Map<String, double> toSave = {};
    for (final r in _roomReadings) {
      if (r.currController.text.trim().isNotEmpty) {
        toSave[r.roomCode] = r.currentReading;
      } else if (r.prevController.text.trim().isNotEmpty) {
        toSave[r.roomCode] = r.previousReading;
      }
    }

    await prefs.setString(savedKey, jsonEncode(toSave));

    if (!mounted || quiet) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryDeep,
        content: Text(
          '✓ Saved readings for ${_selectedProperty!.name}! These will automatically become next month\'s Previous Readings.',
        ),
      ),
    );
  }

  Future<void> _postChargesToTenants() async {
    if (_selectedProperty == null) return;

    final typeLabel = _utilityType == UtilityType.electricity ? 'Electricity' : 'Water';
    final Map<String, double> roomCharges = {};
    for (final r in _roomReadings) {
      if (r.isIncluded && r.isOccupied) {
        final charge = _calculateRoomCharge(r);
        if (charge > 0) {
          roomCharges[r.roomCode] = charge;
        }
      }
    }

    if (roomCharges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          content: Text('No active room utility charges to post.'),
        ),
      );
      return;
    }

    final postedCount = await DatabaseHelper.instance.postUtilityCharges(
      propertyId: _selectedProperty!.id,
      utilityType: typeLabel,
      roomCharges: roomCharges,
    );

    await _saveReadings(quiet: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryDeep,
        content: Text(
          '✓ Posted $typeLabel charges to $postedCount tenant bill${postedCount == 1 ? '' : 's'}! Total: ₱${_currencyFormat.format(_totalAllocatedAmount)}',
        ),
      ),
    );
  }

  void _showPostChargesConfirmationDialog() {
    if (_selectedProperty == null) return;
    if (_totalAllocatedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          content: Text('Please enter readings to calculate utility charges first.'),
        ),
      );
      return;
    }

    final typeLabel = _utilityType == UtilityType.electricity ? 'Electricity' : 'Water';
    final eligibleReadings = _roomReadings
        .where((r) => r.isIncluded && r.isOccupied && _calculateRoomCharge(r) > 0)
        .toList();

    if (eligibleReadings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          content: Text('No occupied rooms with calculated charges to post.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDeep.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryDeep, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Post Utility Charges', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(
                      'Apply to ${_selectedProperty!.name} Bills',
                      style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The following $typeLabel amounts will be added to each tenant\'s monthly ledger in SQLite:',
                    style: const TextStyle(fontSize: 13, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        for (final r in eligibleReadings) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Unit ${r.roomCode} (${r.tenantName ?? "Tenant"})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '₱${_currencyFormat.format(_calculateRoomCharge(r))}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryDeep),
                              ),
                            ],
                          ),
                          if (r != eligibleReadings.last) const Divider(height: 12, color: AppTheme.border),
                        ],
                        const Divider(height: 16, thickness: 1.5, color: AppTheme.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total to Post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Text(
                              '₱${_currencyFormat.format(_totalAllocatedAmount)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.statusPaid),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_post_utility_charges'),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _postChargesToTenants();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm & Post'),
            ),
          ],
        );
      },
    );
  }

  void _shareBreakdown() {
    final typeLabel = _utilityType == UtilityType.electricity ? 'Electricity (Meralco)' : 'Water (Manila Water / Maynilad)';
    final unitLabel = _utilityType == UtilityType.electricity ? 'kWh' : 'm³';
    final propName = _selectedProperty?.name ?? 'Property';
    final nowStr = DateFormat('MMMM yyyy').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('⚡ $typeLabel Breakdown');
    buffer.writeln('🏢 $propName · $nowStr');
    if (_splitMode == SplitMode.actualBill) {
      buffer.writeln('💵 Master Bill: ₱${_currencyFormat.format(_masterBillAmount)}');
      buffer.writeln('📊 Total Consumption: ${_formatNumber(_totalConsumption)} $unitLabel');
      buffer.writeln('📈 Effective Rate: ₱${_currencyFormat.format(_effectiveRatePerUnit)} / $unitLabel');
    } else if (_splitMode == SplitMode.fixedRate) {
      buffer.writeln('📈 Fixed Rate: ₱${_currencyFormat.format(_fixedRate)} / $unitLabel');
      buffer.writeln('📊 Total Consumption: ${_formatNumber(_totalConsumption)} $unitLabel');
    } else {
      buffer.writeln('💵 Equal Split Master Bill: ₱${_currencyFormat.format(_masterBillAmount)} ($_includedRoomsCount rooms)');
    }
    buffer.writeln('--------------------------------');

    for (final r in _roomReadings) {
      if (!r.isIncluded) continue;
      final charge = _calculateRoomCharge(r);
      final tenantDisplay = (r.tenantName != null && r.tenantName!.isNotEmpty) ? '(${r.tenantName})' : '(Vacant)';

      if (_splitMode == SplitMode.equalSplit) {
        buffer.writeln('• Unit ${r.roomCode} $tenantDisplay: ₱${_currencyFormat.format(charge)}');
      } else {
        buffer.writeln(
          '• Unit ${r.roomCode} $tenantDisplay: ${_formatNumber(r.previousReading)} → ${_formatNumber(r.currentReading)} (${_formatNumber(r.consumption)} $unitLabel) = ₱${_currencyFormat.format(charge)}',
        );
      }
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Total Allocated: ₱${_currencyFormat.format(_totalAllocatedAmount)}');
    buffer.writeln('Sent via Tenera Property Manager');

    final text = buffer.toString();

    Clipboard.setData(ClipboardData(text: text));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.copy_all_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Breakdown Copied!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The breakdown has been copied to your clipboard. Paste it directly into your tenant Group Chat (Messenger, Viber, WhatsApp) or SMS:',
              style: TextStyle(fontSize: 13, color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.ink),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Sub-Meter Math Explained', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Filipino Landlords Split Bills Fairly:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
            ),
            SizedBox(height: 10),
            Text(
              '1. Actual Bill Allocation (Recommended):\nEnter the total Meralco or water bill. Tenera sums each room\'s consumption and divides the bill to get the true effective rate per kWh/m³. Every room pays their exact fair share.',
              style: TextStyle(fontSize: 12, color: AppTheme.inkMuted, height: 1.35),
            ),
            SizedBox(height: 10),
            Text(
              '2. Fixed Rate:\nEnter a predetermined rate (e.g. ₱15/kWh). Tenant charges are simply Consumption × Fixed Rate.',
              style: TextStyle(fontSize: 12, color: AppTheme.inkMuted, height: 1.35),
            ),
            SizedBox(height: 10),
            Text(
              '3. Automatic Memory:\nWhen you tap "Save Readings", current readings become next month\'s starting baseline automatically.',
              style: TextStyle(fontSize: 12, color: AppTheme.inkMuted, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _utilityType == UtilityType.electricity ? 'kWh' : 'm³';

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          'Utility Sub-Meter Splitter',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primary),
            tooltip: 'How sub-meter math works',
            onPressed: _showHowItWorksDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Utility Type Selector Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchUtilityType(UtilityType.electricity),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _utilityType == UtilityType.electricity ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: _utilityType == UtilityType.electricity ? AppTheme.accent : AppTheme.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Electricity (kWh)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _utilityType == UtilityType.electricity ? Colors.white : AppTheme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchUtilityType(UtilityType.water),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _utilityType == UtilityType.water ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: _utilityType == UtilityType.water ? const Color(0xFF64B5F6) : AppTheme.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Water (m³)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _utilityType == UtilityType.water ? Colors.white : AppTheme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Property Selector Card
            if (_properties.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PropertyItem>(
                    value: _selectedProperty,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                    items: _properties.map((prop) {
                      return DropdownMenuItem<PropertyItem>(
                        value: prop,
                        child: Row(
                          children: [
                            const Icon(Icons.apartment_rounded, size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              prop.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${prop.rooms.length} units)',
                              style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (prop) async {
                      if (prop != null && prop != _selectedProperty) {
                        setState(() => _selectedProperty = prop);
                        await _setupRoomsForProperty(prop);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Calculation Mode Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calculation Split Mode',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.inkMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSplitModeChip(
                        label: 'Actual Bill Split',
                        mode: SplitMode.actualBill,
                        icon: Icons.pie_chart_outline_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildSplitModeChip(
                        label: 'Fixed Rate',
                        mode: SplitMode.fixedRate,
                        icon: Icons.attach_money_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildSplitModeChip(
                        label: 'Equal Split',
                        mode: SplitMode.equalSplit,
                        icon: Icons.balance_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Inputs depending on mode
                  if (_splitMode == SplitMode.actualBill || _splitMode == SplitMode.equalSplit) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _utilityType == UtilityType.electricity ? 'Total Meralco Bill (₱)' : 'Total Water Bill (₱)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _masterBillController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  prefixText: '₱ ',
                                  prefixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryDeep),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_splitMode == SplitMode.actualBill) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Effective Rate / $unitLabel',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    _totalConsumption > 0
                                        ? '₱${_currencyFormat.format(_effectiveRatePerUnit)}'
                                        : 'Enter readings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: _totalConsumption > 0 ? AppTheme.primaryDeep : AppTheme.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  if (_splitMode == SplitMode.fixedRate) ...[
                    Text(
                      'Fixed Rate per $unitLabel (₱)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _fixedRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        suffixText: 'per $unitLabel',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryDeep),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Room Sub-Meter Readings Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room Sub-Meter Readings (${_roomReadings.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink),
                ),
                TextButton.icon(
                  onPressed: () {
                    for (final r in _roomReadings) {
                      r.currController.clear();
                    }
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Room Readings List
            if (_roomReadings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: Text(
                    'No rooms found for this property. Add rooms in Properties tab first.',
                    style: TextStyle(color: AppTheme.inkMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (final reading in _roomReadings) ...[
                _buildRoomReadingCard(reading, unitLabel),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Consumption', style: TextStyle(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w600)),
                      Text(
                        '${_formatNumber(_totalConsumption)} $unitLabel',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Allocated Amount', style: TextStyle(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w600)),
                      Text(
                        '₱${_currencyFormat.format(_totalAllocatedAmount)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.statusPaid),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('btn_post_utility_to_bills'),
                  onPressed: _showPostChargesConfirmationDialog,
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Post Charges to Tenant Bills', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveReadings,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Readings', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareBreakdown,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Share Breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitModeChip({
    required String label,
    required SplitMode mode,
    required IconData icon,
  }) {
    final isSelected = _splitMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _splitMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.inkMuted),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomReadingCard(RoomReadingData r, String unitLabel) {
    final hasError = r.currController.text.trim().isNotEmpty && r.currentReading < r.previousReading;
    final charge = _calculateRoomCharge(r);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? AppTheme.statusOverdue : (r.isIncluded ? AppTheme.border : AppTheme.border.withValues(alpha: 0.5)),
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.isOccupied ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.roomCode,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryDeep),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.tenantName != null && r.tenantName!.isNotEmpty ? r.tenantName! : 'Vacant Unit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: r.isOccupied ? AppTheme.ink : AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text('Include', style: TextStyle(fontSize: 11, color: AppTheme.inkMuted)),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: r.isIncluded,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) => setState(() => r.isIncluded = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (r.isIncluded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prev ($unitLabel)', style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: r.prevController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current ($unitLabel)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: r.currController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Enter reading',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatNumber(r.consumption)} $unitLabel',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${_currencyFormat.format(charge)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryDeep),
                    ),
                  ],
                ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: AppTheme.statusOverdue),
                  SizedBox(width: 4),
                  Text(
                    'Current reading cannot be lower than previous reading.',
                    style: TextStyle(fontSize: 11, color: AppTheme.statusOverdue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

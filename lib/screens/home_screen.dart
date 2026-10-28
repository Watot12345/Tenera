import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../services/database_helper.dart';
import '../services/plan_guard_service.dart';
import '../services/staff_mode_service.dart';
import '../theme/app_theme.dart';
import 'property_rooms_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/more_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/properties_tab.dart';
import 'tabs/tenants_tab.dart';
import 'utility_calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  StreamSubscription<void>? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _loadFromDatabase();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _dbSubscription = DatabaseHelper.instance.changes.listen((_) {
        if (mounted) {
          _loadFromDatabase();
        }
      });
    }
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final db = DatabaseHelper.instance;
      final results = await Future.wait([
        db.getProperties(),
        db.getTenants(),
        db.getPayments(),
        StaffModeService.isStaffMode(),
        PlanGuardService.isPro(),
        PlanGuardService.isBusiness(),
      ]);

      final props = results[0] as List<PropertyItem>;
      final tenants = results[1] as List<TenantBill>;
      final payments = results[2] as List<PaymentRecord>;
      final isStaff = results[3] as bool;
      final isPro = results[4] as bool;
      final isBusiness = results[5] as bool;

      if (mounted) {
        setState(() {
          _isStaffMode = isStaff;
          _isPro = isPro;
          _isBusiness = isBusiness;
          _properties = props;
          _overdueTenants = tenants.where((t) => t.isOverdue && !t.isPaid).toList();
          _dueSoonTenants = tenants.where((t) => !t.isOverdue && !t.isPaid).toList();
          _paidTenants = tenants.where((t) => t.isPaid).toList();
          _paymentRecords = payments;
          _recomputeLedger();
        });
      }
    } catch (_) {
      // Ignore database errors
    }
  }

  Future<void> _refreshStaffMode() async {
    final staff = await StaffModeService.isStaffMode();
    final isPro = await PlanGuardService.isPro();
    final isBusiness = await PlanGuardService.isBusiness();
    if (mounted) {
      setState(() {
        _isStaffMode = staff;
        _isPro = isPro;
        _isBusiness = isBusiness;
      });
    }
  }

  void _recomputeLedger() {
    _totalUnits = _properties.fold<int>(0, (sum, p) => sum + p.totalUnits);
    _vacantUnits = _properties.fold<int>(
      0,
      (sum, p) => sum + p.rooms.where((r) => r.status == RoomStatus.vacant).length,
    );
    if (_vacantUnits == 0 && _totalUnits > 0) {
      final occupied = _properties.fold<int>(0, (sum, p) => sum + p.occupiedUnits);
      _vacantUnits = (_totalUnits - occupied).clamp(0, _totalUnits);
    }

    _collectedAmount = _paymentRecords.fold<int>(0, (sum, p) => sum + p.amount);

    final propertyExpected = _properties.fold<int>(0, (sum, p) => sum + p.monthlyRevenue);
    final tenantExpected = _allTenants.fold<int>(0, (sum, t) => sum + t.amount);

    if (propertyExpected > 0) {
      _expectedAmount = propertyExpected;
    } else if (tenantExpected > 0) {
      _expectedAmount = tenantExpected;
    } else {
      final unpaidTotal = _overdueTenants.fold<int>(0, (sum, t) => sum + t.amount) +
          _dueSoonTenants.fold<int>(0, (sum, t) => sum + t.amount);
      _expectedAmount = _collectedAmount + unpaidTotal;
    }
  }

  // Dynamic ledger state variables computed from database
  int _collectedAmount = 0;
  int _expectedAmount = 0;
  int _vacantUnits = 0;
  int _totalUnits = 0;
  bool _isStaffMode = false;
  bool _isPro = false;
  bool _isBusiness = false;

  // Real database-backed lists (no static hardcoded data)
  List<PropertyItem> _properties = [];
  List<TenantBill> _overdueTenants = [];
  List<TenantBill> _dueSoonTenants = [];
  List<TenantBill> _paidTenants = [];
  List<PaymentRecord> _paymentRecords = [];

  int get _overdueTotal => _overdueTenants
      .where((t) => !t.isPaid)
      .fold(0, (sum, t) => sum + t.amount);

  int get _overdueCount => _overdueTenants.where((t) => !t.isPaid).length;

  List<TenantBill> get _allTenants => [
        ..._overdueTenants,
        ..._dueSoonTenants,
        ..._paidTenants,
      ];

  void _openRecordPaymentDialog([TenantBill? preselected]) {
    final allUnpaid = [
      ..._overdueTenants.where((t) => !t.isPaid),
      ..._dueSoonTenants.where((t) => !t.isPaid),
    ];

    if (allUnpaid.isEmpty && preselected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All current rent bills have already been collected!'),
          backgroundColor: AppTheme.primary,
        ),
      );
      return;
    }

    TenantBill selected = preselected ?? (allUnpaid.isNotEmpty ? allUnpaid.first : _allTenants.first);
    String selectedMethod = 'Cash';
    final amountController = TextEditingController(text: selected.amount.toString());
    final searchTenantController = TextEditingController();
    final referenceNoController = TextEditingController();
    String? cashImageName;
    bool isSearchingTenant = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final searchQuery = searchTenantController.text.trim().toLowerCase();
            final matchingTenants = _allTenants.where((t) {
              if (searchQuery.isEmpty) return true;
              final matchName = t.name.toLowerCase().contains(searchQuery);
              final matchLoc = t.location.toLowerCase().contains(searchQuery);
              final matchInit = t.initials.toLowerCase().contains(searchQuery);
              return matchName || matchLoc || matchInit;
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceElevatedColor(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.payments_rounded,
                            color: AppTheme.isDark(context) ? AppTheme.darkAccent : AppTheme.primaryDeep,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Record Rent Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getInkColor(context),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppTheme.getInkMutedColor(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tenant Search Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Tenant',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getInkMutedColor(context),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              isSearchingTenant = !isSearchingTenant;
                            });
                          },
                          icon: Icon(
                            isSearchingTenant ? Icons.check_circle_outline_rounded : Icons.search_rounded,
                            size: 15,
                            color: AppTheme.primary,
                          ),
                          label: Text(
                            isSearchingTenant ? 'Done' : 'Search / Switch Tenant',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Search Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: TextField(
                        key: const Key('record_tenant_search_field'),
                        controller: searchTenantController,
                        style: TextStyle(color: AppTheme.getInkColor(context), fontSize: 13),
                        onChanged: (val) {
                          setSheetState(() {
                            isSearchingTenant = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Type name or unit (e.g. Maria, R3)...',
                          hintStyle: TextStyle(fontSize: 13, color: AppTheme.getInkMutedColor(context)),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.getPrimaryColor(context)),
                          suffixIcon: searchTenantController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, size: 16, color: AppTheme.getInkMutedColor(context)),
                                  onPressed: () {
                                    searchTenantController.clear();
                                    setSheetState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),

                    // Live Filtered Tenant Candidate List (near accurate matches)
                    if (isSearchingTenant || searchTenantController.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Material(
                        color: AppTheme.getSurfaceElevatedColor(context),
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.getBorderColor(context)),
                          ),
                          child: matchingTenants.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No tenants found matching "${searchTenantController.text}"',
                                      style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: matchingTenants.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.getBorderColor(context)),
                                  itemBuilder: (context, idx) {
                                    final t = matchingTenants[idx];
                                    final isCurrent = t.id == selected.id;
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      leading: CircleAvatar(
                                        radius: 13,
                                        backgroundColor: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                                        child: Text(
                                          t.initials,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.getPrimaryColor(context)),
                                        ),
                                      ),
                                      title: Text(
                                        t.name,
                                        style: TextStyle(
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                          color: isCurrent ? AppTheme.getPrimaryColor(context) : AppTheme.getInkColor(context),
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        t.location,
                                        style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context)),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₱${NumberFormat('#,###').format(t.amount)}',
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.getInkColor(context)),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 6),
                                            Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.getStatusPaidText(context)),
                                          ],
                                        ],
                                      ),
                                      onTap: () {
                                        setSheetState(() {
                                          selected = t;
                                          amountController.text = t.amount.toString();
                                          isSearchingTenant = false;
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Currently Selected Tenant Pill / Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                            child: Text(
                              selected.initials,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.getPrimaryColor(context)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.name,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                                ),
                                Text(
                                  selected.location,
                                  style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: selected.isPaid
                                  ? AppTheme.getStatusPaidBg(context)
                                  : (selected.isOverdue
                                      ? AppTheme.getStatusOverdueBg(context)
                                      : AppTheme.getStatusDueSoonBg(context)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selected.isPaid ? 'Paid' : (selected.isOverdue ? 'Overdue' : 'Due Soon'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected.isPaid
                                    ? AppTheme.getStatusPaidText(context)
                                    : (selected.isOverdue
                                        ? AppTheme.getStatusOverdueText(context)
                                        : AppTheme.getStatusDueSoonText(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    Text(
                      'Amount Paid (₱)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.getInkMutedColor(context)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        filled: true,
                        fillColor: AppTheme.getBackgroundColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Selection
                    Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.getInkMutedColor(context)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Cash', 'GCash', 'Bank Transfer'].map((method) {
                        final isSelected = selectedMethod == method;
                        return Expanded(
                          child: GestureDetector(
                            key: Key('payment_method_$method'),
                            onTap: () {
                              setSheetState(() {
                                selectedMethod = method;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.getPrimaryColor(context)
                                    : AppTheme.getBackgroundColor(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.getPrimaryColor(context)
                                      : AppTheme.getBorderColor(context),
                                ),
                              ),
                              child: Text(
                                method,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? (AppTheme.isDark(context) ? const Color(0xFF0F2623) : Colors.white)
                                      : AppTheme.getInkColor(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Fields: Cash Photo (optional) OR Reference Number (for digital)
                    if (selectedMethod == 'Cash') ...[
                      // Optional Cash Photo Proof
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.getBorderColor(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.photo_camera_rounded, size: 18, color: AppTheme.getPrimaryColor(context)),
                                const SizedBox(width: 8),
                                Text(
                                  'Cash Photo Proof (Optional)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                                ),
                                const Spacer(),
                                if (cashImageName != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getStatusPaidBg(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Attached',
                                      style: TextStyle(color: AppTheme.getStatusPaidText(context), fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (cashImageName == null)
                              InkWell(
                                key: const Key('attach_cash_photo_button'),
                                onTap: () {
                                  setSheetState(() {
                                    cashImageName = 'cash_${selected.name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch % 10000}.jpg';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurfaceElevatedColor(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 18, color: AppTheme.getPrimaryColor(context)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tap to Take or Attach Cash Photo',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.getPrimaryColor(context)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.getSurfaceElevatedColor(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.getStatusPaidText(context).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.getStatusPaidBg(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.image_rounded, size: 18, color: AppTheme.getStatusPaidText(context)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cashImageName!,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text('Proof of cash handed over', style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context))),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF5350)),
                                      tooltip: 'Remove photo',
                                      onPressed: () {
                                        setSheetState(() {
                                          cashImageName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Reference / Transaction No. Field for GCash or Bank Transfer
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedMethod == 'GCash' ? 'GCash Reference Number' : 'Bank Reference / Txn ID',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                              ),
                              Text(
                                'Digital Trace',
                                style: TextStyle(fontSize: 11, color: AppTheme.getPrimaryColor(context), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('payment_reference_field'),
                            controller: referenceNoController,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context)),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.tag_rounded, size: 18, color: AppTheme.getPrimaryColor(context)),
                              hintText: selectedMethod == 'GCash' ? 'e.g. 1002 9384 1283' : 'e.g. BPI-REF-89412',
                              filled: true,
                              fillColor: AppTheme.getBackgroundColor(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: () {
                        final enteredAmount = int.tryParse(amountController.text) ?? selected.amount;
                        final refNo = (selectedMethod != 'Cash' && referenceNoController.text.trim().isNotEmpty)
                            ? referenceNoController.text.trim()
                            : null;

                        final newPay = PaymentRecord(
                          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                          tenantName: selected.name,
                          location: selected.location,
                          amount: enteredAmount,
                          method: selectedMethod,
                          dateFormatted: DateFormat('MMM d, h:mm a').format(DateTime.now()),
                          referenceNo: refNo,
                          cashImageName: selectedMethod == 'Cash' ? cashImageName : null,
                        );

                        final updatedTenant = selected.copyWith(
                          isPaid: true,
                          isOverdue: false,
                          statusText: 'Paid ${DateFormat('MMM d').format(DateTime.now())}',
                        );

                        Navigator.pop(context);

                        setState(() {
                          _paymentRecords.insert(0, newPay);
                          _overdueTenants.removeWhere((t) => t.id == selected.id);
                          _dueSoonTenants.removeWhere((t) => t.id == selected.id);
                          _paidTenants.insert(0, updatedTenant);
                          _recomputeLedger();
                        });

                        DatabaseHelper.instance.recordPayment(
                          payment: newPay,
                          updatedTenant: updatedTenant,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.primaryDeep,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Payment of ₱${NumberFormat('#,###').format(enteredAmount)} from ${selected.name} logged ($selectedMethod${refNo != null ? " · Ref: $refNo" : ""}${cashImageName != null ? " · Photo attached" : ""}).',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirm & Log Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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

  void _openAddTenantDialog([String? defaultUnit]) {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: defaultUnit ?? '');
    final rentController = TextEditingController();
    final phoneController = TextEditingController();
    final messengerController = TextEditingController();
    bool autoRemind = true;

    PropertyItem? selectedProperty;
    RoomUnit? selectedRoom;

    if (_properties.isNotEmpty) {
      if (defaultUnit != null && defaultUnit.isNotEmpty) {
        for (final p in _properties) {
          if (defaultUnit.contains(p.name)) {
            selectedProperty = p;
            break;
          }
        }
      }
      selectedProperty ??= _properties.firstWhere(
        (p) => p.rooms.any((r) => r.status == RoomStatus.vacant),
        orElse: () => _properties.first,
      );

      final vacant = selectedProperty.rooms.where((r) => r.status == RoomStatus.vacant).toList();
      if (defaultUnit != null && defaultUnit.isNotEmpty) {
        for (final r in selectedProperty.rooms) {
          if (defaultUnit.contains(r.code)) {
            selectedRoom = r;
            break;
          }
        }
      }
      selectedRoom ??= vacant.firstOrNull;

      if (unitController.text.isEmpty && selectedRoom != null) {
        unitController.text = 'Room ${selectedRoom.code} · ${selectedProperty.name}';
      }
      if (rentController.text.isEmpty && selectedRoom != null) {
        rentController.text = '${selectedRoom.rentAmount ?? 4000}';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final vacantRooms = selectedProperty != null
                ? selectedProperty!.rooms.where((r) => r.status == RoomStatus.vacant).toList()
                : <RoomUnit>[];

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceElevatedColor(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppTheme.getPrimaryColor(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add New Tenant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getInkColor(context),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppTheme.getInkMutedColor(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      key: const Key('input_tenant_name'),
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tenant Full Name',
                        hintText: 'e.g. Roberto Gomez',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_properties.isNotEmpty) ...[
                      DropdownButtonFormField<PropertyItem>(
                        key: const Key('dropdown_select_property'),
                        initialValue: selectedProperty,
                        decoration: const InputDecoration(
                          labelText: 'Select Property',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        items: _properties.map((p) {
                          final vacCount = p.rooms.where((r) => r.status == RoomStatus.vacant).length;
                          return DropdownMenuItem<PropertyItem>(
                            value: p,
                            child: Text(
                              '${p.name} ($vacCount vacant)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (prop) {
                          if (prop == null) return;
                          setModalState(() {
                            selectedProperty = prop;
                            final vac = prop.rooms.where((r) => r.status == RoomStatus.vacant).toList();
                            selectedRoom = vac.firstOrNull;
                            if (selectedRoom != null) {
                              unitController.text = 'Room ${selectedRoom!.code} · ${prop.name}';
                              rentController.text = '${selectedRoom!.rentAmount ?? 4000}';
                            } else {
                              unitController.text = 'Unit · ${prop.name}';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (selectedProperty != null) ...[
                        if (vacantRooms.isNotEmpty)
                          DropdownButtonFormField<RoomUnit>(
                            key: ValueKey('dropdown_select_room_${selectedProperty?.id ?? ""}'),
                            initialValue: selectedRoom,
                            decoration: const InputDecoration(
                              labelText: 'Available Room to Assign',
                              prefixIcon: Icon(Icons.meeting_room_outlined),
                            ),
                            items: vacantRooms.map((r) {
                              return DropdownMenuItem<RoomUnit>(
                                value: r,
                                child: Text(
                                  'Room ${r.code} — ₱${NumberFormat('#,###').format(r.rentAmount ?? 4000)}/mo',
                                ),
                              );
                            }).toList(),
                            onChanged: (room) {
                              if (room == null) return;
                              setModalState(() {
                                selectedRoom = room;
                                unitController.text = 'Room ${room.code} · ${selectedProperty!.name}';
                                rentController.text = '${room.rentAmount ?? 4000}';
                              });
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.getBackgroundColor(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.getBorderColor(context)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.getInkMutedColor(context)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'All units in ${selectedProperty!.name} are occupied. Specifying a unit code below.',
                                    style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Room / Unit & Property',
                        hintText: 'e.g. 2E · Mabini Apts',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rent (₱)',
                        hintText: 'e.g. 4500',
                        prefixText: '₱ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('input_tenant_phone'),
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number (SMS / Call)',
                        hintText: 'e.g. 0917 123 4567',
                        prefixIcon: Icon(Icons.phone_android_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('input_tenant_messenger'),
                      controller: messengerController,
                      decoration: const InputDecoration(
                        labelText: 'FB Messenger (Handle / Link)',
                        hintText: 'e.g. m.me/robertogomez or FB Username',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.mark_chat_unread_rounded, size: 20, color: AppTheme.getPrimaryColor(context)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automated Reminders',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                                ),
                                Text(
                                  'Auto-compose friendly SMS & FB Messenger notices',
                                  style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context)),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            key: const Key('switch_auto_reminders'),
                            value: autoRemind,
                            activeTrackColor: AppTheme.primary,
                            onChanged: (val) => setModalState(() => autoRemind = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      key: const Key('btn_save_tenant'),
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        final newRent =
                            int.tryParse(rentController.text.trim()) ?? 4000;
                        final initials = nameController.text
                            .trim()
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase();

                        final assignedLoc = unitController.text.trim().isEmpty
                            ? (selectedRoom != null && selectedProperty != null
                                ? 'Room ${selectedRoom!.code} · ${selectedProperty!.name}'
                                : 'Room 4 · Mabini Apts')
                            : unitController.text.trim();

                        final newTenant = TenantBill(
                          id: 't_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameController.text.trim(),
                          initials: initials.isEmpty ? 'TN' : initials,
                          location: assignedLoc,
                          amount: newRent,
                          statusText: 'In 7 days',
                          isOverdue: false,
                          phone: phoneController.text.trim().isNotEmpty
                              ? phoneController.text.trim()
                              : null,
                          messenger: messengerController.text.trim().isNotEmpty
                              ? messengerController.text.trim()
                              : null,
                          automatedReminders: autoRemind,
                        );

                        Navigator.pop(context);
                        setState(() {
                          _dueSoonTenants.add(newTenant);
                          _recomputeLedger();
                        });

                        // Assign room to tenant in database if a room was selected
                        if (selectedProperty != null && selectedRoom != null) {
                          DatabaseHelper.instance.assignRoom(
                            selectedProperty!.id,
                            selectedRoom!.code,
                            nameController.text.trim(),
                            newRent,
                          );
                        }

                        DatabaseHelper.instance.insertTenant(newTenant);
                        _loadFromDatabase();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.primaryDeep,
                            content: Text(
                              'Tenant ${nameController.text.trim()} added successfully!',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                      child: const Text('Save Tenant & Lease'),
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

  void _openAddPropertyDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: '8');
    final rentCtrl = TextEditingController(text: '3500');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceElevatedColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.domain_add_rounded,
                      color: AppTheme.getPrimaryColor(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New Property',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getInkColor(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppTheme.getInkMutedColor(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  hintText: 'e.g. Luna Residences',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  hintText: 'e.g. 55 Luna St, Quezon City',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Units',
                        prefixIcon: Icon(Icons.door_front_door_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Avg. Rent (₱)',
                        prefixText: '₱ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final totalU = int.tryParse(unitsCtrl.text.trim()) ?? 6;
                  final avgR = int.tryParse(rentCtrl.text.trim()) ?? 3500;

                  final canAdd = await PlanGuardService.canAddUnits(
                    context: context,
                    currentTotalUnits: _totalUnits,
                    incomingUnits: totalU,
                  );
                  if (!canAdd || !mounted) return;

                  final List<RoomUnit> initialRooms = List.generate(
                    totalU,
                    (i) => RoomUnit(code: 'U${i + 1}', status: RoomStatus.vacant),
                  );
                  final newProp = PropertyItem(
                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    address: addressCtrl.text.trim().isEmpty
                        ? 'Metro Manila'
                        : addressCtrl.text.trim(),
                    totalUnits: totalU,
                    occupiedUnits: 0,
                    monthlyRevenue: totalU * avgR,
                    rooms: initialRooms,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _properties.add(newProp);
                    _recomputeLedger();
                  });
                  DatabaseHelper.instance.insertProperty(newProp);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryDeep,
                      content: Text(
                        'Property "${nameCtrl.text.trim()}" added with $totalU units!',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
                child: const Text('Save Property'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendFriendlyReminder(TenantBill tenant) {
    final formattedAmount = NumberFormat('#,###').format(tenant.amount);
    final roomDisplay = tenant.location.split('·')[0].trim();
    final reminderText =
        'Hello ${tenant.name}, this is a gentle reminder regarding your rent of ₱$formattedAmount for $roomDisplay (${tenant.statusText}). Thank you!';

    final hasPhone = tenant.phone != null && tenant.phone!.isNotEmpty;
    final hasMessenger = tenant.messenger != null && tenant.messenger!.isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceElevatedColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.getPrimaryColor(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Remind ${tenant.name}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.getInkColor(context)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPhone || hasMessenger) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.send_rounded, size: 14, color: AppTheme.getPrimaryColor(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            if (hasPhone) '📱 ${tenant.phone}',
                            if (hasMessenger) '💬 m.me/${tenant.messenger!.replaceAll('https://m.me/', '').replaceAll('m.me/', '')}',
                          ].join('   ·   '),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                'Pre-composed reminder message:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getInkMutedColor(context),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                ),
                child: Text(
                  reminderText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getInkColor(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: AppTheme.getInkMutedColor(context))),
            ),
            if (hasMessenger)
              OutlinedButton.icon(
                key: const Key('btn_open_fb_messenger'),
                onPressed: () async {
                  Clipboard.setData(ClipboardData(text: reminderText));
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0084FF),
                      content: Text('💬 Opening FB Messenger for ${tenant.name}! (Reminder text copied)'),
                    ),
                  );
                  final clean = tenant.messenger!
                      .replaceAll('https://m.me/', '')
                      .replaceAll('http://m.me/', '')
                      .replaceAll('m.me/', '')
                      .replaceAll('@', '')
                      .trim();
                  final uri = Uri.parse('https://m.me/$clean');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  }
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF0084FF)),
                label: const Text('FB Messenger', style: TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.w700, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0084FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ElevatedButton.icon(
              key: const Key('btn_share_reminder'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reminderText));
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryDeep,
                    content: Text(
                      'Reminder copied for ${tenant.name} to send via SMS / Chat!',
                    ),
                  ),
                );
                if (hasPhone) {
                  final cleanPhone = tenant.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
                  final smsUri = Uri(
                    scheme: 'sms',
                    path: cleanPhone,
                    queryParameters: <String, String>{'body': reminderText},
                  );
                  launchUrl(smsUri, mode: LaunchMode.externalApplication).catchError((_) {
                    return launchUrl(smsUri).catchError((_) => false);
                  });
                }
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showReceiptDialog(PaymentRecord rec) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.getSurfaceElevatedColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusPaidBg(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.getStatusPaidText(context),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rent Payment Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getInkColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ref: ${rec.id.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getInkMutedColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tenant', style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 13)),
                          Text(rec.tenantName, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Unit / Room', style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 13)),
                          Text(rec.location, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getInkColor(context), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method', style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 13)),
                          Text(rec.method, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getPrimaryColor(context), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Date & Time', style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 13)),
                          Text(rec.dateFormatted, style: TextStyle(color: AppTheme.getInkColor(context), fontSize: 13)),
                        ],
                      ),
                      if (rec.referenceNo != null && rec.referenceNo!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reference / Txn No.', style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 13)),
                            Text(
                              rec.referenceNo!,
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.getPrimaryColor(context), fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                      if (rec.cashImageName != null && rec.cashImageName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cash Photo Proof', style: TextStyle(color: AppTheme.getInkMutedColor(context), fontSize: 13)),
                            Row(
                              children: [
                                Icon(Icons.photo_camera_rounded, size: 14, color: AppTheme.getStatusPaidText(context)),
                                const SizedBox(width: 4),
                                Text(
                                  rec.cashImageName!,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      Divider(height: 20, color: AppTheme.getBorderColor(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getInkColor(context))),
                          Text(
                            '₱${NumberFormat('#,###').format(rec.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppTheme.getStatusPaidText(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryDeep,
                              content: Text('Receipt shared for ${rec.tenantName}!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share Receipt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentDateStr =
        DateFormat('EEE, MMM d').format(DateTime.now());
    final String currentMonthStr = DateFormat('MMMM').format(DateTime.now());
    final double collectionProgress = _expectedAmount > 0
        ? (_collectedAmount / _expectedAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(currentDateStr),
      body: SafeArea(
        child: Column(
          children: [
            if (_isStaffMode) _buildStaffModeBanner(),
            Expanded(
              child: _buildBody(currentMonthStr, collectionProgress),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStaffModeBanner() {
    return Container(
      key: const Key('banner_staff_mode_active'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.18),
        border: const Border(
          bottom: BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.shield_rounded, size: 16, color: AppTheme.ink),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Caretaker Mode Active · Financials Hidden',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDeep,
              ),
            ),
          ),
          InkWell(
            key: const Key('btn_exit_staff_mode_banner'),
            onTap: () {
              StaffModeService.toggleStaffMode(
                context,
                onModeChanged: _refreshStaffMode,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryDeep,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Exit (PIN)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(String currentDateStr) {
    if (_currentNavIndex == 0) {
      return AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Text(
          'Tenera',
          style: TextStyle(
            color: AppTheme.getInkColor(context),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_isPro)
            IconButton(
              key: const Key('home_action_utility_splitter'),
              icon: const Icon(Icons.bolt_rounded, color: AppTheme.primary),
              tooltip: 'Utility Sub-Meter Splitter',
              onPressed: () async {
                final canAccess = await PlanGuardService.requirePro(
                  context: context,
                  featureName: 'Utility Sub-Meter Splitter',
                  featureBenefit: 'Split electric & water sub-meter bills accurately per room with zero math errors.',
                );
                if (!canAccess || !mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UtilityCalculatorScreen(),
                  ),
                );
              },
            ),
        ],
      );
    }

    String title;
    String subtitle;
    Widget? actionButton;

    switch (_currentNavIndex) {
      case 1:
        title = 'Properties';
        subtitle = '${_properties.length} Active Properties';
        actionButton = null;
        break;
      case 2:
        title = 'Tenants';
        subtitle = '${_allTenants.length} Total Tenants';
        actionButton = IconButton(
          icon: const Icon(Icons.person_add_rounded, color: AppTheme.primary),
          tooltip: 'Add Tenant',
          onPressed: () => _openAddTenantDialog(),
        );
        break;
      case 3:
        title = 'Payment Ledger';
        subtitle = '${_paymentRecords.length} Receipts Logged';
        actionButton = IconButton(
          icon: const Icon(Icons.add_card_rounded, color: AppTheme.primary),
          tooltip: 'Record Payment',
          onPressed: () => _openRecordPaymentDialog(),
        );
        break;
      case 4:
      default:
        title = 'More & Settings';
        subtitle = 'Offline · Stored on this device';
        actionButton = null;
    }

    return AppBar(
      backgroundColor: AppTheme.getBackgroundColor(context),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getInkColor(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.getInkMutedColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (actionButton != null) actionButton,
      ],
    );
  }

  Widget _buildBody(String month, double progress) {
    switch (_currentNavIndex) {
      case 0:
        return HomeTab(
          month: month,
          progress: progress,
          collectedAmount: _collectedAmount,
          expectedAmount: _expectedAmount,
          overdueTotal: _overdueTotal,
          overdueCount: _overdueCount,
          vacantUnits: _vacantUnits,
          totalUnits: _totalUnits,
          overdueTenants: _overdueTenants,
          dueSoonTenants: _dueSoonTenants,
          onRecordPaymentQuick: () {
            setState(() => _currentNavIndex = 3);
            _openRecordPaymentDialog();
          },
          onAddTenantQuick: () {
            setState(() => _currentNavIndex = 2);
            _openAddTenantDialog();
          },
          onAddPropertyQuick: () {
            setState(() => _currentNavIndex = 1);
            _openAddPropertyDialog();
          },
          onRemindOverdueQuick: () {
            setState(() => _currentNavIndex = 2);
            final unpaid = _overdueTenants.where((t) => !t.isPaid).toList();
            if (unpaid.isNotEmpty) {
              _sendFriendlyReminder(unpaid.first);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No overdue rent. All caught up!'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            }
          },
          onTenantTap: (tenant) => _openRecordPaymentDialog(tenant),
          onSendReminder: (tenant) => _sendFriendlyReminder(tenant),
          isStaffMode: _isStaffMode,
        );
      case 1:
        return PropertiesTab(
          properties: _properties,
          onAddProperty: _openAddPropertyDialog,
          isStaffMode: _isStaffMode,
          isBusiness: _isBusiness,
          onViewRooms: (prop) async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PropertyRoomsScreen(
                  properties: _properties,
                  initialProperty: prop,
                  onRecordPayment: (tenant) => _openRecordPaymentDialog(tenant),
                  onSendReminder: (tenant) => _sendFriendlyReminder(tenant),
                  onAssignTenant: (location) => _openAddTenantDialog(location),
                  onRoomAdded: (p, room) async {
                    await DatabaseHelper.instance.insertRoom(p.id, room);
                  },
                  onTenantRemoved: (p, roomCode) async {
                    await DatabaseHelper.instance.vacateRoom(p.id, roomCode);
                  },
                ),
              ),
            );
            await _loadFromDatabase();
          },
        );
      case 2:
        return TenantsTab(
          tenants: _allTenants,
          onRecordPayment: (tenant) => _openRecordPaymentDialog(tenant),
          onSendReminder: (tenant) => _sendFriendlyReminder(tenant),
          onAddTenant: () => _openAddTenantDialog(),
          onShowReceipt: (tenant) {
            final existingRec = _paymentRecords.firstWhere(
              (r) => r.tenantName == tenant.name,
              orElse: () => PaymentRecord(
                id: 'pay_auto',
                tenantName: tenant.name,
                location: tenant.location,
                amount: tenant.amount,
                method: 'Cash',
                dateFormatted: 'Oct 2026',
              ),
            );
            _showReceiptDialog(existingRec);
          },
        );
      case 3:
        return PaymentsTab(
          paymentRecords: _paymentRecords,
          collectedAmount: _collectedAmount,
          isStaffMode: _isStaffMode,
          onRecordPayment: () => _openRecordPaymentDialog(),
          onShowReceipt: (rec) => _showReceiptDialog(rec),
        );
      case 4:
        return MoreTab(
          isPro: _isPro,
          isBusiness: _isBusiness,
          onStaffModeToggled: _refreshStaffMode,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    final isDark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.getBorderColor(context).withValues(alpha: 0.8)),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: isDark ? const Color(0xFF1B3D38) : const Color(0xFFE3F4EA), // Soft active pill
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkInkMuted : AppTheme.inkMuted,
            );
          }),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: AppTheme.getSurfaceColor(context),
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) async {
            setState(() {
              _currentNavIndex = index;
            });
            final staff = await StaffModeService.isStaffMode();
            final isPro = await PlanGuardService.isPro();
            final isBusiness = await PlanGuardService.isBusiness();
            if (mounted) {
              setState(() {
                _isStaffMode = staff;
                _isPro = isPro;
                _isBusiness = isBusiness;
              });
            }
          },
          destinations: const [
            NavigationDestination(
              key: Key('nav_home'),
              icon: Icon(Icons.home_outlined, color: AppTheme.inkMuted),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              key: Key('nav_properties'),
              icon: Icon(Icons.domain_outlined, color: AppTheme.inkMuted),
              selectedIcon: Icon(Icons.domain_rounded, color: AppTheme.primary),
              label: 'Properties',
            ),
            NavigationDestination(
              key: Key('nav_tenants'),
              icon: Icon(Icons.people_outline_rounded, color: AppTheme.inkMuted),
              selectedIcon: Icon(Icons.people_rounded, color: AppTheme.primary),
              label: 'Tenants',
            ),
            NavigationDestination(
              key: Key('nav_payments'),
              icon: Icon(Icons.payments_outlined, color: AppTheme.inkMuted),
              selectedIcon: Icon(Icons.payments_rounded, color: AppTheme.primary),
              label: 'Payments',
            ),
            NavigationDestination(
              key: Key('nav_more'),
              icon: Icon(Icons.more_horiz_rounded, color: AppTheme.inkMuted),
              selectedIcon: Icon(Icons.more_horiz_rounded, color: AppTheme.primary),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

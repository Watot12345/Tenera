import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/roof_ledger_logo.dart';
import 'privacy_policy_screen.dart';
import 'property_rooms_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/more_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/properties_tab.dart';
import 'tabs/tenants_tab.dart';
import 'utility_calculator_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final db = DatabaseHelper.instance;
      final results = await Future.wait([
        db.getProperties(),
        db.getTenants(),
        db.getPayments(),
      ]);

      final props = results[0] as List<PropertyItem>;
      final tenants = results[1] as List<TenantBill>;
      final payments = results[2] as List<PaymentRecord>;

      if (mounted) {
        setState(() {
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

    final unpaidTotal = _overdueTenants.fold<int>(0, (sum, t) => sum + t.amount) +
        _dueSoonTenants.fold<int>(0, (sum, t) => sum + t.amount);

    _expectedAmount = _collectedAmount + unpaidTotal;
    if (_expectedAmount == 0 && _properties.isNotEmpty) {
      _expectedAmount = _properties.fold<int>(0, (sum, p) => sum + p.monthlyRevenue);
    }
  }

  // Dynamic ledger state variables computed from database
  int _collectedAmount = 0;
  int _expectedAmount = 0;
  int _vacantUnits = 0;
  int _totalUnits = 0;

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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          child: const Icon(
                            Icons.payments_rounded,
                            color: AppTheme.primaryDeep,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Record Rent Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tenant Search Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Tenant',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkMuted,
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
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: TextField(
                        key: const Key('record_tenant_search_field'),
                        controller: searchTenantController,
                        onChanged: (val) {
                          setSheetState(() {
                            isSearchingTenant = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Type name or unit (e.g. Maria, R3)...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.inkMuted),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primary),
                          suffixIcon: searchTenantController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.inkMuted),
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
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: matchingTenants.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No tenants found matching "${searchTenantController.text}"',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: matchingTenants.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
                                  itemBuilder: (context, idx) {
                                    final t = matchingTenants[idx];
                                    final isCurrent = t.id == selected.id;
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      leading: CircleAvatar(
                                        radius: 13,
                                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                        child: Text(
                                          t.initials,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                                        ),
                                      ),
                                      title: Text(
                                        t.name,
                                        style: TextStyle(
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                          color: isCurrent ? AppTheme.primary : AppTheme.ink,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        t.location,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.inkMuted),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₱${NumberFormat('#,###').format(t.amount)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.statusPaid),
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
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                            child: Text(
                              selected.initials,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                ),
                                Text(
                                  selected.location,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: selected.isPaid ? AppTheme.statusPaidBg : (selected.isOverdue ? const Color(0xFFFFECEB) : AppTheme.statusDueSoonBg),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selected.isPaid ? 'Paid' : (selected.isOverdue ? 'Overdue' : 'Due Soon'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected.isPaid ? AppTheme.statusPaid : (selected.isOverdue ? AppTheme.statusOverdue : AppTheme.statusDueSoon),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    const Text(
                      'Amount Paid (₱)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.inkMuted),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.ink),
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Selection
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.inkMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Cash', 'GCash', 'Bank Transfer'].map((method) {
                        final isSelected = selectedMethod == method;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedMethod = method;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : AppTheme.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                              ),
                              child: Text(
                                method,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.ink,
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
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_camera_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cash Photo Proof (Optional)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                ),
                                const Spacer(),
                                if (cashImageName != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusPaidBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Attached', style: TextStyle(color: AppTheme.statusPaid, fontSize: 11, fontWeight: FontWeight.w700)),
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
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 18, color: AppTheme.primary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tap to Take or Attach Cash Photo',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.statusPaid.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.statusPaidBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.image_rounded, size: 18, color: AppTheme.statusPaid),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cashImageName!,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text('Proof of cash handed over', style: TextStyle(fontSize: 11, color: AppTheme.inkMuted)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFC92A2A)),
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
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink),
                              ),
                              const Text(
                                'Digital Trace',
                                style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('payment_reference_field'),
                            controller: referenceNoController,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: AppTheme.primary),
                              hintText: selectedMethod == 'GCash' ? 'e.g. 1002 9384 1283' : 'e.g. BPI-REF-89412',
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Tenant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tenant Full Name',
                  hintText: 'e.g. Roberto Gomez',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
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

                  final newTenant = TenantBill(
                    id: 't_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    initials: initials.isEmpty ? 'TN' : initials,
                    location: unitController.text.trim().isEmpty
                        ? 'Room 4 · Mabini Apts'
                        : unitController.text.trim(),
                    amount: newRent,
                    statusText: 'In 7 days',
                    isOverdue: false,
                  );

                  Navigator.pop(context);
                  setState(() {
                    _dueSoonTenants.add(newTenant);
                    _recomputeLedger();
                  });
                  DatabaseHelper.instance.insertTenant(newTenant);

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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.domain_add_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Property',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppTheme.primary),
              const SizedBox(width: 10),
              Text('Remind ${tenant.name}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pre-composed reminder message:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkMuted,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Hello ${tenant.name}, this is a gentle reminder regarding your rent of ₱${NumberFormat('#,###').format(tenant.amount)} for ${tenant.location.split('·')[0].trim()} (${tenant.statusText}). Thank you!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryDeep,
                    content: Text(
                      'Reminder copied for ${tenant.name} to send via SMS / Chat!',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Reminder'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.statusPaidBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.statusPaid,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rent Payment Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ref: ${rec.id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tenant', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                          Text(rec.tenantName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Unit / Room', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                          Text(rec.location, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                          Text(rec.method, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date & Time', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                          Text(rec.dateFormatted, style: const TextStyle(color: AppTheme.ink, fontSize: 13)),
                        ],
                      ),
                      if (rec.referenceNo != null && rec.referenceNo!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reference / Txn No.', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                            Text(
                              rec.referenceNo!,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryDeep, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                      if (rec.cashImageName != null && rec.cashImageName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cash Photo Proof', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                            Row(
                              children: [
                                const Icon(Icons.photo_camera_rounded, size: 14, color: AppTheme.statusPaid),
                                const SizedBox(width: 4),
                                Text(
                                  rec.cashImageName!,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20, color: AppTheme.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink)),
                          Text(
                            '₱${NumberFormat('#,###').format(rec.amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppTheme.statusPaid,
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
    final double collectionProgress =
        (_collectedAmount / _expectedAmount).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(currentDateStr),
      body: SafeArea(
        child: _buildBody(currentMonthStr, collectionProgress),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget? _buildAppBar(String currentDateStr) {
    if (_currentNavIndex == 0) {
      return AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            RoofLedgerLogo(
              size: 28,
              isLight: false,
            ),
            SizedBox(width: 10),
            Text(
              'Tenera',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                currentDateStr,
                style: const TextStyle(
                  color: AppTheme.inkMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('home_action_utility_splitter'),
            icon: const Icon(Icons.bolt_rounded, color: AppTheme.primary),
            tooltip: 'Utility Sub-Meter Splitter',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UtilityCalculatorScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.inkMuted),
            tooltip: 'Welcome Guide',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined, color: AppTheme.inkMuted),
            tooltip: 'Privacy Policy & Terms',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(
                    isOnboarding: false,
                  ),
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
      backgroundColor: AppTheme.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (actionButton != null) actionButton,
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, color: AppTheme.inkMuted),
          tooltip: 'Welcome Guide',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
        ),
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
          onRecordPaymentQuick: () => _openRecordPaymentDialog(),
          onAddTenantQuick: () => _openAddTenantDialog(),
          onAddPropertyQuick: _openAddPropertyDialog,
          onRemindOverdueQuick: () {
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
        );
      case 1:
        return PropertiesTab(
          properties: _properties,
          onAddProperty: _openAddPropertyDialog,
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
          onRecordPayment: () => _openRecordPaymentDialog(),
          onShowReceipt: (rec) => _showReceiptDialog(rec),
        );
      case 4:
        return const MoreTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE3F4EA), // Soft active pill
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.inkMuted,
            );
          }),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: AppTheme.surface,
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentNavIndex = index;
            });
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

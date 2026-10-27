import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lease_contract.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class LeaseContractScreen extends StatefulWidget {
  final LeaseContract? initialContract;

  const LeaseContractScreen({super.key, this.initialContract});

  @override
  State<LeaseContractScreen> createState() => _LeaseContractScreenState();
}

class _LeaseContractScreenState extends State<LeaseContractScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _landlordNameCtrl = TextEditingController(text: 'Juan Dela Cruz');
  final _landlordAddressCtrl = TextEditingController(text: 'Quezon City, Metro Manila');
  final _landlordContactCtrl = TextEditingController(text: '+63 917 123 4567');

  final _tenantNameCtrl = TextEditingController(text: 'Elena Santos');
  final _tenantAddressCtrl = TextEditingController(text: 'Manila, Philippines');
  final _tenantContactCtrl = TextEditingController(text: '+63 918 987 6543');
  final _tenantIdCtrl = TextEditingController(text: 'National ID: 1234-5678-9012');

  final _propertyNameCtrl = TextEditingController(text: 'Sampaguita Place');
  final _unitCodeCtrl = TextEditingController(text: 'Room 2B');
  final _propertyAddressCtrl = TextEditingController(text: '123 Katipunan Ave, Quezon City');

  final _monthlyRentCtrl = TextEditingController(text: '6500');
  final _advanceRentCtrl = TextEditingController(text: '6500');
  final _depositCtrl = TextEditingController(text: '13000');

  final _rulesCtrl = TextEditingController(
    text: 'No loud music after 10:00 PM. No unauthorized overnight guests exceeding 3 consecutive nights.',
  );
  final _witness1Ctrl = TextEditingController(text: 'Maria Clara');
  final _witness2Ctrl = TextEditingController(text: 'Jose Rizal');

  DateTime _startDate = DateTime.now();
  int _durationMonths = 12;
  int _dueDay = 5;
  double _lateFee = 5.0;
  int _maxOccupants = 2;
  String _petPolicy = 'Not Allowed';

  List<TenantBill> _availableTenants = [];
  List<PropertyItem> _availableProperties = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialContract != null) {
      _applyContract(widget.initialContract!);
    } else {
      _loadData();
    }
  }

  void _applyContract(LeaseContract c) {
    _landlordNameCtrl.text = c.landlordName;
    _landlordAddressCtrl.text = c.landlordAddress;
    _landlordContactCtrl.text = c.landlordContact;

    _tenantNameCtrl.text = c.tenantName;
    _tenantAddressCtrl.text = c.tenantAddress;
    _tenantContactCtrl.text = c.tenantContact;
    _tenantIdCtrl.text = c.tenantIdInfo;

    _propertyNameCtrl.text = c.propertyName;
    _unitCodeCtrl.text = c.unitCode;
    _propertyAddressCtrl.text = c.propertyAddress;

    _monthlyRentCtrl.text = c.monthlyRent.toString();
    _advanceRentCtrl.text = c.advanceRent.toString();
    _depositCtrl.text = c.securityDeposit.toString();

    _startDate = c.startDate;
    _durationMonths = c.durationInMonths;
    _dueDay = c.dueDayOfMonth;
    _lateFee = c.lateFeePercent;
    _maxOccupants = c.maxOccupants;
    _petPolicy = c.petPolicy;
    _rulesCtrl.text = c.additionalRules;
    _witness1Ctrl.text = c.witness1Name;
    _witness2Ctrl.text = c.witness2Name;
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper.instance;
      final results = await Future.wait([
        db.getTenants(),
        db.getProperties(),
      ]);

      if (mounted) {
        setState(() {
          _availableTenants = results[0] as List<TenantBill>;
          _availableProperties = results[1] as List<PropertyItem>;

          // If there is an existing tenant, pre-fill from first one
          if (_availableTenants.isNotEmpty) {
            final t = _availableTenants.first;
            _autofillFromTenant(t);
          }
        });
      }
    } catch (_) {}
  }

  void _autofillFromTenant(TenantBill t) {
    setState(() {
      _tenantNameCtrl.text = t.name;
      _monthlyRentCtrl.text = t.amount.toString();
      _advanceRentCtrl.text = t.amount.toString();
      _depositCtrl.text = (t.amount * 2).toString();

      // Split location (e.g., "Room 2 · Mabini Apts")
      if (t.location.contains('·')) {
        final parts = t.location.split('·');
        _unitCodeCtrl.text = parts[0].trim();
        _propertyNameCtrl.text = parts[1].trim();
      } else {
        _unitCodeCtrl.text = t.location.trim();
      }

      // Check if property matches
      for (final p in _availableProperties) {
        if (p.name.toLowerCase() == _propertyNameCtrl.text.toLowerCase()) {
          if (p.address.isNotEmpty) {
            _propertyAddressCtrl.text = p.address;
          }
          break;
        }
      }
    });
  }

  LeaseContract _buildCurrentContract() {
    final rent = int.tryParse(_monthlyRentCtrl.text.trim()) ?? 0;
    final advance = int.tryParse(_advanceRentCtrl.text.trim()) ?? rent;
    final deposit = int.tryParse(_depositCtrl.text.trim()) ?? (rent * 2);

    final endDate = DateTime(_startDate.year, _startDate.month + _durationMonths, _startDate.day);

    return LeaseContract(
      landlordName: _landlordNameCtrl.text.trim(),
      landlordAddress: _landlordAddressCtrl.text.trim(),
      landlordContact: _landlordContactCtrl.text.trim(),
      tenantName: _tenantNameCtrl.text.trim(),
      tenantAddress: _tenantAddressCtrl.text.trim(),
      tenantContact: _tenantContactCtrl.text.trim(),
      tenantIdInfo: _tenantIdCtrl.text.trim(),
      propertyName: _propertyNameCtrl.text.trim(),
      unitCode: _unitCodeCtrl.text.trim(),
      propertyAddress: _propertyAddressCtrl.text.trim(),
      monthlyRent: rent,
      securityDeposit: deposit,
      advanceRent: advance,
      startDate: _startDate,
      endDate: endDate,
      dueDayOfMonth: _dueDay,
      lateFeePercent: _lateFee,
      maxOccupants: _maxOccupants,
      petPolicy: _petPolicy,
      additionalRules: _rulesCtrl.text.trim(),
      witness1Name: _witness1Ctrl.text.trim(),
      witness2Name: _witness2Ctrl.text.trim(),
    );
  }

  void _copyToClipboard() {
    final contract = _buildCurrentContract();
    final text = contract.toFormattedContractText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Full lease contract copied to clipboard! Ready to paste into Google Docs or Word.'),
        backgroundColor: AppTheme.primaryDeep,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPrintDialog() {
    final contract = _buildCurrentContract();
    final text = contract.toFormattedContractText();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.print_rounded, color: AppTheme.primaryDeep),
              SizedBox(width: 8),
              Text('Print-Ready Contract', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              key: const Key('btn_modal_copy_contract'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contract copied! Paste and print from any text editor or browser.'),
                    backgroundColor: AppTheme.primaryDeep,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy All Text'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDeep,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _landlordNameCtrl.dispose();
    _landlordAddressCtrl.dispose();
    _landlordContactCtrl.dispose();
    _tenantNameCtrl.dispose();
    _tenantAddressCtrl.dispose();
    _tenantContactCtrl.dispose();
    _tenantIdCtrl.dispose();
    _propertyNameCtrl.dispose();
    _unitCodeCtrl.dispose();
    _propertyAddressCtrl.dispose();
    _monthlyRentCtrl.dispose();
    _advanceRentCtrl.dispose();
    _depositCtrl.dispose();
    _rulesCtrl.dispose();
    _witness1Ctrl.dispose();
    _witness2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lease Agreement Generator',
              style: TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Philippine Civil Code & Rent Control Act Compliant',
              style: TextStyle(
                color: AppTheme.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryDeep,
          unselectedLabelColor: AppTheme.inkMuted,
          indicatorColor: AppTheme.primaryDeep,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Edit Agreement'),
            Tab(icon: Icon(Icons.visibility_rounded, size: 20), text: 'Contract Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditFormTab(),
          _buildPreviewTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // EDIT FORM TAB
  // ===========================================================================
  Widget _buildEditFormTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Autofill selector
        if (_availableTenants.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded, color: AppTheme.primaryDeep, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Autofill from registered tenant:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryDeep),
                  ),
                ),
                DropdownButton<TenantBill>(
                  key: const Key('dropdown_autofill_tenant'),
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  hint: const Text('Choose Tenant', style: TextStyle(fontSize: 12)),
                  items: _availableTenants.map((t) {
                    return DropdownMenuItem<TenantBill>(
                      value: t,
                      child: Text('${t.name} (${t.location})', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (selected) {
                    if (selected != null) _autofillFromTenant(selected);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Section: Landlord
        _buildSectionHeader(Icons.person_pin_rounded, 'Lessor / Landlord Details'),
        const SizedBox(height: 8),
        _buildTextField(
          key: const Key('input_contract_landlord_name'),
          controller: _landlordNameCtrl,
          label: 'Lessor / Landlord Full Name',
          hint: 'e.g. Juan Dela Cruz',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_landlord_contact'),
                controller: _landlordContactCtrl,
                label: 'Landlord Contact No.',
                hint: '+63 917 123 4567',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_landlord_address'),
                controller: _landlordAddressCtrl,
                label: 'City / Province',
                hint: 'Metro Manila',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section: Tenant
        _buildSectionHeader(Icons.person_rounded, 'Lessee / Tenant Details'),
        const SizedBox(height: 8),
        _buildTextField(
          key: const Key('input_contract_tenant_name'),
          controller: _tenantNameCtrl,
          label: 'Lessee / Tenant Full Name',
          hint: 'e.g. Elena Santos',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_tenant_contact'),
                controller: _tenantContactCtrl,
                label: 'Tenant Contact No.',
                hint: '+63 918 987 6543',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_tenant_id'),
                controller: _tenantIdCtrl,
                label: 'ID Card / Passport / TIN',
                hint: 'National ID: 1234',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          key: const Key('input_contract_tenant_address'),
          controller: _tenantAddressCtrl,
          label: 'Tenant Permanent Address',
          hint: 'e.g. Makati City, Philippines',
        ),
        const SizedBox(height: 20),

        // Section: Premises
        _buildSectionHeader(Icons.domain_rounded, 'Leased Premises'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                key: const Key('input_contract_property_name'),
                controller: _propertyNameCtrl,
                label: 'Property Name',
                hint: 'Sampaguita Place',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _buildTextField(
                key: const Key('input_contract_unit_code'),
                controller: _unitCodeCtrl,
                label: 'Unit / Room',
                hint: 'Room 2B',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          key: const Key('input_contract_property_address'),
          controller: _propertyAddressCtrl,
          label: 'Complete Property Address',
          hint: '123 Katipunan Ave, Quezon City',
        ),
        const SizedBox(height: 20),

        // Section: Rent & Deposits
        _buildSectionHeader(Icons.payments_rounded, 'Rental Rates & Deposits (₱)'),
        const SizedBox(height: 8),
        _buildTextField(
          key: const Key('input_contract_rent'),
          controller: _monthlyRentCtrl,
          label: 'Monthly Rent (₱)',
          hint: '6500',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final rent = int.tryParse(val) ?? 0;
            if (rent > 0) {
              setState(() {
                _advanceRentCtrl.text = rent.toString();
                _depositCtrl.text = (rent * 2).toString();
              });
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_advance'),
                controller: _advanceRentCtrl,
                label: 'Advance Rent (₱)',
                hint: '6500',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_deposit'),
                controller: _depositCtrl,
                label: 'Security Deposit (₱)',
                hint: '13000',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDepositHelperChip('1 Month Deposit', 1),
            const SizedBox(width: 8),
            _buildDepositHelperChip('2 Months Deposit', 2),
          ],
        ),
        const SizedBox(height: 20),

        // Section: Lease Duration & Due Day
        _buildSectionHeader(Icons.calendar_month_rounded, 'Duration & Payment Terms'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('dropdown_contract_duration'),
                initialValue: _durationMonths,
                decoration: _fieldDecoration('Lease Term'),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 Months')),
                  DropdownMenuItem(value: 6, child: Text('6 Months')),
                  DropdownMenuItem(value: 12, child: Text('12 Months (1 Year)')),
                  DropdownMenuItem(value: 24, child: Text('24 Months (2 Years)')),
                ],
                onChanged: (val) => setState(() => _durationMonths = val ?? 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('dropdown_contract_due_day'),
                initialValue: _dueDay,
                decoration: _fieldDecoration('Monthly Due Day'),
                items: [1, 5, 10, 15, 20, 25, 30].map((d) {
                  return DropdownMenuItem(value: d, child: Text('Every ${LeaseContract.ordinal(d)}'));
                }).toList(),
                onChanged: (val) => setState(() => _dueDay = val ?? 5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<double>(
                key: const Key('dropdown_contract_late_fee'),
                initialValue: _lateFee,
                decoration: _fieldDecoration('Late Penalty'),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('No Late Fee')),
                  DropdownMenuItem(value: 3.0, child: Text('3% per month')),
                  DropdownMenuItem(value: 5.0, child: Text('5% per month (Standard)')),
                  DropdownMenuItem(value: 10.0, child: Text('10% per month')),
                ],
                onChanged: (val) => setState(() => _lateFee = val ?? 5.0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('dropdown_contract_occupants'),
                initialValue: _maxOccupants,
                decoration: _fieldDecoration('Max Occupants'),
                items: [1, 2, 3, 4, 6].map((o) {
                  return DropdownMenuItem(value: o, child: Text('$o person(s)'));
                }).toList(),
                onChanged: (val) => setState(() => _maxOccupants = val ?? 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section: House Rules & Pet Policy
        _buildSectionHeader(Icons.gavel_rounded, 'House Rules & Policies'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('dropdown_contract_pet_policy'),
          initialValue: _petPolicy,
          decoration: _fieldDecoration('Pet Policy'),
          items: const [
            DropdownMenuItem(value: 'Not Allowed', child: Text('Pets Not Allowed')),
            DropdownMenuItem(value: 'Small Pets Allowed (Cats/Small Dogs)', child: Text('Small Pets Allowed')),
            DropdownMenuItem(value: 'Allowed with Pet Security Deposit', child: Text('Allowed with Pet Deposit')),
          ],
          onChanged: (val) => setState(() => _petPolicy = val ?? 'Not Allowed'),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          key: const Key('input_contract_rules'),
          controller: _rulesCtrl,
          label: 'Special Stipulations / House Rules',
          hint: 'e.g. Quiet hours, visitor limits, smoking rules...',
          maxLines: 2,
        ),
        const SizedBox(height: 20),

        // Section: Witnesses
        _buildSectionHeader(Icons.group_rounded, 'Witness Signatures'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_witness1'),
                controller: _witness1Ctrl,
                label: 'Witness 1 Full Name',
                hint: 'Maria Clara',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                key: const Key('input_contract_witness2'),
                controller: _witness2Ctrl,
                label: 'Witness 2 Full Name',
                hint: 'Jose Rizal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Switch to Preview Button
        ElevatedButton.icon(
          key: const Key('btn_proceed_to_preview'),
          onPressed: () => _tabController.animateTo(1),
          icon: const Icon(Icons.description_rounded),
          label: const Text('View Formatted Contract', style: TextStyle(fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDeep,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ===========================================================================
  // CONTRACT PREVIEW TAB
  // ===========================================================================
  Widget _buildPreviewTab() {
    final contract = _buildCurrentContract();
    final contractText = contract.toFormattedContractText();

    return Column(
      children: [
        // Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('btn_copy_contract'),
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy All Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                key: const Key('btn_print_contract'),
                onPressed: _showPrintDialog,
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.ink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Document Card
        Expanded(
          child: Container(
            color: const Color(0xFFF4EFE6), // Warm paper tone
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SelectableText(
                  contractText,
                  key: const Key('text_rendered_contract'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryDeep),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryDeep,
          ),
        ),
      ],
    );
  }

  Widget _buildDepositHelperChip(String label, int months) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.surface,
      side: const BorderSide(color: AppTheme.border),
      onPressed: () {
        final rent = int.tryParse(_monthlyRentCtrl.text.trim()) ?? 0;
        setState(() {
          _depositCtrl.text = (rent * months).toString();
        });
      },
    );
  }

  Widget _buildTextField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: _fieldDecoration(label, hint: hint),
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppTheme.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class ExpensesScreen extends StatefulWidget {
  final List<PropertyItem>? initialProperties;
  final List<ExpenseRecord>? initialExpenses;
  final List<PaymentRecord>? initialPayments;

  const ExpensesScreen({
    super.key,
    this.initialProperties,
    this.initialExpenses,
    this.initialPayments,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _isLoading = true;
  List<ExpenseRecord> _expenses = [];
  List<PropertyItem> _properties = [];
  List<PaymentRecord> _payments = [];

  String _selectedPropertyId = 'ALL';
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'Repairs & Maintenance',
    'Utilities',
    'Caretaker & Staff',
    'Taxes & Permits',
    'Supplies & Cleaning',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialProperties != null && widget.initialExpenses != null && widget.initialPayments != null) {
      _properties = widget.initialProperties!;
      _expenses = widget.initialExpenses!;
      _payments = widget.initialPayments!;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_expenses.isEmpty && _properties.isEmpty) {
      setState(() => _isLoading = true);
    }
    final db = DatabaseHelper.instance;
    final exps = await db.getExpenses();
    if (!mounted) return;
    final props = widget.initialProperties ?? await db.getProperties();
    if (!mounted) return;
    final pays = await db.getPayments();
    if (!mounted) return;

    setState(() {
      _expenses = exps;
      _properties = props;
      _payments = pays;
      _isLoading = false;
    });
  }

  List<ExpenseRecord> get _filteredExpenses {
    return _expenses.where((exp) {
      final matchesProp = _selectedPropertyId == 'ALL' || exp.propertyId == _selectedPropertyId;
      final matchesCat = _selectedCategory == 'ALL' || exp.category == _selectedCategory;
      return matchesProp && matchesCat;
    }).toList();
  }

  int get _totalGrossRevenue {
    final validPayments = _payments.where((p) => !p.isVoided && !p.method.contains('Security Deposit'));
    if (_selectedPropertyId == 'ALL') {
      return validPayments.fold(0, (sum, p) => sum + p.amount);
    }
    final prop = _properties.firstWhere((p) => p.id == _selectedPropertyId, orElse: () => _properties.first);
    return validPayments
        .where((p) => p.location.toLowerCase().contains(prop.name.toLowerCase()))
        .fold(0, (sum, p) => sum + p.amount);
  }

  int get _totalExpenses {
    final list = _expenses.where((exp) {
      return _selectedPropertyId == 'ALL' || exp.propertyId == _selectedPropertyId;
    });
    return list.fold(0, (sum, exp) => sum + exp.amount);
  }

  int get _netProfit => _totalGrossRevenue - _totalExpenses;

  double get _profitMargin {
    if (_totalGrossRevenue <= 0) return 0.0;
    return (_netProfit / _totalGrossRevenue) * 100.0;
  }

  void _openLogExpenseDialog() {
    final formKey = GlobalKey<FormState>();
    String selectedPropId = _selectedPropertyId == 'ALL'
        ? (_properties.isNotEmpty ? _properties.first.id : 'ALL')
        : _selectedPropertyId;
    String selectedCategory = _categories.first;
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC92A2A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFC92A2A), size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'Log Property Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.getInkColor(dialogCtx),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Property Picker
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_expense_property'),
                      initialValue: selectedPropId,
                      decoration: InputDecoration(
                        labelText: 'Property',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        ..._properties.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            )),
                        const DropdownMenuItem(
                          value: 'GENERAL',
                          child: Text('General / All Properties', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedPropId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    // Category Picker
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_expense_category'),
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Expense Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    // Description
                    TextFormField(
                      key: const Key('input_expense_description'),
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description / Purpose',
                        hintText: 'e.g. Plumber repair, caretaker wage',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 14),
                    // Amount
                    TextFormField(
                      key: const Key('input_expense_amount'),
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount (₱)',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        final amt = int.tryParse(val?.trim() ?? '');
                        if (amt == null || amt <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Receipt / Reference #
                    TextField(
                      key: const Key('input_expense_ref'),
                      controller: refCtrl,
                      decoration: InputDecoration(
                        labelText: 'Receipt / OR / Invoice # (Optional)',
                        hintText: 'e.g. OR-8812, MRL-1029',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                key: const Key('btn_confirm_log_expense'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final propName = selectedPropId == 'GENERAL'
                      ? 'General Portfolio'
                      : (_properties.firstWhere((p) => p.id == selectedPropId, orElse: () => _properties.first).name);

                  final newExp = ExpenseRecord(
                    id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                    propertyId: selectedPropId == 'GENERAL' ? null : selectedPropId,
                    propertyName: propName,
                    category: selectedCategory,
                    description: descCtrl.text.trim(),
                    amount: int.parse(amountCtrl.text.trim()),
                    dateFormatted: DateFormat('MMM d, y').format(DateTime.now()),
                    receiptRef: refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : null,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  Navigator.pop(dialogCtx);
                  setState(() {
                    _expenses.insert(0, newExp);
                  });
                  DatabaseHelper.instance.insertExpense(newExp);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryDeep,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Expense of ₱${NumberFormat('#,###').format(newExp.amount)} logged for $propName!',
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
                ),
                child: const Text('Save Expense'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteExpense(ExpenseRecord expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC92A2A), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Expense?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppTheme.getInkColor(dialogCtx),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ₱${NumberFormat('#,###').format(expense.amount)} (${expense.description})? This cannot be undone.',
          style: TextStyle(fontSize: 14, color: AppTheme.getInkColor(dialogCtx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_expense'),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() {
                _expenses.removeWhere((e) => e.id == expense.id);
              });
              DatabaseHelper.instance.deleteExpense(expense.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFC92A2A),
                  content: Text('Expense record deleted.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC92A2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareExpenseSummary() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('PROPERTY EXPENSE & NET INCOME REPORT');
    buffer.writeln('Generated: ${DateFormat('MMMM d, y').format(DateTime.now())}');
    final propName = _selectedPropertyId == 'ALL'
        ? 'All Properties (Portfolio Total)'
        : _properties.firstWhere((p) => p.id == _selectedPropertyId, orElse: () => _properties.first).name;
    buffer.writeln('Scope: $propName');
    buffer.writeln('========================================');
    buffer.writeln('Gross Rent Collected: ₱${NumberFormat('#,###').format(_totalGrossRevenue)}');
    buffer.writeln('Total Operating Expenses: ₱${NumberFormat('#,###').format(_totalExpenses)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('NET RENTAL PROFIT: ₱${NumberFormat('#,###').format(_netProfit)}');
    buffer.writeln('Net Profit Margin: ${_profitMargin.toStringAsFixed(1)}%');
    buffer.writeln('========================================');
    buffer.writeln('OPERATING EXPENSES BREAKDOWN:');
    if (_filteredExpenses.isEmpty) {
      buffer.writeln('No expenses recorded for this period.');
    } else {
      for (final exp in _filteredExpenses) {
        final refStr = exp.receiptRef != null ? ' (Ref: ${exp.receiptRef})' : '';
        buffer.writeln('• ${exp.dateFormatted} [${exp.category}]: ₱${NumberFormat('#,###').format(exp.amount)} — ${exp.description}$refStr');
      }
    }
    buffer.writeln('========================================');
    buffer.writeln('Generated via Tenera Property Manager');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryDeep,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '✓ Expense & Net Income Report copied to clipboard!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getSurfaceElevatedColor(context),
        elevation: 0,
        title: Text(
          'Expenses & Net Profit',
          style: TextStyle(
            color: AppTheme.getInkColor(context),
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('btn_share_expense_report'),
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share / Copy Report',
            onPressed: _shareExpenseSummary,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_log_expense'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Expense', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openLogExpenseDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Property Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const Key('dropdown_property_filter'),
                        value: _selectedPropertyId,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        items: [
                          const DropdownMenuItem(
                            value: 'ALL',
                            child: Text('All Properties (Portfolio Total)', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          ..._properties.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPropertyId = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Financial Performance Summary Cards
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryDeep,
                          AppTheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'NET RENTAL PROFIT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_profitMargin.toStringAsFixed(1)}% Margin',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₱${currencyFmt.format(_netProfit)}',
                          key: const Key('text_net_profit_amount'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Gross Collections', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${currencyFmt.format(_totalGrossRevenue)}',
                                      key: const Key('text_gross_collections_amount'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 32, color: Colors.white24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Operating Expenses', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${currencyFmt.format(_totalExpenses)}',
                                      key: const Key('text_total_expenses_amount'),
                                      style: const TextStyle(color: Color(0xFFFFB4AB), fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          key: const Key('chip_category_all'),
                          label: const Text('All Categories'),
                          selected: _selectedCategory == 'ALL',
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = 'ALL');
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: _selectedCategory == c,
                                onSelected: (val) {
                                  setState(() => _selectedCategory = val ? c : 'ALL');
                                },
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Expense Records Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXPENSE RECORDS (${_filteredExpenses.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppTheme.getInkMutedColor(context),
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('btn_quick_add_expense'),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: _openLogExpenseDialog,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_filteredExpenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.getInkMutedColor(context)),
                          const SizedBox(height: 10),
                          Text(
                            'No expenses logged yet.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getInkColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Log Expense" to record maintenance, utilities, or staff wages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredExpenses.map((exp) {
                      IconData catIcon;
                      Color catColor;
                      switch (exp.category) {
                        case 'Repairs & Maintenance':
                          catIcon = Icons.build_rounded;
                          catColor = const Color(0xFFD97706);
                          break;
                        case 'Utilities':
                          catIcon = Icons.flash_on_rounded;
                          catColor = const Color(0xFF0284C7);
                          break;
                        case 'Caretaker & Staff':
                          catIcon = Icons.badge_rounded;
                          catColor = const Color(0xFF7C3AED);
                          break;
                        case 'Taxes & Permits':
                          catIcon = Icons.account_balance_rounded;
                          catColor = const Color(0xFF059669);
                          break;
                        case 'Supplies & Cleaning':
                          catIcon = Icons.cleaning_services_rounded;
                          catColor = const Color(0xFFDB2777);
                          break;
                        default:
                          catIcon = Icons.receipt_rounded;
                          catColor = AppTheme.primary;
                          break;
                      }

                      return Container(
                        key: Key('expense_card_${exp.id}'),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.getBorderColor(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(catIcon, color: catColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          exp.description,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppTheme.getInkColor(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${exp.propertyName} · ${exp.category}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.getInkMutedColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${exp.dateFormatted}${exp.receiptRef != null ? " · Ref: ${exp.receiptRef}" : ""}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.getInkMutedColor(context).withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-₱${currencyFmt.format(exp.amount)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFC92A2A),
                                  ),
                                ),
                                IconButton(
                                  key: Key('btn_delete_expense_${exp.id}'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.inkMuted),
                                  onPressed: () => _confirmDeleteExpense(exp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

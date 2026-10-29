import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/maintenance_ticket.dart';
import '../models/property.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class MaintenanceTrackerScreen extends StatefulWidget {
  final List<MaintenanceTicket>? initialTickets;
  final List<PropertyItem>? initialProperties;

  const MaintenanceTrackerScreen({
    super.key,
    this.initialTickets,
    this.initialProperties,
  });

  @override
  State<MaintenanceTrackerScreen> createState() => _MaintenanceTrackerScreenState();
}

class _MaintenanceTrackerScreenState extends State<MaintenanceTrackerScreen> {
  List<MaintenanceTicket> _tickets = [];
  List<PropertyItem> _properties = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'ALL';
  String _selectedPropertyFilter = 'ALL';

  static const List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Appliance',
    'Roofing / Leaks',
    'General',
  ];

  static const List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Emergency',
  ];

  static const List<String> _statuses = [
    'Reported',
    'In Progress',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTickets != null && widget.initialProperties != null) {
      _tickets = List.from(widget.initialTickets!);
      _properties = List.from(widget.initialProperties!);
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_tickets.isEmpty && _properties.isEmpty) {
      setState(() => _isLoading = true);
    }
    final props = await DatabaseHelper.instance.getProperties();
    final tix = await DatabaseHelper.instance.getMaintenanceTickets();
    if (mounted) {
      setState(() {
        _properties = props;
        _tickets = tix;
        _isLoading = false;
      });
    }
  }

  List<MaintenanceTicket> get _filteredTickets {
    return _tickets.where((t) {
      final matchesProp = _selectedPropertyFilter == 'ALL' || t.propertyId == _selectedPropertyFilter;
      final matchesStatus = _selectedStatusFilter == 'ALL' || t.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
      return matchesProp && matchesStatus;
    }).toList();
  }

  int get _openTicketsCount => _tickets.where((t) => !t.isResolved).length;
  int get _urgentTicketsCount => _tickets.where((t) => !t.isResolved && (t.priority == 'High' || t.priority == 'Emergency')).length;
  int get _resolvedTicketsCount => _tickets.where((t) => t.isResolved).length;
  int get _totalRepairCost => _tickets.fold(0, (sum, t) => sum + (t.cost ?? 0));

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return const Color(0xFFC92A2A);
      case 'high':
        return const Color(0xFFE8590C);
      case 'medium':
        return const Color(0xFF1971C2);
      default:
        return const Color(0xFF868E96);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.water_drop_rounded;
      case 'electrical':
        return Icons.bolt_rounded;
      case 'carpentry':
        return Icons.carpenter_rounded;
      case 'appliance':
        return Icons.kitchen_rounded;
      case 'roofing / leaks':
        return Icons.roofing_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  void _openAddTicketDialog() {
    final formKey = GlobalKey<FormState>();
    String selectedPropId = _selectedPropertyFilter == 'ALL'
        ? (_properties.isNotEmpty ? _properties.first.id : '')
        : _selectedPropertyFilter;
    String roomCode = '';
    String category = _categories.first;
    String priority = 'Medium';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentProp = _properties.firstWhere(
            (p) => p.id == selectedPropId,
            orElse: () => _properties.isNotEmpty ? _properties.first : PropertyItem(id: '', name: '', address: '', totalUnits: 0, occupiedUnits: 0, monthlyRevenue: 0, rooms: []),
          );
          final availableRooms = currentProp.rooms.map((r) => r.code).toList();
          if (roomCode.isEmpty && availableRooms.isNotEmpty) {
            roomCode = availableRooms.first;
          }

          return AlertDialog(
            backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8590C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_circle_rounded, color: Color(0xFFE8590C), size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'Log Repair Request',
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
                    // Property selection
                    DropdownButtonFormField<String>(
                      initialValue: selectedPropId.isNotEmpty ? selectedPropId : null,
                      decoration: InputDecoration(
                        labelText: 'Property',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedPropId = val;
                            roomCode = '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Unit code
                    if (availableRooms.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: availableRooms.contains(roomCode) ? roomCode : availableRooms.first,
                        decoration: InputDecoration(
                          labelText: 'Unit / Room',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: availableRooms.map((r) => DropdownMenuItem(value: r, child: Text('Unit $r'))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => roomCode = val);
                        },
                      )
                    else
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Unit / Room Code',
                          hintText: 'e.g. Unit 2B or Common Area',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => roomCode = val.trim(),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter a unit code' : null,
                      ),
                    const SizedBox(height: 12),
                    // Category & Priority Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: priority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => priority = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    TextFormField(
                      key: const Key('input_ticket_title'),
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Issue / Repair Title',
                        hintText: 'e.g. Leaking shower, broken latch',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 12),
                    // Description
                    TextFormField(
                      key: const Key('input_ticket_desc'),
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes / Details',
                        hintText: 'e.g. Water dripping under sink since yesterday',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Estimated Cost
                    TextField(
                      key: const Key('input_ticket_cost'),
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estimated / Actual Cost (₱) (Optional)',
                        prefixText: '₱ ',
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
                key: const Key('btn_confirm_log_ticket'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final propName = currentProp.name.isNotEmpty ? currentProp.name : 'General Portfolio';
                  final costVal = int.tryParse(costCtrl.text.trim());

                  final newTicket = MaintenanceTicket(
                    id: 'mt_${DateTime.now().millisecondsSinceEpoch}',
                    propertyId: selectedPropId,
                    propertyName: propName,
                    roomCode: roomCode.isNotEmpty ? roomCode : 'General',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: category,
                    priority: priority,
                    status: 'Reported',
                    cost: costVal,
                    reportedDate: DateFormat('MMM d, y').format(DateTime.now()),
                    resolvedDate: null,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  Navigator.pop(dialogCtx);
                  setState(() {
                    _tickets.insert(0, newTicket);
                  });
                  DatabaseHelper.instance.insertMaintenanceTicket(newTicket);

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
                              'Repair ticket "${newTicket.title}" logged for ${newTicket.roomCode}!',
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
                child: const Text('Save Ticket'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangeStatusDialog(MaintenanceTicket ticket) {
    String currentStatus = ticket.status;
    final costCtrl = TextEditingController(text: ticket.cost != null ? ticket.cost.toString() : '');
    bool syncToExpenses = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.getSurfaceElevatedColor(dialogCtx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Update Status',
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
                  '${ticket.title} · ${ticket.roomCode} (${ticket.propertyName})',
                  style: TextStyle(fontSize: 13, color: AppTheme.getInkMutedColor(dialogCtx)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('dropdown_ticket_status'),
                  initialValue: currentStatus,
                  decoration: InputDecoration(
                    labelText: 'Ticket Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentStatus = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('input_update_ticket_cost'),
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Repair / Plumber Cost (₱)',
                    prefixText: '₱ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (currentStatus == 'Resolved') ...[
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    key: const Key('checkbox_sync_expense'),
                    value: syncToExpenses,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    title: const Text('Log repair cost into Property Expenses automatically', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Deducts cost from net rental profit', style: TextStyle(fontSize: 11)),
                    onChanged: (v) => setDialogState(() => syncToExpenses = v ?? true),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('btn_confirm_update_ticket'),
                onPressed: () async {
                  final costVal = int.tryParse(costCtrl.text.trim());
                  final resolvedDateStr = currentStatus == 'Resolved' ? DateFormat('MMM d, y').format(DateTime.now()) : null;

                  final updatedTicket = ticket.copyWith(
                    status: currentStatus,
                    cost: costVal,
                    resolvedDate: resolvedDateStr,
                  );

                  Navigator.pop(dialogCtx);
                  setState(() {
                    final idx = _tickets.indexWhere((t) => t.id == ticket.id);
                    if (idx != -1) _tickets[idx] = updatedTicket;
                  });
                  DatabaseHelper.instance.updateMaintenanceTicket(updatedTicket);

                  // Auto-log to expenses if requested
                  if (currentStatus == 'Resolved' && syncToExpenses && costVal != null && costVal > 0) {
                    final expRecord = ExpenseRecord(
                      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                      propertyId: ticket.propertyId.isNotEmpty ? ticket.propertyId : null,
                      propertyName: ticket.propertyName,
                      category: 'Repairs & Maintenance',
                      description: '${ticket.title} (${ticket.roomCode})',
                      amount: costVal,
                      dateFormatted: DateFormat('MMM d, y').format(DateTime.now()),
                      receiptRef: 'TICKET-${ticket.id.substring(ticket.id.length - 4)}',
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    );
                    await DatabaseHelper.instance.insertExpense(expRecord);
                  }

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryDeep,
                      content: Text('Status updated to $currentStatus!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteTicket(MaintenanceTicket ticket) {
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
              'Delete Ticket?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppTheme.getInkColor(dialogCtx),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ticket "${ticket.title}" for ${ticket.roomCode}? This cannot be undone.',
          style: TextStyle(fontSize: 14, color: AppTheme.getInkColor(dialogCtx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_ticket'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _tickets.removeWhere((t) => t.id == ticket.id);
              });
              DatabaseHelper.instance.deleteMaintenanceTicket(ticket.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFC92A2A),
                  content: Text('Maintenance ticket deleted.'),
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

  void _shareMaintenanceSummary() {
    final buffer = StringBuffer();
    final fmt = NumberFormat('#,###');
    buffer.writeln('========================================');
    buffer.writeln('TENERA UNIT MAINTENANCE & REPAIRS REPORT');
    buffer.writeln('Date: ${DateFormat('MMMM d, y').format(DateTime.now())}');
    buffer.writeln('========================================');
    buffer.writeln('Active Open Requests: $_openTicketsCount');
    buffer.writeln('Urgent / Emergency: $_urgentTicketsCount');
    buffer.writeln('Resolved Repairs: $_resolvedTicketsCount');
    buffer.writeln('Total Repair Cost Logged: ₱${fmt.format(_totalRepairCost)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('REPAIR TASKS:');

    for (final t in _filteredTickets) {
      final costStr = t.cost != null ? ' · ₱${fmt.format(t.cost)}' : '';
      buffer.writeln('• [${t.status.toUpperCase()}] Unit ${t.roomCode} (${t.propertyName}) - ${t.title} [${t.priority} Priority]$costStr');
      if (t.description.isNotEmpty) {
        buffer.writeln('  Notes: ${t.description}');
      }
    }
    buffer.writeln('========================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.primaryDeep,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '✓ Maintenance & Repair list copied to clipboard!',
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Unit Maintenance & Repairs',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('btn_share_maintenance_summary'),
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryDeep),
            tooltip: 'Share / Copy Repair List',
            onPressed: _tickets.isEmpty ? null : _shareMaintenanceSummary,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_log_ticket'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Repair', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openAddTicketDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppTheme.isDark(context)
                            ? [const Color(0xFF1E3A34), const Color(0xFF132824)]
                            : [AppTheme.primaryDeep, AppTheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDeep.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ACTIVE REPAIR TICKETS',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$_openTicketsCount Open',
                                    key: const Key('text_open_tickets_count'),
                                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _urgentTicketsCount > 0 ? const Color(0xFFE8590C) : Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_urgentTicketsCount > 0 ? Icons.warning_rounded : Icons.check_circle_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_urgentTicketsCount Urgent',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resolved: $_resolvedTicketsCount repairs',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              'Logged Costs: ₱${currencyFmt.format(_totalRepairCost)}',
                              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Row
                  Row(
                    children: [
                      // Status Segmented Chips
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusChip('ALL', 'All'),
                              const SizedBox(width: 6),
                              _buildStatusChip('Reported', 'Reported'),
                              const SizedBox(width: 6),
                              _buildStatusChip('In Progress', 'In Progress'),
                              const SizedBox(width: 6),
                              _buildStatusChip('Resolved', 'Resolved'),
                            ],
                          ),
                        ),
                      ),
                      if (_properties.length > 1) ...[
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedPropertyFilter,
                          dropdownColor: AppTheme.getSurfaceElevatedColor(context),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(value: 'ALL', child: Text('All Properties', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                            ..._properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 12)))),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedPropertyFilter = v);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Ticket List
                  if (_filteredTickets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, size: 48, color: AppTheme.getInkMutedColor(context)),
                          const SizedBox(height: 12),
                          Text(
                            'No maintenance tickets found.',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getInkColor(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ Log Repair" to report a plumbing or electrical issue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.getInkMutedColor(context)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredTickets.map((t) => _buildTicketCard(t, currencyFmt)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.getInkColor(context),
      ),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.getSurfaceColor(context),
      onSelected: (_) => setState(() => _selectedStatusFilter = value),
    );
  }

  Widget _buildTicketCard(MaintenanceTicket ticket, NumberFormat currencyFmt) {
    final priorityColor = _getPriorityColor(ticket.priority);
    final categoryIcon = _getCategoryIcon(ticket.category);

    return Container(
      key: Key('ticket_card_${ticket.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Category Icon + Unit Code + Priority & Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon, size: 18, color: priorityColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${ticket.roomCode} · ${ticket.propertyName}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getInkMutedColor(context)),
                      ),
                      Text(
                        ticket.title,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getInkColor(context)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.priority.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: priorityColor),
                  ),
                ),
              ],
            ),
            if (ticket.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: TextStyle(fontSize: 13, color: AppTheme.getInkColor(context), height: 1.3),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Footer: Date + Cost + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.getInkMutedColor(context)),
                    const SizedBox(width: 4),
                    Text(
                      ticket.reportedDate,
                      style: TextStyle(fontSize: 11, color: AppTheme.getInkMutedColor(context)),
                    ),
                    if (ticket.cost != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '₱${currencyFmt.format(ticket.cost)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryDeep),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      key: Key('btn_update_status_${ticket.id}'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showChangeStatusDialog(ticket),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ticket.isResolved
                              ? const Color(0xFF2B8A3E).withValues(alpha: 0.15)
                              : AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ticket.isResolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                              size: 14,
                              color: ticket.isResolved ? const Color(0xFF2B8A3E) : AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ticket.isResolved ? const Color(0xFF2B8A3E) : AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: Key('btn_delete_ticket_${ticket.id}'),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC92A2A)),
                      tooltip: 'Delete Ticket',
                      onPressed: () => _confirmDeleteTicket(ticket),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

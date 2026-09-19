import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/payroll.dart';
import '../models/user.dart';
import '../models/absence_form.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isRunningPayroll = false;
  StoreUser? _currentUser;
  bool _isOwnerOrManager = false;
  bool _isUserLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final user = await _firestoreService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
        _isOwnerOrManager = user.role == UserRole.owner || user.role == UserRole.manager;
        _isUserLoaded = true;
      });
    }
  }

  String _monthName(int month) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month];
  }

  void _runPayroll() async {
    if (_isRunningPayroll) return;
    try {
      setState(() => _isRunningPayroll = true);
      final users = await _firestoreService.getUsers().first;
      final attendance = await _firestoreService.getAttendance().first;
      final absenceForms = await _firestoreService.getAbsenceForms().first;
      final existingPayrolls = await _firestoreService.getPayrolls().first;

      final now = DateTime.now();
      final periodStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final periodEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${DateTime(now.year, now.month + 1, 0).day.toString().padLeft(2, '0')}';

      final alreadyGenerated = existingPayrolls.where((r) =>
        r.periodStart == periodStart && r.periodEnd == periodEnd).toList();
      if (alreadyGenerated.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payroll already generated for ${_monthName(now.month)} ${now.year}')),
          );
          setState(() => _isRunningPayroll = false);
        }
        return;
      }

      int count = 0;
      for (final user in users) {
        final userRecords = attendance.where((r) =>
          r.employeeId == user.uid &&
          r.date.compareTo(periodStart) >= 0 &&
          r.date.compareTo(periodEnd) <= 0).toList();

        final totalHours = userRecords.fold<double>(0, (s, r) => s + r.totalHours).toInt();
        final overtimeHours = userRecords.fold<double>(0, (s, r) => s + r.overtimeHours).toInt();
        final basicPay = totalHours * user.rate;
        final overtimePay = overtimeHours * user.rate * 1.5;

        final userAbsences = absenceForms.where((f) =>
          f.employeeId == user.uid &&
          f.status == AbsenceStatus.approved &&
          f.startDate.compareTo(DateTime.parse(periodEnd)) <= 0 &&
          f.endDate.compareTo(DateTime.parse(periodStart)) >= 0).toList();

        int paidLeaveDays = 0;
        int unpaidLeaveDays = 0;
        for (final absence in userAbsences) {
          final days = absence.endDate.difference(absence.startDate).inDays + 1;
          if (absence.isPaidLeave) {
            paidLeaveDays += days;
          } else {
            unpaidLeaveDays += days;
          }
        }

        final leavePay = paidLeaveDays * user.rate * 8;

        await _firestoreService.addPayroll(PayrollRecord(
          id: '',
          employeeId: user.uid,
          employeeName: user.name,
          role: user.role.value,
          periodStart: periodStart,
          periodEnd: periodEnd,
          hourlyRate: user.rate,
          totalHours: totalHours,
          overtimeHours: overtimeHours,
          basicPay: basicPay,
          overtimePay: overtimePay,
          totalGross: basicPay + overtimePay + leavePay,
          deductions: [],
          totalDeductions: 0,
          netPay: basicPay + overtimePay + leavePay,
          paidLeaveDays: paidLeaveDays,
          unpaidLeaveDays: unpaidLeaveDays,
          status: 'pending',
          createdAt: DateTime.now(),
        ));
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payroll generated for $count employees. Edit deductions before marking as paid.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to generate payroll. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningPayroll = false);
    }
  }

  void _editDeductions(PayrollRecord record) async {
    final result = await showDialog<PayrollRecord>(
      context: context,
      builder: (ctx) => _DeductionEditorDialog(record: record),
    );
    if (result != null) {
      try {
        await _firestoreService.updatePayroll(result.id, {
          'deductions': result.deductions.map((d) => d.toMap()).toList(),
          'totalDeductions': result.totalDeductions,
          'netPay': result.netPay,
          'ownerNotes': result.ownerNotes,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payroll updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update. Please try again.'), backgroundColor: BaycelColors.error),
          );
        }
      }
    }
  }

  void _markAsPaid(String payrollId) async {
    try {
      await _firestoreService.updatePayroll(payrollId, {
        'status': 'paid',
        'paidAt': DateTime.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as paid')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserLoaded) {
      return const Center(child: SkeletonDashboard());
    }

    return StreamBuilder<List<PayrollRecord>>(
      stream: _firestoreService.getPayrolls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SkeletonDashboard());
        }

        final allRecords = snapshot.data ?? [];
        final records = _isOwnerOrManager
            ? allRecords
            : allRecords.where((r) => r.employeeId == _currentUser?.uid).toList();
        final totalPayroll = records.fold<double>(0, (sum, r) => sum + r.netPay);
        final employeeCount = records.map((r) => r.employeeId).toSet().length;
        final pendingCount = records.where((r) => r.status == 'pending').length;
        final averageNetPay = records.isNotEmpty ? totalPayroll / records.length : 0.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(BaycelSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredItem(index: 0, child: _buildHeader()),
              SizedBox(height: BaycelSpacing.lg),
              StaggeredItem(
                index: 1,
                child: _buildStatsRow(totalPayroll, employeeCount, pendingCount, averageNetPay),
              ),
              SizedBox(height: BaycelSpacing.lg),
              StaggeredItem(index: 2, child: _buildPayrollList(records)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isOwnerOrManager ? 'Payroll' : 'My Payslip', style: BaycelTypography.display.copyWith(fontSize: 26)),
              Text(
                '${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(width: BaycelSpacing.md),
        if (_isOwnerOrManager)
          ElevatedButton(
            onPressed: _isRunningPayroll ? null : _runPayroll,
            style: BaycelComponents.buttonPrimary,
            child: _isRunningPayroll
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Run Payroll'),
          ),
      ],
    );
  }

  Widget _buildStatsRow(
    double totalPayroll,
    int employeeCount,
    int pendingCount,
    double averageNetPay,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossCount,
          crossAxisSpacing: BaycelSpacing.sm,
          mainAxisSpacing: BaycelSpacing.sm,
          childAspectRatio: crossCount == 1 ? 3.5 : 3,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            BaycelCompactStatCard(
              title: 'Total Payroll',
              value: '\u20B1${_formatCurrency(totalPayroll)}',
              icon: Icons.account_balance_wallet,
              color: BaycelColors.viz6,
            ),
            BaycelCompactStatCard(
              title: 'Employees',
              value: '$employeeCount',
              icon: Icons.people,
              color: BaycelColors.viz5,
            ),
            BaycelCompactStatCard(
              title: 'Pending Payslips',
              value: '$pendingCount',
              icon: Icons.pending_actions,
              color: BaycelColors.viz2,
            ),
            BaycelCompactStatCard(
              title: 'Average Net Pay',
              value: '\u20B1${_formatCurrency(averageNetPay)}',
              icon: Icons.show_chart,
              color: BaycelColors.viz1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPayrollList(List<PayrollRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isOwnerOrManager ? 'Payroll Records' : 'My Payslip Records', style: BaycelTypography.headlineMd),
        SizedBox(height: BaycelSpacing.md),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            decoration: BaycelComponents.card,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xl),
              child: Center(
                child: Text('No payroll records found', style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)),
              ),
            ),
          )
        else
          ...records.map((record) => _buildPayrollCard(record)),
      ],
    );
  }

  Widget _buildPayrollCard(PayrollRecord record) {
    final isPending = record.status == 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: BaycelSpacing.sm),
      decoration: BaycelComponents.card,
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: BaycelColors.crimson.withValues(alpha: 0.1),
                  child: Text(
                    record.employeeName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join('').toUpperCase().substring(0, 2),
                    style: BaycelTypography.label.copyWith(color: BaycelColors.crimson),
                  ),
                ),
                SizedBox(width: BaycelSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.employeeName, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      Text(record.role.isNotEmpty ? record.role[0].toUpperCase() + record.role.substring(1) : 'Staff',
                        style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                BaycelStatusPill(
                  label: isPending ? 'Pending' : 'Paid',
                  color: isPending ? BaycelColors.marigoldDark : BaycelColors.success,
                ),
              ],
            ),
            SizedBox(height: BaycelSpacing.md),
            Container(
              padding: EdgeInsets.all(BaycelSpacing.sm),
              decoration: BoxDecoration(
                color: BaycelColors.surface,
                borderRadius: BorderRadius.circular(BaycelRadius.sm),
              ),
              child: Column(
                children: [
                  _buildPayrollRow('Hourly Rate', '\u20B1${record.hourlyRate.toStringAsFixed(0)}/hr'),
                  _buildPayrollRow('Regular Hours', '${record.totalHours} hrs'),
                  _buildPayrollRow('Overtime Hours', '${record.overtimeHours} hrs'),
                  if (record.paidLeaveDays > 0)
                    _buildPayrollRow('Paid Leave', '${record.paidLeaveDays} days', color: BaycelColors.success),
                  if (record.unpaidLeaveDays > 0)
                    _buildPayrollRow('Unpaid Leave', '${record.unpaidLeaveDays} days', color: BaycelColors.error),
                  Divider(color: BaycelColors.divider),
                  _buildPayrollRow('Basic Pay', '\u20B1${_formatCurrency(record.basicPay)}', bold: true),
                  _buildPayrollRow('Overtime Pay', '\u20B1${_formatCurrency(record.overtimePay)}'),
                  if (record.paidLeaveDays > 0)
                    _buildPayrollRow('Leave Pay', '\u20B1${_formatCurrency(record.paidLeaveDays * record.hourlyRate * 8)}', color: BaycelColors.success),
                  _buildPayrollRow('Gross Pay', '\u20B1${_formatCurrency(record.totalGross)}', bold: true),
                ],
              ),
            ),
            if (record.deductions.isNotEmpty || record.totalDeductions > 0) ...[
              SizedBox(height: BaycelSpacing.sm),
              Container(
                padding: EdgeInsets.all(BaycelSpacing.sm),
                decoration: BoxDecoration(
                  color: BaycelColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(BaycelRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.remove_circle_outline, size: 14, color: BaycelColors.error),
                        SizedBox(width: 6),
                        Text('Deductions', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 4),
                    ...record.deductions.map((d) => _buildPayrollRow(d.description, '\u20B1${_formatCurrency(d.amount)}', color: BaycelColors.error)),
                    Divider(color: BaycelColors.error.withValues(alpha: 0.3)),
                    _buildPayrollRow('Total Deductions', '\u20B1${_formatCurrency(record.totalDeductions)}', bold: true, color: BaycelColors.error),
                  ],
                ),
              ),
            ],
            SizedBox(height: BaycelSpacing.sm),
            Container(
              padding: EdgeInsets.all(BaycelSpacing.sm),
              decoration: BoxDecoration(
                color: BaycelColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(BaycelRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Pay', style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w700, color: BaycelColors.success)),
                  Text('\u20B1${_formatCurrency(record.netPay)}', style: BaycelTypography.headlineMd.copyWith(color: BaycelColors.success)),
                ],
              ),
            ),
            if (record.ownerNotes != null && record.ownerNotes!.isNotEmpty) ...[
              SizedBox(height: BaycelSpacing.sm),
              Container(
                padding: EdgeInsets.all(BaycelSpacing.sm),
                decoration: BoxDecoration(
                  color: BaycelColors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(BaycelRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 14, color: BaycelColors.blue),
                    SizedBox(width: 6),
                    Expanded(child: Text(record.ownerNotes!, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12))),
                  ],
                ),
              ),
            ],
            if (_isOwnerOrManager && isPending) ...[
              SizedBox(height: BaycelSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editDeductions(record),
                      icon: Icon(Icons.edit, size: 14),
                      label: Text('Edit Deductions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BaycelColors.crimson,
                        side: BorderSide(color: BaycelColors.crimson.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsPaid(record.id),
                      icon: Icon(Icons.check, size: 14, color: Colors.white),
                      label: Text('Mark Paid', style: TextStyle(color: Colors.white)),
                      style: BaycelComponents.buttonPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (!isPending && record.paidAt != null)
              Padding(
                padding: EdgeInsets.only(top: BaycelSpacing.sm),
                child: Text('Paid on ${record.paidAt?.month}/${record.paidAt?.day}/${record.paidAt?.year}',
                  style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BaycelTypography.bodySm.copyWith(
            fontSize: 12,
            color: color ?? BaycelColors.textSecondary,
          )),
          Text(value, style: BaycelTypography.dataMono.copyWith(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: color ?? BaycelColors.textPrimary,
          )),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final whole = amount.truncate();
    final fraction = ((amount - whole) * 100).round().toString().padLeft(2, '0');
    final formatted = whole.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m.group(1)},',
    );
    return '$formatted.$fraction';
  }
}

class _DeductionEditorDialog extends StatefulWidget {
  final PayrollRecord record;

  const _DeductionEditorDialog({required this.record});

  @override
  State<_DeductionEditorDialog> createState() => _DeductionEditorDialogState();
}

class _DeductionEditorDialogState extends State<_DeductionEditorDialog> {
  late List<PayrollDeduction> _deductions;
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deductions = List.from(widget.record.deductions);
    _notesController.text = widget.record.ownerNotes ?? '';
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addDeduction() {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (desc.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter description and valid amount')),
      );
      return;
    }
    setState(() {
      _deductions.add(PayrollDeduction(description: desc, amount: amount));
      _descController.clear();
      _amountController.clear();
    });
  }

  void _removeDeduction(int index) {
    setState(() => _deductions.removeAt(index));
  }

  void _save() {
    final totalDeductions = _deductions.fold<double>(0, (sum, d) => sum + d.amount);
    final netPay = widget.record.totalGross - totalDeductions;
    Navigator.pop(context, PayrollRecord(
      id: widget.record.id,
      employeeId: widget.record.employeeId,
      employeeName: widget.record.employeeName,
      role: widget.record.role,
      periodStart: widget.record.periodStart,
      periodEnd: widget.record.periodEnd,
      hourlyRate: widget.record.hourlyRate,
      totalHours: widget.record.totalHours,
      overtimeHours: widget.record.overtimeHours,
      basicPay: widget.record.basicPay,
      overtimePay: widget.record.overtimePay,
      totalGross: widget.record.totalGross,
      deductions: _deductions,
      totalDeductions: totalDeductions,
      netPay: netPay,
      paidLeaveDays: widget.record.paidLeaveDays,
      unpaidLeaveDays: widget.record.unpaidLeaveDays,
      status: widget.record.status,
      ownerNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      paidAt: widget.record.paidAt,
      createdAt: widget.record.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalDeductions = _deductions.fold<double>(0, (sum, d) => sum + d.amount);
    final netPay = widget.record.totalGross - totalDeductions;

    return AlertDialog(
      title: Text('Edit Deductions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.record.employeeName, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
            Text('Gross Pay: \u20B1${widget.record.totalGross.toStringAsFixed(2)}', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
            SizedBox(height: BaycelSpacing.md),
            if (_deductions.isNotEmpty) ...[
              Text('Deductions:', style: BaycelTypography.labelSm.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              ...List.generate(_deductions.length, (i) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${_deductions[i].description} - \u20B1${_deductions[i].amount.toStringAsFixed(2)}',
                        style: BaycelTypography.bodySm.copyWith(fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: () => _removeDeduction(i),
                      child: Icon(Icons.close, size: 14, color: BaycelColors.error),
                    ),
                  ],
                ),
              )),
              SizedBox(height: BaycelSpacing.sm),
            ],
            TextField(
              controller: _descController,
              decoration: BaycelComponents.input.copyWith(hintText: 'Description (e.g., SSS, PhilHealth, Cash Advance)'),
              style: BaycelTypography.body.copyWith(fontSize: 13),
            ),
            SizedBox(height: BaycelSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: BaycelComponents.input.copyWith(hintText: 'Amount'),
              style: BaycelTypography.body.copyWith(fontSize: 13),
            ),
            SizedBox(height: BaycelSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addDeduction,
                icon: Icon(Icons.add, size: 14),
                label: Text('Add Deduction'),
              ),
            ),
            SizedBox(height: BaycelSpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: BaycelComponents.input.copyWith(hintText: 'Owner notes (optional)'),
              style: BaycelTypography.body.copyWith(fontSize: 13),
            ),
            SizedBox(height: BaycelSpacing.md),
            Container(
              padding: EdgeInsets.all(BaycelSpacing.sm),
              decoration: BoxDecoration(
                color: BaycelColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(BaycelRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Pay', style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
                  Text('\u20B1${netPay.toStringAsFixed(2)}', style: BaycelTypography.headlineMd.copyWith(color: BaycelColors.success)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          style: BaycelComponents.buttonPrimary,
          child: Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

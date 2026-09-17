import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/payroll.dart';
import '../models/user.dart';

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

        final totalHours = userRecords.fold<double>(0, (s, r) => s + r.totalHours);
        final basicPay = totalHours * user.rate;
        final overtimePay = userRecords.fold<double>(0, (s, r) => s + r.overtimeHours) * user.rate * 1.5;
        final deductions = basicPay * 0.1;
        final netPay = basicPay + overtimePay - deductions;

        await _firestoreService.addPayroll(PayrollRecord(
          id: '',
          employeeId: user.uid,
          employeeName: user.name,
          role: user.role.value,
          periodStart: periodStart,
          periodEnd: periodEnd,
          basicPay: basicPay,
          overtimePay: overtimePay,
          deductions: deductions,
          netPay: netPay,
          status: 'pending',
          createdAt: DateTime.now(),
        ));
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payroll generated for $count employees'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: BaycelColors.crimson,
              onPressed: () async {
                try {
                  final fresh = await _firestoreService.getPayrolls().first;
                  final toDelete = fresh.where((r) =>
                    r.periodStart == periodStart && r.periodEnd == periodEnd).toList();
                  for (final record in toDelete) {
                    await _firestoreService.deletePayroll(record.id);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payroll for ${_monthName(now.month)} ${now.year} undone')),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to undo. Please delete manually.'), backgroundColor: BaycelColors.error),
                    );
                  }
                }
              },
            ),
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
              StaggeredItem(index: 2, child: _buildPayrollTable(records)),
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

  Widget _buildPayrollTable(List<PayrollRecord> records) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BaycelComponents.card,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(2),
                        5: FlexColumnWidth(2),
                        6: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          children: [
                            _buildTh('Employee'),
                            _buildTh('Role'),
                            _buildTh('Gross Pay'),
                            _buildTh('Deductions'),
                            _buildTh('Net Pay'),
                            _buildTh('Status'),
                            if (_isOwnerOrManager) _buildTh('Action'),
                          ],
                        ),
                        ...records.map((record) => _buildTr(record)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTh(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary)),
    );
  }

  TableRow _buildTr(PayrollRecord record) {
    final grossPay = record.basicPay + record.overtimePay;

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5)),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(record.employeeName, style: BaycelTypography.body.copyWith(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(record.role.isNotEmpty ? record.role[0].toUpperCase() + record.role.substring(1) : 'Staff', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text('\u20B1${_formatCurrency(grossPay)}', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text('\u20B1${_formatCurrency(record.deductions)}', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text('\u20B1${_formatCurrency(record.netPay)}', style: BaycelTypography.dataMono.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: BaycelStatusPill(
            label: record.status == 'paid' ? 'Paid' : 'Pending',
            color: record.status == 'paid' ? BaycelColors.success : BaycelColors.marigoldDark,
          ),
        ),
        if (_isOwnerOrManager)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
            child: record.status == 'pending'
              ? SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () => _markAsPaid(record.id),
                    style: BaycelComponents.buttonPrimary.copyWith(
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                    ),
                    child: Text('Mark Paid', style: BaycelTypography.labelXs.copyWith(color: Colors.white)),
                  ),
                )
              : Text('${record.paidAt?.month}/${record.paidAt?.day}', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
          ),
      ],
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

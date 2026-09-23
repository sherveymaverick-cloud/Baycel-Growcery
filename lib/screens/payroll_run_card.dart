import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/payroll.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/absence_form.dart';
import '../models/deductible_template.dart';

class PayrollRunCard extends StatefulWidget {
  const PayrollRunCard({super.key});

  @override
  State<PayrollRunCard> createState() => _PayrollRunCardState();
}

class _PayrollRunCardState extends State<PayrollRunCard> {
  final FirestoreService _service = FirestoreService();

  bool _loading = true;
  bool _generating = false;
  String? _error;
  String? _warning;

  List<StoreUser> _employees = [];
  List<AttendanceRecord> _attendance = [];
  List<AbsenceForm> _absences = [];
  List<DeductibleTemplate> _templates = [];
  Set<String> _existingKeys = {};

  int _paydayFilter = 0; // 0 = all, 7, 15
  final Set<String> _selected = {};
  bool _stagePreview = false;
  List<PayrollRecord> _previewRecords = [];
  int _activeTab = 0;

  late String _periodStart;
  late String _periodEnd;
  late String _periodLabel;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    _periodStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    _periodEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    _periodLabel = '${names[now.month]} ${now.year}';
    _load();
  }

  Future<void> _load() async {
    List<StoreUser> users = [];
    List<AttendanceRecord> attendance = [];
    List<PayrollRecord> payrolls = [];
    List<AbsenceForm> absences = [];
    List<DeductibleTemplate> templates = [];
    final failures = <String>[];

    try {
      users = await _service.getUsers().first;
    } catch (e) {
      debugPrint('payroll load users failed: $e');
      failures.add('employees');
    }

    try {
      attendance = await _service.getAllAttendance();
    } catch (e) {
      debugPrint('payroll load attendance failed: $e');
      failures.add('attendance');
    }

    try {
      payrolls = await _service.getPayrollsOnce();
    } catch (e) {
      debugPrint('payroll load payrolls failed: $e');
      failures.add('existing payslips');
    }

    try {
      absences = await _service.getAbsenceForms().first;
    } catch (e) {
      debugPrint('payroll load absences failed: $e');
    }

    try {
      templates = await _service.getDeductibleTemplatesOnce();
    } catch (e) {
      debugPrint('payroll load deductible_templates failed: $e');
    }

    if (!mounted) return;

    if (failures.contains('employees')) {
      setState(() {
        _loading = false;
        _error = 'Unable to load employees. Check Firestore rules allow the owner to read users.';
      });
      return;
    }

    setState(() {
      _employees = users
          .where((u) => u.role != UserRole.owner && u.role != UserRole.merchandiser)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _attendance = attendance;
      _absences = absences;
      _templates = templates;
      _existingKeys = payrolls
          .where((r) => r.periodStart == _periodStart && r.periodEnd == _periodEnd)
          .map((r) => '${r.employeeId}|${r.periodStart}')
          .toSet();
      _loading = false;
      _warning = failures.isEmpty
          ? null
          : 'Some data failed to load (${failures.join(', ')}). You can still generate.';
    });
  }

  bool _isGenerated(StoreUser user) => _existingKeys.contains('${user.uid}|$_periodStart');

  List<StoreUser> get _visibleEmployees {
    if (_paydayFilter == 0) return _employees;
    return _employees.where((u) => u.payday == _paydayFilter).toList();
  }

  void _toggleSelect(StoreUser user) {
    if (_isGenerated(user)) return;
    setState(() {
      if (!_selected.remove(user.uid)) _selected.add(user.uid);
    });
  }

  void _selectVisible() {
    setState(() {
      for (final u in _visibleEmployees) {
        if (!_isGenerated(u)) _selected.add(u.uid);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  void _goPreview() {
    final selectedUsers = _employees.where((u) => _selected.contains(u.uid)).toList();
    if (selectedUsers.isEmpty) return;
    try {
      final records = selectedUsers
          .map((u) => buildPayrollPreview(
                user: u,
                attendance: _attendance,
                absenceForms: _absences,
                templates: _templates,
                periodStart: _periodStart,
                periodEnd: _periodEnd,
              ))
          .toList();
      setState(() {
        _previewRecords = records;
        _activeTab = 0;
        _stagePreview = true;
      });
    } catch (e) {
      debugPrint('payroll preview failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to preview payroll. Please try again.'),
          backgroundColor: BaycelColors.error,
        ),
      );
    }
  }

  void _generate() async {
    if (_generating) return;
    if (_previewRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No payslips to generate. Select employees first.'),
          backgroundColor: BaycelColors.error,
        ),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      int count = 0;
      for (final record in _previewRecords) {
        if (_existingKeys.contains('${record.employeeId}|${record.periodStart}')) continue;
        await _service.addPayroll(record);
        count++;
      }
      if (mounted) Navigator.pop(context, count);
    } catch (e) {
      debugPrint('payroll generate failed: $e');
      if (!mounted) return;
      setState(() => _generating = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('Permission denied') || msg.contains('Failed to add payroll')
                ? msg
                : 'Unable to generate payroll. Please try again.',
          ),
          backgroundColor: BaycelColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: EdgeInsets.all(BaycelSpacing.lg),
          decoration: BoxDecoration(
            color: BaycelColors.card,
            borderRadius: BorderRadius.circular(BaycelRadius.lg),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: BaycelSpacing.md),
              Flexible(child: _buildBody()),
              SizedBox(height: BaycelSpacing.md),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BaycelColors.viz6.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.playlist_play, color: BaycelColors.viz6, size: 20),
        ),
        SizedBox(width: BaycelSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _stagePreview ? 'Payroll Preview' : 'Run Payroll',
                style: BaycelTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                _periodLabel,
                style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20, color: BaycelColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.error)),
              SizedBox(height: BaycelSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _warning = null;
                    _loading = true;
                  });
                  _load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_warning != null)
          Padding(
            padding: const EdgeInsets.only(bottom: BaycelSpacing.sm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BaycelSpacing.sm),
              decoration: BoxDecoration(
                color: BaycelColors.marigoldDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BaycelRadius.sm),
              ),
              child: Text(
                _warning!,
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.warningText, fontSize: 12),
              ),
            ),
          ),
        Flexible(child: _stagePreview ? _buildPreviewStage() : _buildSelectStage()),
      ],
    );
  }

  Widget _buildSelectStage() {
    final visible = _visibleEmployees;
    final selectedVisible = visible.where((u) => _selected.contains(u.uid)).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: BaycelSpacing.sm,
          runSpacing: BaycelSpacing.sm,
          children: [
            _filterChip('All', 0),
            _filterChip('Payday 7', 7),
            _filterChip('Payday 15', 15),
          ],
        ),
        SizedBox(height: BaycelSpacing.sm),
        Row(
          children: [
            Flexible(
              child: Text(
                _selected.isEmpty
                    ? 'None selected'
                    : '${_selected.length} employee${_selected.length == 1 ? '' : 's'} selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _selectVisible,
              child: Text('Select visible', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson)),
            ),
            TextButton(
              onPressed: _clearSelection,
              child: Text('Clear', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted)),
            ),
          ],
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
            child: Center(
              child: Text(
                'No employees match this filter',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted),
              ),
            ),
          )
        else
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: BaycelColors.surface,
                borderRadius: BorderRadius.circular(BaycelRadius.sm),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: BaycelSpacing.xs),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final user = visible[index];
                  final generated = _isGenerated(user);
                  final checked = _selected.contains(user.uid);
                  return InkWell(
                    onTap: generated ? null : () => _toggleSelect(user),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xs),
                      child: Row(
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: generated ? null : (_) => _toggleSelect(user),
                            activeColor: BaycelColors.crimson,
                            side: BorderSide(color: generated ? BaycelColors.textDisabled : BaycelColors.divider),
                          ),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: BaycelColors.viz5.withValues(alpha: 0.1),
                            child: Text(
                              _initials(user.name),
                              style: BaycelTypography.labelXs.copyWith(color: BaycelColors.viz5),
                            ),
                          ),
                          SizedBox(width: BaycelSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600)),
                                Text(
                                  user.role.value.replaceAll('_', ' '),
                                  style: BaycelTypography.bodyXs.copyWith(color: BaycelColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (generated)
                            const BaycelGeneratedPill()
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: BaycelColors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(BaycelRadius.full),
                              ),
                              child: Text(
                                'Payday ${user.payday}',
                                style: BaycelTypography.labelXs.copyWith(color: BaycelColors.blue),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (visible.isNotEmpty && selectedVisible == 0 && _selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: BaycelSpacing.xs),
            child: Text(
              'Select employees to preview payroll',
              style: BaycelTypography.bodyXs.copyWith(color: BaycelColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewStage() {
    final showTabs = _previewRecords.length > 1;
    final active = _previewRecords[_activeTab];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTabs) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _previewRecords.length,
              separatorBuilder: (_, _) => const SizedBox(width: BaycelSpacing.xs),
              itemBuilder: (context, index) {
                final selected = index == _activeTab;
                final name = _previewRecords[index].employeeName;
                return ChoiceChip(
                  label: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: selected,
                  onSelected: (_) => setState(() => _activeTab = index),
                  selectedColor: BaycelColors.crimson,
                  backgroundColor: BaycelColors.card,
                  labelStyle: BaycelTypography.labelSm.copyWith(
                    color: selected ? Colors.white : BaycelColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: selected ? BaycelColors.crimson : BaycelColors.divider,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.full)),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          SizedBox(height: BaycelSpacing.sm),
        ],
        Flexible(
          child: SingleChildScrollView(
            child: _PayrollPreviewBreakdown(record: active),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_loading) return const SizedBox.shrink();
    if (_error != null) return const SizedBox.shrink();

    if (!_stagePreview) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: BaycelSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: _selected.isEmpty ? null : _goPreview,
              style: BaycelComponents.buttonPrimary.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  _selected.isEmpty ? BaycelColors.textDisabled : BaycelColors.crimson,
                ),
              ),
              child: Text('Preview (${_selected.length})', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _generating ? null : () => setState(() => _stagePreview = false),
            child: const Text('Back'),
          ),
        ),
        SizedBox(width: BaycelSpacing.sm),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.description, size: 14, color: Colors.white),
            label: Text(
              _generating ? 'Generating...' : 'Generate Payslips (${_previewRecords.length})',
              style: const TextStyle(color: Colors.white),
            ),
            style: BaycelComponents.buttonPrimary,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int value) {
    final selected = _paydayFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _paydayFilter = value),
      selectedColor: BaycelColors.crimson,
      backgroundColor: BaycelColors.card,
      labelStyle: BaycelTypography.labelSm.copyWith(
        color: selected ? Colors.white : BaycelColors.textPrimary,
      ),
      side: BorderSide(color: selected ? BaycelColors.crimson : BaycelColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.full)),
      showCheckmark: false,
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }
}

class BaycelGeneratedPill extends StatelessWidget {
  const BaycelGeneratedPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: BaycelColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BaycelRadius.full),
      ),
      child: Text('Generated', style: BaycelTypography.labelXs.copyWith(color: BaycelColors.success)),
    );
  }
}

class _PayrollPreviewBreakdown extends StatelessWidget {
  final PayrollRecord record;
  const _PayrollPreviewBreakdown({required this.record});

  @override
  Widget build(BuildContext context) {
    final leavePay = record.paidLeaveDays * record.hourlyRate * 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BaycelSpacing.sm),
          decoration: BoxDecoration(
            color: BaycelColors.surface,
            borderRadius: BorderRadius.circular(BaycelRadius.sm),
          ),
          child: Column(
            children: [
              _row('Hourly Rate', '\u20B1${_fmt(record.hourlyRate)}/hr'),
              _row('Regular Hours', '${record.totalHours} hrs'),
              _row('Overtime Hours', '${record.overtimeHours} hrs'),
              if (record.paidLeaveDays > 0)
                _row('Paid Leave', '${record.paidLeaveDays} days', color: BaycelColors.success),
              if (record.unpaidLeaveDays > 0)
                _row('Unpaid Absence', '${record.unpaidLeaveDays} days', color: BaycelColors.error),
              const Divider(color: BaycelColors.divider),
              _row('Basic Pay', '\u20B1${_fmt(record.basicPay)}', bold: true),
              _row('Overtime Pay', '\u20B1${_fmt(record.overtimePay)}'),
              if (record.paidLeaveDays > 0)
                _row('Leave Pay', '\u20B1${_fmt(leavePay)}', color: BaycelColors.success),
              if (record.unpaidLeaveDays > 0)
                _row(
                  'Absence Value',
                  '\u20B1${_fmt(record.unpaidLeaveDays * record.hourlyRate * 8)}',
                  color: BaycelColors.error,
                ),
              const Divider(color: BaycelColors.divider),
              _row('Gross Pay', '\u20B1${_fmt(record.totalGross)}', bold: true),
            ],
          ),
        ),
        SizedBox(height: BaycelSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BaycelSpacing.sm),
          decoration: BoxDecoration(
            color: BaycelColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(BaycelRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.remove_circle_outline, size: 14, color: BaycelColors.error),
                  const SizedBox(width: 6),
                  Text(
                    'Deductibles',
                    style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (record.deductions.isEmpty)
                _row('No deductibles applied', '\u20B10.00', color: BaycelColors.textMuted)
              else
                ...record.deductions.map((d) => _row(d.description, '\u20B1${_fmt(d.amount)}', color: BaycelColors.error)),
              Divider(color: BaycelColors.error.withValues(alpha: 0.3)),
              _row('Total Deductibles', '\u20B1${_fmt(record.totalDeductions)}', bold: true, color: BaycelColors.error),
            ],
          ),
        ),
        SizedBox(height: BaycelSpacing.sm),
        Container(
          padding: const EdgeInsets.all(BaycelSpacing.sm),
          decoration: BoxDecoration(
            color: BaycelColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(BaycelRadius.sm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Pay', style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w700, color: BaycelColors.success)),
              Text(
                '\u20B1${_fmt(record.netPay)}',
                style: BaycelTypography.headlineMd.copyWith(color: BaycelColors.success),
              ),
            ],
          ),
        ),
        SizedBox(height: BaycelSpacing.xs),
        Text(
          'Review figures before generating payslips.',
          style: BaycelTypography.bodyXs.copyWith(color: BaycelColors.textMuted),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: BaycelTypography.bodySm.copyWith(fontSize: 12, color: color ?? BaycelColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: BaycelTypography.dataMono.copyWith(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? BaycelColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) {
    final whole = amount.truncate();
    final fraction = ((amount - whole) * 100).round().toString().padLeft(2, '0');
    final formatted = whole.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m.group(1)},',
    );
    return '$formatted.$fraction';
  }
}

PayrollRecord buildPayrollPreview({
  required StoreUser user,
  required List<AttendanceRecord> attendance,
  required List<AbsenceForm> absenceForms,
  required List<DeductibleTemplate> templates,
  required String periodStart,
  required String periodEnd,
}) {
  final userRecords = attendance
      .where((r) =>
          r.employeeId == user.uid &&
          r.date.compareTo(periodStart) >= 0 &&
          r.date.compareTo(periodEnd) <= 0)
      .toList();

  final totalHours = userRecords.fold<double>(0, (s, r) => s + r.totalHours).toInt();
  final overtimeHours = userRecords.fold<double>(0, (s, r) => s + r.overtimeHours).toInt();
  final basicPay = totalHours * user.rate;
  final overtimePay = overtimeHours * user.rate * 1.5;

  final userAbsences = absenceForms
      .where((f) =>
          f.employeeId == user.uid &&
          f.status == AbsenceStatus.approved &&
          f.startDate.compareTo(DateTime.parse(periodEnd)) <= 0 &&
          f.endDate.compareTo(DateTime.parse(periodStart)) >= 0)
      .toList();

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
  final absenceDeduction = unpaidLeaveDays * user.rate * 8;
  final gross = basicPay + overtimePay + leavePay + absenceDeduction;

  final deductions = <PayrollDeduction>[];
  if (absenceDeduction > 0) {
    deductions.add(PayrollDeduction(
      description: 'Unpaid Absence ($unpaidLeaveDays days)',
      amount: absenceDeduction,
    ));
  }
  for (final t in templates) {
    final amount = t.type == 'percentage' ? gross * t.value / 100 : t.value;
    if (amount <= 0) continue;
    deductions.add(PayrollDeduction(
      description: t.type == 'percentage' ? '${t.name} (${_trim(t.value)}%)' : t.name,
      amount: amount,
    ));
  }

  final totalDeductions = deductions.fold<double>(0, (s, d) => s + d.amount);

  return PayrollRecord(
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
    totalGross: gross,
    deductions: deductions,
    totalDeductions: totalDeductions,
    netPay: gross - totalDeductions,
    paidLeaveDays: paidLeaveDays,
    unpaidLeaveDays: unpaidLeaveDays,
    status: 'pending',
    createdAt: DateTime.now(),
  );
}

String _trim(double value) {
  return value == value.truncateToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

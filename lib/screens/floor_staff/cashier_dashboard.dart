import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../widgets/floor_staff_shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/stock_movement.dart';
import '../../models/cash_advance.dart';
import '../../models/absence_form.dart';
import '../../models/attendance.dart';
import '../../widgets/search_scope.dart';

class CashierDashboard extends StatelessWidget {
  final FirestoreService firestore;
  final String staffName;
  final void Function(double amount, double expectedCash, double actualCash, String shift, String register, File receiptImage) onSubmitSales;
  final void Function(DateTime startDate, DateTime endDate, String reason) onSubmitAbsence;
  final Stream<List<CashAdvance>> cashAdvancesStream;
  final Stream<List<AttendanceRecord>> attendanceStream;

  const CashierDashboard({
    super.key,
    required this.firestore,
    required this.staffName,
    required this.onSubmitSales,
    required this.onSubmitAbsence,
    required this.cashAdvancesStream,
    required this.attendanceStream,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SalesCounterCard(onSubmit: onSubmitSales),
        SizedBox(height: BaycelSpacing.md),
        _RecentSubmissionsCard(firestore: firestore),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceFormCard(onSubmit: onSubmitAbsence),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceRequestsCard(firestore: firestore),
        SizedBox(height: BaycelSpacing.md),
        CashAdvanceCard(onSubmit: (amount, reason) async {
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            await firestore.addCashAdvance(CashAdvance(
              id: '',
              employeeId: uid,
              employeeName: staffName,
              amount: double.tryParse(amount) ?? 0,
              reason: reason,
              requestedAt: DateTime.now(),
            ));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cash advance request submitted')));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to submit request. Please try again.'), backgroundColor: BaycelColors.error),
              );
            }
          }
        }),
        SizedBox(height: BaycelSpacing.md),
        MyRequestsCard(requestsStream: cashAdvancesStream),
        SizedBox(height: BaycelSpacing.md),
        AttendanceCard(attendanceStream: attendanceStream),
      ],
    );
  }
}

class _AbsenceFormCard extends StatefulWidget {
  final void Function(DateTime startDate, DateTime endDate, String reason) onSubmit;

  const _AbsenceFormCard({required this.onSubmit});

  @override
  State<_AbsenceFormCard> createState() => _AbsenceFormCardState();
}

class _AbsenceFormCardState extends State<_AbsenceFormCard> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (_startDate == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select dates and enter a reason')));
      return;
    }
    widget.onSubmit(_startDate!, _endDate ?? _startDate!, reason);
    _reasonController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _startDate != null
      ? _endDate != null && !_startDate!.isAtSameMomentAs(_endDate!)
        ? '${_startDate!.month}/${_startDate!.day} \u2013 ${_endDate!.month}/${_endDate!.day}'
        : '${_startDate!.month}/${_startDate!.day}'
      : '';

    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Absence Form', style: BaycelTypography.title),
          SizedBox(height: BaycelSpacing.xxs),
          Text('Requests are reviewed by your Manager',
            style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5)),
          SizedBox(height: BaycelSpacing.md),
          buildFieldLabel('Date(s)'),
          SizedBox(height: 5),
          GestureDetector(
            onTap: _pickDates,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: BaycelColors.card,
                borderRadius: BorderRadius.circular(BaycelRadius.md),
                border: Border.all(color: BaycelColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 18, color: BaycelColors.textSecondary),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(
                    child: Text(
                      dateText.isEmpty ? 'Select date range' : dateText,
                      style: BaycelTypography.body.copyWith(
                        fontSize: 13,
                        color: dateText.isEmpty ? BaycelColors.textDisabled : BaycelColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: BaycelColors.textDisabled),
                ],
              ),
            ),
          ),
          SizedBox(height: BaycelSpacing.md),
          buildFieldLabel('Reason'),
          SizedBox(height: 5),
          TextField(
            controller: _reasonController,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: 'Brief reason for absence', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: BaycelComponents.buttonPrimary.copyWith(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical)),
              ),
              child: Text('Submit Request', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsenceRequestsCard extends StatelessWidget {
  final FirestoreService firestore;

  const _AbsenceRequestsCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AbsenceForm>>(
      stream: firestore.getAbsenceForms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final List<AbsenceForm> forms = snapshot.data ?? [];
        final query = context.searchQuery;
        var myForms = forms.where((AbsenceForm f) =>
          f.employeeId == FirebaseAuth.instance.currentUser?.uid).toList();
        if (query.isNotEmpty) {
          myForms = myForms.where((f) =>
              '${f.reason} ${f.status.value} ${f.startDate} ${f.endDate}'.toLowerCase().contains(query)).toList();
        }
        final visibleForms = myForms.take(query.isEmpty ? 5 : myForms.length).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Absence Requests', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (visibleForms.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text(
                        query.isEmpty ? 'No requests yet' : 'No absences match "$query"',
                        style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled),
                      ),
                    ],
                  ),
                ))
              else
                ...visibleForms.map((f) {
                  final statusColor = f.status == AbsenceStatus.approved
                    ? BaycelColors.success
                    : f.status == AbsenceStatus.rejected
                      ? BaycelColors.crimson
                      : BaycelColors.marigoldDark;
                  return buildAbsenceRequestRow(
                    f.reason,
                    'Submitted',
                    f.status.value[0].toUpperCase() + f.status.value.substring(1),
                    statusColor,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _SalesCounterCard extends StatefulWidget {
  final void Function(double amount, double expectedCash, double actualCash, String shift, String register, File receiptImage) onSubmit;

  const _SalesCounterCard({required this.onSubmit});

  @override
  State<_SalesCounterCard> createState() => _SalesCounterCardState();
}

class _SalesCounterCardState extends State<_SalesCounterCard> {
  final _salesController = TextEditingController();
  final _expectedCashController = TextEditingController();
  final _actualCashController = TextEditingController();
  String _shiftStart = '';
  String _shiftEnd = '';
  String _selectedRegister = 'Register 1';
  File? _receiptImage;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _salesController.dispose();
    _expectedCashController.dispose();
    _actualCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final expected = double.tryParse(_expectedCashController.text) ?? 0;
        final actual = double.tryParse(_actualCashController.text) ?? 0;
        final shortOver = expected - actual;
        final isShort = shortOver > 0;
        final isOver = shortOver < 0;
        final shortOverText = isShort
            ? 'Short: \u20B1${shortOver.toStringAsFixed(2)}'
            : isOver
                ? 'Over: \u20B1${(-shortOver).toStringAsFixed(2)}'
                : expected > 0 || actual > 0
                    ? 'Balanced'
                    : '';

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit Sales Counter', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.xxs),
              Text('Record today\'s total for your shift',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5)),
              SizedBox(height: BaycelSpacing.md),
              buildFieldLabel('Shift Time'),
              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final now = TimeOfDay.now();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _shiftStart.isNotEmpty
                            ? TimeOfDay(hour: int.parse(_shiftStart.split(':')[0]), minute: int.parse(_shiftStart.split(':')[1]))
                            : now,
                        );
                        if (picked != null) {
                          setModalState(() {
                            _shiftStart = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: BaycelColors.card,
                          borderRadius: BorderRadius.circular(BaycelRadius.md),
                          border: Border.all(color: BaycelColors.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 16, color: BaycelColors.success),
                            SizedBox(width: BaycelSpacing.xs),
                            Expanded(
                              child: Text(
                                _shiftStart.isEmpty ? 'Start' : _shiftStart,
                                style: BaycelTypography.body.copyWith(
                                  fontSize: 13,
                                  color: _shiftStart.isEmpty ? BaycelColors.textDisabled : BaycelColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm),
                    child: Text('–', style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final now = TimeOfDay.now();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _shiftEnd.isNotEmpty
                            ? TimeOfDay(hour: int.parse(_shiftEnd.split(':')[0]), minute: int.parse(_shiftEnd.split(':')[1]))
                            : now,
                        );
                        if (picked != null) {
                          final endStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          if (_shiftStart.isNotEmpty) {
                            final startParts = _shiftStart.split(':');
                            final endParts = endStr.split(':');
                            final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                            final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
                            if (endMin <= startMin) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('End time must be after start time'), backgroundColor: BaycelColors.error),
                              );
                              return;
                            }
                          }
                          setModalState(() => _shiftEnd = endStr);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: BaycelColors.card,
                          borderRadius: BorderRadius.circular(BaycelRadius.md),
                          border: Border.all(color: BaycelColors.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.stop_rounded, size: 16, color: BaycelColors.error),
                            SizedBox(width: BaycelSpacing.xs),
                            Expanded(
                              child: Text(
                                _shiftEnd.isEmpty ? 'End' : _shiftEnd,
                                style: BaycelTypography.body.copyWith(
                                  fontSize: 13,
                                  color: _shiftEnd.isEmpty ? BaycelColors.textDisabled : BaycelColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.md),
              buildFieldLabel('Register'),
              SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: _selectedRegister,
                decoration: BaycelComponents.input.copyWith(filled: true, fillColor: BaycelColors.card),
                style: BaycelTypography.body.copyWith(fontSize: 13),
                items: [
                  DropdownMenuItem(value: 'Register 1', child: Text('Register 1')),
                  DropdownMenuItem(value: 'Register 2', child: Text('Register 2')),
                  DropdownMenuItem(value: 'Register 3', child: Text('Register 3')),
                ],
                onChanged: (v) => setModalState(() => _selectedRegister = v ?? _selectedRegister),
              ),
              SizedBox(height: BaycelSpacing.md),
              buildFieldLabel('Total Sales (\u20B1)'),
              SizedBox(height: 5),
              TextField(
                controller: _salesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: BaycelTypography.dataMono.copyWith(fontSize: 13),
                decoration: BaycelComponents.input.copyWith(
                  hintText: '0.00', filled: true, fillColor: BaycelColors.card),
              ),
              SizedBox(height: BaycelSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFieldLabel('Expected Cash (\u20B1)'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _expectedCashController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: BaycelTypography.dataMono.copyWith(fontSize: 13),
                          decoration: BaycelComponents.input.copyWith(
                            hintText: '0.00', filled: true, fillColor: BaycelColors.card),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFieldLabel('Actual Cash (\u20B1)'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _actualCashController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: BaycelTypography.dataMono.copyWith(fontSize: 13),
                          decoration: BaycelComponents.input.copyWith(
                            hintText: '0.00', filled: true, fillColor: BaycelColors.card),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (shortOverText.isNotEmpty) ...[
                SizedBox(height: BaycelSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xs),
                  decoration: BoxDecoration(
                    color: isShort
                        ? BaycelColors.error.withValues(alpha: 0.1)
                        : isOver
                            ? BaycelColors.success.withValues(alpha: 0.1)
                            : BaycelColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isShort ? Icons.warning_amber_rounded : isOver ? Icons.check_circle_outline : Icons.check,
                        size: 14,
                        color: isShort ? BaycelColors.error : isOver ? BaycelColors.success : BaycelColors.blue,
                      ),
                      SizedBox(width: 6),
                      Text(shortOverText, style: BaycelTypography.labelSm.copyWith(
                        color: isShort ? BaycelColors.error : isOver ? BaycelColors.success : BaycelColors.blue,
                        fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              ],
              SizedBox(height: BaycelSpacing.md),
              buildFieldLabel('Receipt Photo *'),
              SizedBox(height: 5),
              GestureDetector(
                onTap: _pickReceiptImage,
                child: Container(
                  height: _receiptImage != null ? 200 : 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BaycelColors.surface,
                    borderRadius: BorderRadius.circular(BaycelRadius.md),
                    border: Border.all(
                      color: _receiptImage != null ? BaycelColors.success : BaycelColors.divider,
                      width: _receiptImage != null ? 2 : 1,
                    ),
                  ),
                  child: _receiptImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(BaycelRadius.md),
                            child: Image.file(_receiptImage!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setModalState(() => _receiptImage = null),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: BaycelColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BaycelColors.crimson.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt_outlined, size: 24, color: BaycelColors.crimson),
                          ),
                          SizedBox(height: BaycelSpacing.sm),
                          Text('Upload receipt photo', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12.5)),
                          SizedBox(height: BaycelSpacing.xxs),
                          Text('Required — tap to take a photo or choose from gallery', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 10)),
                        ],
                      ),
                ),
              ),
              SizedBox(height: BaycelSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_receiptImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please upload a receipt photo before submitting'), backgroundColor: BaycelColors.error),
                      );
                      return;
                    }
                    if (_shiftStart.isEmpty || _shiftEnd.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select both shift start and end times'), backgroundColor: BaycelColors.error),
                      );
                      return;
                    }
                    final amount = double.tryParse(_salesController.text) ?? 0;
                    final expectedCash = double.tryParse(_expectedCashController.text) ?? 0;
                    final actualCash = double.tryParse(_actualCashController.text) ?? 0;
                    widget.onSubmit(amount, expectedCash, actualCash, '$_shiftStart–$_shiftEnd', _selectedRegister, _receiptImage!);
                    _salesController.clear();
                    _expectedCashController.clear();
                    _actualCashController.clear();
                    setState(() {
                      _receiptImage = null;
                      _shiftStart = '';
                      _shiftEnd = '';
                    });
                  },
                  style: BaycelComponents.buttonPrimary.copyWith(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical)),
                  ),
                  child: Text('Submit Counter Record', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickReceiptImage() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (picked != null) setState(() => _receiptImage = File(picked.path));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setState(() => _receiptImage = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSubmissionsCard extends StatelessWidget {
  final FirestoreService firestore;

  const _RecentSubmissionsCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<StockMovement>>(
      stream: firestore.getStockMovementsByUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final movements = snapshot.data ?? [];
        final submissions = movements.where((m) => m.productId == 'sales').take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Submissions', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (submissions.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No submissions yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                      SizedBox(height: BaycelSpacing.xxs),
                      Text('Submit your first sales counter record above', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 10)),
                    ],
                  ),
                ))
              else
                ...submissions.map((m) {
                  final date = '${m.createdAt.month}/${m.createdAt.day}';
                  final time = '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
                  final hasShortOver = m.expectedCash != null && m.actualCash != null;
                  final shortOver = hasShortOver ? (m.expectedCash! - m.actualCash!) : 0.0;
                  return buildSubmissionRow(
                    '$date \u00b7 ${m.note ?? "Sales"}',
                    'Submitted $time',
                    '\u20B1${m.quantity}',
                    shortOver: hasShortOver ? shortOver : null,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

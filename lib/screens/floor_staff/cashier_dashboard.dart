import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../widgets/floor_staff_shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/stock_movement.dart';
import '../../models/cash_advance.dart';
import '../../models/attendance.dart';

class CashierDashboard extends StatelessWidget {
  final FirestoreService firestore;
  final String staffName;
  final void Function(double amount, double expectedCash, double actualCash, String shift, String register) onSubmitSales;
  final Stream<List<CashAdvance>> cashAdvancesStream;
  final Stream<List<AttendanceRecord>> attendanceStream;

  const CashierDashboard({
    super.key,
    required this.firestore,
    required this.staffName,
    required this.onSubmitSales,
    required this.cashAdvancesStream,
    required this.attendanceStream,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SalesCounterCard(onSubmit: onSubmitSales),
        SizedBox(height: BaycelSpacing.md),
        _RecentSubmissionsCard(firestore: firestore),
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

class _SalesCounterCard extends StatefulWidget {
  final void Function(double amount, double expectedCash, double actualCash, String shift, String register) onSubmit;

  const _SalesCounterCard({required this.onSubmit});

  @override
  State<_SalesCounterCard> createState() => _SalesCounterCardState();
}

class _SalesCounterCardState extends State<_SalesCounterCard> {
  final _salesController = TextEditingController();
  final _expectedCashController = TextEditingController();
  final _actualCashController = TextEditingController();
  String _selectedShift = 'Morning (7AM\u20133PM)';
  String _selectedRegister = 'Register 1';

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
              buildFieldLabel('Shift'),
              SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: _selectedShift,
                decoration: BaycelComponents.input.copyWith(filled: true, fillColor: BaycelColors.card),
                style: BaycelTypography.body.copyWith(fontSize: 13),
                items: [
                  DropdownMenuItem(value: 'Morning (7AM\u20133PM)', child: Text('Morning (7AM\u20133PM)')),
                  DropdownMenuItem(value: 'Afternoon (3PM\u201311PM)', child: Text('Afternoon (3PM\u201311PM)')),
                ],
                onChanged: (v) => setModalState(() => _selectedShift = v ?? _selectedShift),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_salesController.text) ?? 0;
                    final expectedCash = double.tryParse(_expectedCashController.text) ?? 0;
                    final actualCash = double.tryParse(_actualCashController.text) ?? 0;
                    widget.onSubmit(amount, expectedCash, actualCash, _selectedShift, _selectedRegister);
                    _salesController.clear();
                    _expectedCashController.clear();
                    _actualCashController.clear();
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

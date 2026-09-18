import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/product.dart';
import '../models/cash_advance.dart';
import '../models/attendance.dart';
import 'floor_staff_helpers.dart';

class ClockCard extends StatelessWidget {
  final bool isClockedIn;
  final bool isOnBreak;
  final String clockTime;
  final VoidCallback onToggleClockIn;
  final VoidCallback onToggleBreak;

  const ClockCard({
    super.key,
    required this.isClockedIn,
    required this.isOnBreak,
    required this.clockTime,
    required this.onToggleClockIn,
    required this.onToggleBreak,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BaycelColors.crimson, BaycelColors.crimsonDark],
            ),
            borderRadius: BorderRadius.circular(BaycelRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOnBreak ? Icons.coffee : Icons.access_time,
                  color: Colors.white, size: 26,
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnBreak ? 'On Break' : isClockedIn ? 'Clocked in' : 'Not clocked in',
                      style: BaycelTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      )),
                    SizedBox(height: BaycelSpacing.xxs),
                    Text(
                      isClockedIn ? clockTime : 'Tap to start your shift',
                      style: BaycelTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                      )),
                  ],
                ),
              ),
              if (!isClockedIn)
                ElevatedButton(
                  onPressed: onToggleClockIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BaycelColors.crimson,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BaycelRadius.md),
                    ),
                  ),
                  child: Text('Time In',
                    style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 12.5)),
                )
              else if (isOnBreak)
                ElevatedButton(
                  onPressed: onToggleBreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BaycelColors.crimson,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BaycelRadius.md),
                    ),
                  ),
                  child: Text('End Break',
                    style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 12.5)),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: onToggleBreak,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(BaycelRadius.md),
                        ),
                      ),
                      child: Text('Break',
                        style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12)),
                    ),
                    SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: onToggleClockIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: BaycelColors.crimson,
                        padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.md, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(BaycelRadius.md),
                        ),
                      ),
                      child: Text('Time Out',
                        style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 12.5)),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: Opacity(
            opacity: 0.08,
            child: Icon(Icons.shopping_cart, size: 80, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class CashAdvanceCard extends StatefulWidget {
  final void Function(String amount, String reason) onSubmit;

  const CashAdvanceCard({super.key, required this.onSubmit});

  @override
  State<CashAdvanceCard> createState() => _CashAdvanceCardState();
}

class _CashAdvanceCardState extends State<CashAdvanceCard> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _amountController.text;
    final reason = _reasonController.text;
    if (amount.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid amount and reason')));
      return;
    }
    widget.onSubmit(amount, reason);
    _amountController.clear();
    _reasonController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Cash Advance (Bale)', style: BaycelTypography.title),
          SizedBox(height: BaycelSpacing.xxs),
          Text('Requests are reviewed by the Owner',
            style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5)),
          SizedBox(height: BaycelSpacing.md),
          buildFieldLabel('Amount (\u20B1)'),
          SizedBox(height: 5),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: BaycelTypography.dataMono.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: '0.00', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          buildFieldLabel('Reason'),
          SizedBox(height: 5),
          TextField(
            controller: _reasonController,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: 'Why do you need the advance?', filled: true, fillColor: BaycelColors.card),
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

class MyRequestsCard extends StatelessWidget {
  final Stream<List<CashAdvance>> requestsStream;

  const MyRequestsCard({super.key, required this.requestsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CashAdvance>>(
      stream: requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final requests = snapshot.data ?? [];
        final recent = requests.take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Cash Advance Requests', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (recent.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.request_page_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No requests yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                      SizedBox(height: BaycelSpacing.xxs),
                      Text('Submit a cash advance request above', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 10)),
                    ],
                  ),
                ))
              else
                ...recent.map((r) {
                  final date = '${r.requestedAt.month}/${r.requestedAt.day}';
                  Color statusColor;
                  String statusLabel;
                  switch (r.status) {
                    case CashAdvanceStatus.approved:
                      statusColor = BaycelColors.success;
                      statusLabel = 'Approved';
                      break;
                    case CashAdvanceStatus.rejected:
                      statusColor = BaycelColors.error;
                      statusLabel = 'Rejected';
                      break;
                    case CashAdvanceStatus.pending:
                      statusColor = BaycelColors.marigold;
                      statusLabel = 'Pending';
                      break;
                  }
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
                          child: Icon(Icons.payments_outlined, color: BaycelColors.textSecondary, size: 15),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('\u20B1${r.amount.toStringAsFixed(0)} \u2014 ${r.reason}',
                                style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 1),
                              Text(r.status == CashAdvanceStatus.pending
                                  ? '$date \u00b7 Submitted'
                                  : '$date \u00b7 ${r.reviewNote ?? (r.status == CashAdvanceStatus.approved ? 'Approved' : 'Rejected')}',
                                style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(BaycelRadius.full),
                          ),
                          child: Text(statusLabel, style: BaycelTypography.labelSm.copyWith(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final Stream<List<AttendanceRecord>> attendanceStream;

  const AttendanceCard({super.key, required this.attendanceStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: attendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final List<AttendanceRecord> records = snapshot.data ?? [];
        final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final List<AttendanceRecord> myRecords = records.where((AttendanceRecord r) => r.employeeId == myUid).toList();
        final int daysPresent = myRecords.where((AttendanceRecord r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.complete).length;
        final int late = myRecords.where((AttendanceRecord r) => r.lateMinutes > 0).length;
        final double totalHrs = myRecords.fold<double>(0, (double s, AttendanceRecord r) => s + r.totalHours);

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Attendance This Week', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.md),
              Row(
                children: [
                  Expanded(child: buildStatBox('$daysPresent', 'Days Present')),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(child: buildStatBox('$late', 'Late')),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(child: buildStatBox(totalHrs.toStringAsFixed(1), 'Total Hrs')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class StockLevelsCard extends StatelessWidget {
  final Stream<List<Product>> productsStream;
  final void Function(String productName) onProductTap;

  const StockLevelsCard({
    super.key,
    required this.productsStream,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final top = products.take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock Levels', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (top.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No products', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...top.map((p) => InkWell(
                  onTap: () => onProductTap(p.name),
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 9, horizontal: BaycelSpacing.xs),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              SizedBox(height: 1),
                              Text(p.category, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                            ],
                          ),
                        ),
                        Text('${p.stockQuantity}', style: BaycelTypography.dataMono.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                        SizedBox(width: BaycelSpacing.xs),
                        Icon(Icons.chevron_right, size: 16, color: BaycelColors.textDisabled),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}

class StockOutCard extends StatefulWidget {
  final Stream<List<Product>> productsStream;
  final void Function(String productName, int quantity) onSubmit;

  const StockOutCard({
    super.key,
    required this.productsStream,
    required this.onSubmit,
  });

  @override
  State<StockOutCard> createState() => _StockOutCardState();
}

class _StockOutCardState extends State<StockOutCard> {
  String _selectedProduct = '';
  final _qtyController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0 || _selectedProduct.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select product and enter quantity')));
      return;
    }
    widget.onSubmit(_selectedProduct, qty);
    _qtyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: widget.productsStream,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];

        if (_selectedProduct.isEmpty && products.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedProduct = products.first.name);
          });
        }

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock-Out to Shelves', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.md),
              buildFieldLabel('Product'),
              SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: products.any((p) => p.name == _selectedProduct) ? _selectedProduct : null,
                decoration: BaycelComponents.input.copyWith(filled: true, fillColor: BaycelColors.card),
                style: BaycelTypography.body.copyWith(fontSize: 13),
                items: products.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _selectedProduct = v ?? ''),
              ),
              SizedBox(height: BaycelSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFieldLabel('Quantity'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          style: BaycelTypography.dataMono.copyWith(fontSize: 13),
                          decoration: BaycelComponents.input.copyWith(
                            hintText: '0', filled: true, fillColor: BaycelColors.card),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.md),
                  Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: BaycelComponents.buttonPrimary.copyWith(
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical)),
                      ),
                      child: Text('Record Transfer', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

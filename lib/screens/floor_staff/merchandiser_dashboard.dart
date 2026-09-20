import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../models/user.dart';
import '../../models/absence_form.dart';

class MerchandiserDashboard extends StatefulWidget {
  final FirestoreService firestore;
  final StoreUser? currentUser;
  final Stream<List<Product>> productsStream;
  final Stream<List<StockMovement>> stockMovementsStream;
  final void Function(String productName, int quantity) onStockOut;
  final void Function(DateTime startDate, DateTime endDate, String reason) onSubmitAbsence;

  const MerchandiserDashboard({
    super.key,
    required this.firestore,
    required this.currentUser,
    required this.productsStream,
    required this.stockMovementsStream,
    required this.onStockOut,
    required this.onSubmitAbsence,
  });

  @override
  State<MerchandiserDashboard> createState() => _MerchandiserDashboardState();
}

class _MerchandiserDashboardState extends State<MerchandiserDashboard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AssignedProductsCard(
                  currentUser: widget.currentUser,
                  productsStream: widget.productsStream,
                  onStockOut: (productName) => _showStockOutDialog(context, productName),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _StockMovementsCard(stockMovementsStream: widget.stockMovementsStream),
              ),
            ],
          ),
        ),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceFormCard(onSubmit: widget.onSubmitAbsence),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceRequestsCard(firestore: widget.firestore),
      ],
    );
  }

  void _showStockOutDialog(BuildContext context, String productName) {
    int qty = 1;
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Stock Out: $productName'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (qty > 1) {
                    qty--;
                    qtyController.text = qty.toString();
                    setDialogState(() {});
                  }
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: BaycelColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  ),
                  child: Icon(Icons.remove, size: 18, color: BaycelColors.error),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: BaycelTypography.dataMono.copyWith(fontSize: 18),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      qty = parsed;
                    }
                  },
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              GestureDetector(
                onTap: () {
                  qty++;
                  qtyController.text = qty.toString();
                  setDialogState(() {});
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: BaycelColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  ),
                  child: Icon(Icons.add, size: 18, color: BaycelColors.success),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final finalQty = int.tryParse(qtyController.text) ?? 0;
                if (finalQty > 0) {
                  widget.onStockOut(productName, finalQty);
                }
                Navigator.pop(ctx);
              },
              style: BaycelComponents.buttonPrimary,
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedProductsCard extends StatelessWidget {
  final StoreUser? currentUser;
  final Stream<List<Product>> productsStream;
  final void Function(String productName) onStockOut;

  const _AssignedProductsCard({
    required this.currentUser,
    required this.productsStream,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    final assignedIds = currentUser?.assignedProducts ?? [];

    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final products = snapshot.data ?? [];
        final assigned = assignedIds.isEmpty
          ? products.take(5).toList()
          : products.where((p) => assignedIds.contains(p.id)).toList();

        final lowStockCount = assigned.where((p) => p.reorderLevel > 0 && p.stockQuantity <= p.reorderLevel).length;

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Assigned Products', style: BaycelTypography.title),
                  if (lowStockCount > 0)
                    BaycelPill(label: '$lowStockCount low stock', color: BaycelColors.error),
                ],
              ),
              SizedBox(height: BaycelSpacing.xxs),
              Text('Stock-out only applies to products assigned to you',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5)),
              SizedBox(height: BaycelSpacing.md),
              if (assigned.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No products assigned', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...assigned.map((p) {
                  final isLow = p.reorderLevel > 0 && p.stockQuantity <= p.reorderLevel;
                  return InkWell(
                    onTap: () => onStockOut(p.name),
                    borderRadius: BorderRadius.circular(BaycelRadius.md),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 9, horizontal: BaycelSpacing.xs),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
                            child: Icon(Icons.inventory_outlined, color: BaycelColors.textSecondary, size: 15),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                SizedBox(height: 1),
                                Text('${p.stockQuantity} ${p.unit}', style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                              ],
                            ),
                          ),
                          BaycelPill(
                            label: isLow ? 'Low Stock' : 'In Stock',
                            color: isLow ? BaycelColors.error : BaycelColors.success,
                          ),
                          SizedBox(width: BaycelSpacing.sm),
                          OutlinedButton(
                            onPressed: () => onStockOut(p.name),
                            style: BaycelComponents.buttonOutlined.copyWith(
                              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                            ),
                            child: Text('Stock Out', style: BaycelTypography.label.copyWith(fontSize: 11.5)),
                          ),
                        ],
                      ),
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

class _StockMovementsCard extends StatelessWidget {
  final Stream<List<StockMovement>> stockMovementsStream;

  const _StockMovementsCard({required this.stockMovementsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockMovement>>(
      stream: stockMovementsStream,
      builder: (context, snapshot) {
        final movements = snapshot.data ?? [];
        final recent = movements.take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Stock Movements', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (recent.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No movements yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...recent.map((m) {
                  final date = '${m.createdAt.month}/${m.createdAt.day}';
                  final time = '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
                  final sign = m.type == StockMovementType.stockOut ? '\u2212' : '+';
                  return buildMovementRow(
                    '${m.productName} \u00b7 $sign${m.quantity}',
                    '$date, $time',
                  );
                }),
            ],
          ),
        );
      },
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
        final List<AbsenceForm> myForms = forms.where((AbsenceForm f) =>
          f.employeeId == FirebaseAuth.instance.currentUser?.uid).take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Absence Requests', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (myForms.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No requests yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...myForms.map((f) {
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

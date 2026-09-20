import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../widgets/floor_staff_shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../models/delivery.dart';
import '../../models/stock_movement.dart';
import '../../models/absence_form.dart';
import '../../models/cash_advance.dart';

class BodegeroDashboard extends StatefulWidget {
  final FirestoreService firestore;
  final String staffName;
  final void Function(DateTime startDate, DateTime endDate, String reason) onSubmitAbsence;
  final Stream<List<Delivery>> deliveriesStream;
  final Stream<List<StockMovement>> stockMovementsStream;
  final Stream<List<Product>> productsStream;
  final Stream<List<CashAdvance>> cashAdvancesStream;
  final void Function(String deliveryId) onConfirmDelivery;
  final void Function(String productName, int quantity) onStockOut;
  final void Function(String supplier, List<Map<String, String>> items) onCreateDelivery;

  const BodegeroDashboard({
    super.key,
    required this.firestore,
    required this.staffName,
    required this.onSubmitAbsence,
    required this.deliveriesStream,
    required this.stockMovementsStream,
    required this.productsStream,
    required this.cashAdvancesStream,
    required this.onConfirmDelivery,
    required this.onStockOut,
    required this.onCreateDelivery,
  });

  @override
  State<BodegeroDashboard> createState() => _BodegeroDashboardState();
}

class _BodegeroDashboardState extends State<BodegeroDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                child: _LowStockProductsCard(
                  productsStream: widget.productsStream,
                  onStockOut: (productName) => _showStockOutDialog(context, productName),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _RecentStockMovementsCard(stockMovementsStream: widget.stockMovementsStream),
              ),
            ],
          ),
        ),
        SizedBox(height: BaycelSpacing.md),
        _buildDeliveryManagement(),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceFormCard(onSubmit: widget.onSubmitAbsence),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceRequestsCard(firestore: widget.firestore),
        SizedBox(height: BaycelSpacing.md),
        CashAdvanceCard(onSubmit: (amount, reason) async {
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            await widget.firestore.addCashAdvance(CashAdvance(
              id: '',
              employeeId: uid,
              employeeName: widget.staffName,
              amount: double.tryParse(amount) ?? 0,
              reason: reason,
              requestedAt: DateTime.now(),
            ));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cash advance request submitted')));
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to submit request. Please try again.'), backgroundColor: BaycelColors.error),
              );
            }
          }
        }),
        SizedBox(height: BaycelSpacing.md),
        MyRequestsCard(requestsStream: widget.cashAdvancesStream),
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

  Widget _buildDeliveryManagement() {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: BaycelColors.crimson,
            unselectedLabelColor: BaycelColors.textMuted,
            indicatorColor: BaycelColors.crimson,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: BaycelTypography.label.copyWith(fontSize: 12.5),
            unselectedLabelStyle: BaycelTypography.label.copyWith(fontSize: 12.5),
            tabs: const [
              Tab(text: 'Create Delivery'),
              Tab(text: 'Verify Deliveries'),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TabBarView(
              controller: _tabController,
              children: [
                CreateDeliveryCard(
                  firestore: widget.firestore,
                  onSubmit: widget.onCreateDelivery,
                ),
                VerifyDeliveriesCard(
                  firestore: widget.firestore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockProductsCard extends StatelessWidget {
  final Stream<List<Product>> productsStream;
  final void Function(String productName) onStockOut;

  const _LowStockProductsCard({required this.productsStream, required this.onStockOut});

  @override
  Widget build(BuildContext context) {
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
        final lowStock = products.where((p) => p.reorderLevel > 0 && p.stockQuantity <= p.reorderLevel).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Product List', style: BaycelTypography.title),
                  if (lowStock.isNotEmpty)
                    BaycelPill(label: '${lowStock.length} low stock', color: BaycelColors.error),
                ],
              ),
              SizedBox(height: BaycelSpacing.xxs),
              Text('Tap to stock out any product',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5)),
              SizedBox(height: BaycelSpacing.md),
              if (lowStock.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 32, color: BaycelColors.success),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('All products are well-stocked', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...lowStock.map((p) {
                  final isOut = p.stockQuantity <= 0;
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
                            label: isOut ? 'Out of Stock' : 'Low Stock',
                            color: isOut ? BaycelColors.error : BaycelColors.marigoldDark,
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

class _RecentStockMovementsCard extends StatelessWidget {
  final Stream<List<StockMovement>> stockMovementsStream;

  const _RecentStockMovementsCard({required this.stockMovementsStream});

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
          Row(
            children: [
              Icon(Icons.event_busy_outlined, size: 18, color: BaycelColors.crimson),
              SizedBox(width: BaycelSpacing.sm),
              Text('Request Absence', style: BaycelTypography.title),
            ],
          ),
          SizedBox(height: BaycelSpacing.md),
          GestureDetector(
            onTap: _pickDates,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: BaycelColors.divider),
                borderRadius: BorderRadius.circular(BaycelRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 18, color: BaycelColors.textSecondary),
                  SizedBox(width: BaycelSpacing.sm),
                  Text(
                    dateText.isEmpty ? 'Select date range' : dateText,
                    style: dateText.isEmpty
                      ? BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)
                      : BaycelTypography.bodySm,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: BaycelSpacing.sm),
          TextField(
            controller: _reasonController,
            decoration: BaycelComponents.input.copyWith(hintText: 'Reason for absence'),
            maxLines: 2,
          ),
          SizedBox(height: BaycelSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: BaycelComponents.buttonPrimary,
              child: Text('Submit Request'),
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
        final forms = snapshot.data ?? [];
        final myForms = forms.where((f) =>
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

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
import 'delivery_scanner_screen.dart';

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
  });

  @override
  State<BodegeroDashboard> createState() => _BodegeroDashboardState();
}

class _BodegeroDashboardState extends State<BodegeroDashboard> {
  final List<Map<String, String>> _scannedItems = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BodegeroSummaryCard(firestore: widget.firestore),
        SizedBox(height: BaycelSpacing.md),
        _buildScannerSection(),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceFormCard(onSubmit: widget.onSubmitAbsence),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceRequestsCard(firestore: widget.firestore),
        SizedBox(height: BaycelSpacing.md),
        StockLevelsCard(
          productsStream: widget.productsStream,
          onProductTap: (productName) => _showStockOutDialog(context, productName),
        ),
        SizedBox(height: BaycelSpacing.md),
        _PendingDeliveryCard(firestore: widget.firestore, onConfirmDelivery: widget.onConfirmDelivery),
        SizedBox(height: BaycelSpacing.md),
        StockOutCard(productsStream: widget.productsStream, onSubmit: widget.onStockOut),
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
        SizedBox(height: BaycelSpacing.md),
        _RecentTransfersCard(stockMovementsStream: widget.stockMovementsStream),
      ],
    );
  }

  Widget _buildScannerSection() {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Actions', style: BaycelTypography.title),
              if (_scannedItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: BaycelColors.crimson.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BaycelRadius.full),
                  ),
                  child: Text('${_scannedItems.length} items', style: BaycelTypography.labelXs.copyWith(color: BaycelColors.crimson)),
                ),
            ],
          ),
          SizedBox(height: BaycelSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BodegeroActionCard(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                  onTap: _scanBarcode,
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _BodegeroActionCard(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Paper List',
                  onTap: _scanPaperList,
                ),
              ),
            ],
          ),
          if (_scannedItems.isNotEmpty) ...[
            SizedBox(height: BaycelSpacing.md),
            Container(
              padding: EdgeInsets.all(BaycelSpacing.sm),
              decoration: BoxDecoration(
                color: BaycelColors.surface,
                borderRadius: BorderRadius.circular(BaycelRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, size: 14, color: BaycelColors.textMuted),
                      SizedBox(width: BaycelSpacing.xs),
                      Text('Scanned Items (${_scannedItems.length})', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  SizedBox(height: BaycelSpacing.sm),
                  ...List.generate(_scannedItems.length, (i) => Padding(
                    padding: EdgeInsets.only(bottom: BaycelSpacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: BaycelColors.success),
                        SizedBox(width: BaycelSpacing.sm),
                        Expanded(
                          child: Text(_scannedItems[i]['name']!, style: BaycelTypography.bodySm.copyWith(fontSize: 12)),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: BaycelColors.crimson.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(BaycelRadius.full),
                          ),
                          child: Text('x${_scannedItems[i]['qty']}', style: BaycelTypography.dataMono.copyWith(fontSize: 11, color: BaycelColors.crimson)),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        GestureDetector(
                          onTap: () => setState(() => _scannedItems.removeAt(i)),
                          child: Icon(Icons.close, size: 14, color: BaycelColors.textDisabled),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scanPaperList() async {
    final result = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _scannedItems.addAll(result));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.length} items added from scan')),
        );
      }
    }
  }

  void _scanBarcode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Barcode Scanner'),
        content: Text('Point camera at product barcode to add to stock-out list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  void _showStockOutDialog(BuildContext context, String productName) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stock Out: $productName'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: BaycelComponents.input.copyWith(hintText: 'Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > 0) {
                widget.onStockOut(productName, qty);
              }
              Navigator.pop(ctx);
            },
            style: BaycelComponents.buttonPrimary,
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BodegeroActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BodegeroActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(BaycelSpacing.base),
        decoration: BoxDecoration(
          color: BaycelColors.surface,
          borderRadius: BorderRadius.circular(BaycelRadius.md),
          border: Border.all(color: BaycelColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: BaycelColors.crimson),
            SizedBox(height: BaycelSpacing.sm),
            Text(label, style: BaycelTypography.labelSm.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BodegeroSummaryCard extends StatelessWidget {
  final FirestoreService firestore;

  const _BodegeroSummaryCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Delivery>>(
      stream: firestore.getDeliveries(),
      builder: (context, deliverySnap) {
        final deliveries = deliverySnap.data ?? [];
        final pending = deliveries.where((d) =>
          d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).toList();
        final pendingName = pending.isNotEmpty ? pending.first.supplierName : '';

        return StreamBuilder<List<StockMovement>>(
          stream: firestore.getStockMovements(),
          builder: (context, movementSnap) {
            final movements = movementSnap.data ?? [];
            final today = DateTime.now();
            final todayTransfers = movements.where((m) =>
              m.createdAt.year == today.year && m.createdAt.month == today.month && m.createdAt.day == today.day).length;

            return Container(
              padding: EdgeInsets.all(BaycelSpacing.base),
              decoration: BaycelComponents.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Summary", style: BaycelTypography.title),
                  SizedBox(height: BaycelSpacing.sm),
                  if (pending.isNotEmpty)
                    buildSummaryRow(
                      Icons.local_shipping_outlined,
                      '${pending.length} delivery awaiting stock-in',
                      pendingName,
                      pillLabel: 'Pending',
                      pillColor: BaycelColors.marigoldDark,
                    ),
                  if (todayTransfers > 0)
                    buildSummaryRow(
                      Icons.swap_horiz,
                      '$todayTransfers transfer logged today',
                      '',
                    ),
                  if (pending.isEmpty && todayTransfers == 0)
                    Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 32, color: BaycelColors.textDisabled),
                          SizedBox(height: BaycelSpacing.sm),
                          Text('No pending deliveries or transfers', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                        ],
                      ),
                    )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingDeliveryCard extends StatelessWidget {
  final FirestoreService firestore;
  final void Function(String deliveryId) onConfirmDelivery;

  const _PendingDeliveryCard({required this.firestore, required this.onConfirmDelivery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Delivery>>(
      stream: firestore.getDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final deliveries = snapshot.data ?? [];
        final pending = deliveries.where((d) =>
          d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending Delivery \u2014 Receive & Stock-In', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.xxs),
              Text('${pending.length} deliveries awaiting',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5)),
              SizedBox(height: BaycelSpacing.md),
              if (pending.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No pending deliveries', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...pending.map((d) => InkWell(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Confirm Stock-In'),
                        content: Text('Mark delivery from ${d.supplierName} as received?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: BaycelComponents.buttonPrimary,
                            child: Text('Confirm', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    onConfirmDelivery(d.id);
                  },
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
                          child: Icon(Icons.inventory_2_outlined, color: BaycelColors.textSecondary, size: 15),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.supplierName, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              SizedBox(height: 1),
                              Text('${d.items.length} products', style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                            ],
                          ),
                        ),
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

class _RecentTransfersCard extends StatelessWidget {
  final Stream<List<StockMovement>> stockMovementsStream;

  const _RecentTransfersCard({required this.stockMovementsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockMovement>>(
      stream: stockMovementsStream,
      builder: (context, snapshot) {
        final movements = snapshot.data ?? [];
        final transfers = movements.where((m) => m.type == StockMovementType.stockOut).take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Transfers', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (transfers.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No transfers yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...transfers.map((m) => buildMovementRow(
                  '${m.productName} \u00b7 \u2212${m.quantity}',
                  '${m.createdAt.month}/${m.createdAt.day}',
                )),
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

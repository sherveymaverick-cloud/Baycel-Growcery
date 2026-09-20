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
  final List<Map<String, String>> _scannedItems = [];
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
        _RecentTransfersCard(stockMovementsStream: widget.stockMovementsStream),
        SizedBox(height: BaycelSpacing.md),
        _LowStockNotificationCard(
          productsStream: widget.productsStream,
          onProductTap: (productName) {},
        ),
        SizedBox(height: BaycelSpacing.md),
        _buildScannerSection(),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceFormCard(onSubmit: widget.onSubmitAbsence),
        SizedBox(height: BaycelSpacing.md),
        _AbsenceRequestsCard(firestore: widget.firestore),
        SizedBox(height: BaycelSpacing.md),
        _buildDeliveryManagement(),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BarcodeScannerSheet(
        onScanned: (code) async {
          Navigator.pop(ctx);
          final product = await widget.firestore.getProductByBarcode(code);
          if (product != null) {
            setState(() {
              final existing = _scannedItems.indexWhere((i) => i['name']!.toLowerCase() == product.name.toLowerCase());
              if (existing >= 0) {
                final currentQty = int.tryParse(_scannedItems[existing]['qty']!) ?? 0;
                _scannedItems[existing]['qty'] = (currentQty + 1).toString();
              } else {
                _scannedItems.add({'name': product.name, 'qty': '1'});
              }
            });
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} added')),
            );
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No product found for: $code'), backgroundColor: BaycelColors.marigoldDark),
            );
          }
        },
      ),
    );
  }

  Widget _buildDeliveryManagement() {
    return Container(
      decoration: BoxDecoration(
        color: BaycelColors.card,
        borderRadius: BorderRadius.circular(BaycelRadius.lg),
        border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.5)),
      ),
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
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
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

class _LowStockNotificationCard extends StatelessWidget {
  final Stream<List<Product>> productsStream;
  final void Function(String productName) onProductTap;

  const _LowStockNotificationCard({required this.productsStream, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }
        final products = snapshot.data ?? [];
        final lowStock = products.where((p) => p.reorderLevel > 0 && p.stockQuantity <= p.reorderLevel).toList();

        if (lowStock.isEmpty) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BoxDecoration(
            color: BaycelColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(BaycelRadius.lg),
            border: Border.all(color: BaycelColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: BaycelColors.error),
                  SizedBox(width: BaycelSpacing.sm),
                  Text('Low Stock Alert', style: BaycelTypography.title.copyWith(color: BaycelColors.error)),
                  Spacer(),
                  BaycelPill(label: '${lowStock.length} items', color: BaycelColors.error),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              ...lowStock.take(5).map((p) => Padding(
                padding: EdgeInsets.only(bottom: BaycelSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.name, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    Text('${p.stockQuantity}/${p.reorderLevel}', style: BaycelTypography.dataMono.copyWith(fontSize: 11, color: BaycelColors.error)),
                  ],
                ),
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

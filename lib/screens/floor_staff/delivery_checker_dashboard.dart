import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../widgets/floor_staff_shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../models/delivery.dart';
import '../../models/absence_form.dart';
import '../../models/cash_advance.dart';
import 'delivery_scanner_screen.dart';

class DeliveryCheckerDashboard extends StatefulWidget {
  final FirestoreService firestore;
  final String staffName;
  final void Function(DateTime startDate, DateTime endDate, String reason) onSubmitAbsence;
  final Stream<List<Delivery>> deliveriesStream;
  final Stream<List<Product>> productsStream;
  final Stream<List<CashAdvance>> cashAdvancesStream;
  final void Function(String supplier, List<Map<String, String>> items) onCreateDelivery;

  const DeliveryCheckerDashboard({
    super.key,
    required this.firestore,
    required this.staffName,
    required this.onSubmitAbsence,
    required this.deliveriesStream,
    required this.productsStream,
    required this.cashAdvancesStream,
    required this.onCreateDelivery,
  });

  @override
  State<DeliveryCheckerDashboard> createState() => _DeliveryCheckerDashboardState();
}

class _DeliveryCheckerDashboardState extends State<DeliveryCheckerDashboard> with SingleTickerProviderStateMixin {
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
      children: [
        _DeliveryCheckerSummaryCard(firestore: widget.firestore),
        SizedBox(height: BaycelSpacing.md),
        StockLevelsCard(
          productsStream: widget.productsStream,
          onProductTap: (productName) {},
        ),
        SizedBox(height: BaycelSpacing.md),
        Container(
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
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CreateDeliveryCard(firestore: widget.firestore, onSubmit: widget.onCreateDelivery),
                    _VerifyDeliveriesCard(firestore: widget.firestore),
                  ],
                ),
              ),
            ],
          ),
        ),
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
}

class _DeliveryCheckerSummaryCard extends StatelessWidget {
  final FirestoreService firestore;

  const _DeliveryCheckerSummaryCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Delivery>>(
      stream: firestore.getDeliveries(),
      builder: (context, snapshot) {
        final deliveries = snapshot.data ?? [];
        final pending = deliveries.where((d) =>
          d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).length;
        final received = deliveries.where((d) =>
          d.status == DeliveryStatus.delivered).length;
        final discrepancy = deliveries.where((d) =>
          d.status == DeliveryStatus.discrepancy).length;

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Summary", style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              Row(
                children: [
                  Expanded(child: buildSummaryRow(
                    Icons.local_shipping_outlined,
                    '$pending pending',
                    '',
                    pillLabel: 'Pending',
                    pillColor: BaycelColors.marigoldDark,
                  )),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(child: buildSummaryRow(
                    Icons.check_circle_outline,
                    '$received received',
                    '',
                    pillLabel: 'Received',
                    pillColor: BaycelColors.success,
                  )),
                ],
              ),
              SizedBox(height: BaycelSpacing.xs),
              Row(
                children: [
                  Expanded(child: buildSummaryRow(
                    Icons.warning_amber_outlined,
                    '$discrepancy issues',
                    '',
                    pillLabel: 'Discrepancy',
                    pillColor: BaycelColors.error,
                  )),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(child: buildSummaryRow(
                    Icons.inventory_2_outlined,
                    '${deliveries.length} total',
                    '',
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreateDeliveryCard extends StatefulWidget {
  final FirestoreService firestore;
  final void Function(String supplier, List<Map<String, String>> items) onSubmit;

  const _CreateDeliveryCard({required this.firestore, required this.onSubmit});

  @override
  State<_CreateDeliveryCard> createState() => _CreateDeliveryCardState();
}

class _CreateDeliveryCardState extends State<_CreateDeliveryCard> {
  final _supplierController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');
  final List<Map<String, String>> _items = [];

  @override
  void dispose() {
    _supplierController.dispose();
    _itemNameController.dispose();
    _itemQtyController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemNameController.text.trim();
    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    if (name.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter product name and valid quantity')));
      return;
    }
    setState(() {
      final existing = _items.indexWhere((i) => i['name']!.toLowerCase() == name.toLowerCase());
      if (existing >= 0) {
        final currentQty = int.tryParse(_items[existing]['qty']!) ?? 0;
        _items[existing]['qty'] = (currentQty + qty).toString();
      } else {
        _items.add({'name': name, 'qty': qty.toString()});
      }
    });
    _itemNameController.clear();
    _itemQtyController.text = '1';
  }

  void _decrementItem(int index) {
    setState(() {
      final currentQty = int.tryParse(_items[index]['qty']!) ?? 0;
      if (currentQty <= 1) {
        _items.removeAt(index);
      } else {
        _items[index]['qty'] = (currentQty - 1).toString();
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _editItemName(int index) {
    final controller = TextEditingController(text: _items[index]['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Product Name'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'Product name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _items[index]['name'] = newName);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final supplier = _supplierController.text.trim();
    if (supplier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter supplier name')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add at least one product')));
      return;
    }
    widget.onSubmit(supplier, List.from(_items));
    _supplierController.clear();
    setState(() => _items.clear());
  }

  Widget _buildScanChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xs + 2),
        decoration: BoxDecoration(
          color: BaycelColors.crimson.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BaycelRadius.md),
          border: Border.all(color: BaycelColors.crimson.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: BaycelColors.crimson),
            SizedBox(width: BaycelSpacing.xs),
            Text(label, style: BaycelTypography.labelXs.copyWith(color: BaycelColors.crimson, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _scanPaperList() async {
    final result = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _items.addAll(result));
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
      builder: (ctx) => _BarcodeScannerSheet(
        onScanned: (code) async {
          Navigator.pop(ctx);
          final product = await widget.firestore.getProductByBarcode(code);
          if (product != null) {
            final existing = _items.indexWhere((i) => i['name']!.toLowerCase() == product.name.toLowerCase());
            if (existing >= 0) {
              final currentQty = int.tryParse(_items[existing]['qty']!) ?? 0;
              setState(() => _items[existing]['qty'] = (currentQty + 1).toString());
            } else {
              setState(() => _items.add({'name': product.name, 'qty': '1'}));
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} added')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No product found for barcode: $code'),
                  backgroundColor: BaycelColors.marigoldDark,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create Delivery Record', style: BaycelTypography.title),
          SizedBox(height: BaycelSpacing.md),
          buildFieldLabel('Supplier'),
          SizedBox(height: 5),
          TextField(
            controller: _supplierController,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: 'e.g. Golden Grain Traders', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          buildFieldLabel('Products'),
          SizedBox(height: 5),
          Row(
            children: [
              _buildScanChip(
                icon: Icons.document_scanner_outlined,
                label: 'Scan Paper List',
                onTap: _scanPaperList,
              ),
              SizedBox(width: BaycelSpacing.sm),
              _buildScanChip(
                icon: Icons.qr_code_scanner,
                label: 'Scan Barcode',
                onTap: _scanBarcode,
              ),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          if (_items.isNotEmpty) ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 120),
              child: Container(
                padding: EdgeInsets.all(BaycelSpacing.sm),
                decoration: BoxDecoration(
                  color: BaycelColors.surface,
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist, size: 14, color: BaycelColors.textMuted),
                        SizedBox(width: BaycelSpacing.xs),
                        Text('Delivery Checklist (${_items.length} items)', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    SizedBox(height: BaycelSpacing.sm),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(bottom: BaycelSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(_items[i]['name']!, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ),
                              GestureDetector(
                                onTap: () => _editItemName(i),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: BaycelColors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                                  ),
                                  child: Icon(Icons.edit, size: 13, color: BaycelColors.blue),
                                ),
                              ),
                              SizedBox(width: BaycelSpacing.sm),
                              GestureDetector(
                                onTap: () => _decrementItem(i),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: BaycelColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                                  ),
                                  child: Icon(Icons.remove, size: 14, color: BaycelColors.error),
                                ),
                              ),
                              SizedBox(width: BaycelSpacing.sm),
                              Text('x${_items[i]['qty']}', style: BaycelTypography.dataMono.copyWith(fontSize: 11, color: BaycelColors.crimson)),
                              SizedBox(width: BaycelSpacing.sm),
                              GestureDetector(
                                onTap: () {
                                  final currentQty = int.tryParse(_items[i]['qty']!) ?? 0;
                                  setState(() => _items[i]['qty'] = (currentQty + 1).toString());
                                },
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: BaycelColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                                  ),
                                  child: Icon(Icons.add, size: 14, color: BaycelColors.success),
                                ),
                              ),
                              SizedBox(width: BaycelSpacing.sm),
                              GestureDetector(
                                onTap: () => _removeItem(i),
                                child: Icon(Icons.close, size: 14, color: BaycelColors.textDisabled),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: BaycelSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemNameController,
                  style: BaycelTypography.body.copyWith(fontSize: 13),
                  decoration: BaycelComponents.input.copyWith(
                    hintText: 'Product name', filled: true, fillColor: BaycelColors.card),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              SizedBox(width: BaycelSpacing.sm),
              GestureDetector(
                onTap: () {
                  final current = int.tryParse(_itemQtyController.text) ?? 0;
                  if (current > 1) _itemQtyController.text = (current - 1).toString();
                },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: BaycelColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  ),
                  child: Icon(Icons.remove, size: 16, color: BaycelColors.error),
                ),
              ),
              SizedBox(width: BaycelSpacing.xs),
              SizedBox(
                width: 32,
                child: TextField(
                  controller: _itemQtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: BaycelTypography.dataMono.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '1',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: BaycelSpacing.xs),
              GestureDetector(
                onTap: () {
                  final current = int.tryParse(_itemQtyController.text) ?? 0;
                  _itemQtyController.text = (current + 1).toString();
                },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: BaycelColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  ),
                  child: Icon(Icons.add, size: 16, color: BaycelColors.success),
                ),
              ),
              SizedBox(width: BaycelSpacing.sm),
              GestureDetector(
                onTap: _addItem,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: BaycelColors.crimson, borderRadius: BorderRadius.circular(BaycelRadius.md)),
                  child: Icon(Icons.save, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: BaycelComponents.buttonPrimary.copyWith(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 16, color: Colors.white),
                  SizedBox(width: BaycelSpacing.sm),
                  Text(
                    _items.isEmpty
                      ? 'Encode Delivery'
                      : 'Encode Delivery (${_items.length} items)',
                    style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScannerSheet extends StatefulWidget {
  final void Function(String code) onScanned;

  const _BarcodeScannerSheet({required this.onScanned});

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  MobileScannerController? _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: BaycelColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(BaycelRadius.lg)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: BaycelColors.divider, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Scan Product Barcode', style: BaycelTypography.title),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Expanded(
            child: _controller == null
                ? Center(child: CircularProgressIndicator(color: BaycelColors.crimson))
                : MobileScanner(
                    controller: _controller!,
                    onDetect: (capture) {
                      if (_hasScanned) return;
                      final code = capture.barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty) {
                        _hasScanned = true;
                        widget.onScanned(code);
                      }
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            child: Text(
              'Point camera at a product barcode',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyDeliveriesCard extends StatefulWidget {
  final FirestoreService firestore;

  const _VerifyDeliveriesCard({required this.firestore});

  @override
  State<_VerifyDeliveriesCard> createState() => _VerifyDeliveriesCardState();
}

class _VerifyDeliveriesCardState extends State<_VerifyDeliveriesCard> {
  final Map<String, Map<int, TextEditingController>> _receivedQtyControllers = {};
  final Map<String, TextEditingController> _discrepancyNoteControllers = {};

  @override
  void dispose() {
    for (final controllers in _receivedQtyControllers.values) {
      for (final ctrl in controllers.values) {
        ctrl.dispose();
      }
    }
    for (final ctrl in _discrepancyNoteControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _getReceivedController(String deliveryId, int itemIndex) {
    _receivedQtyControllers.putIfAbsent(deliveryId, () => {});
    _receivedQtyControllers[deliveryId]!.putIfAbsent(itemIndex, () => TextEditingController());
    return _receivedQtyControllers[deliveryId]![itemIndex]!;
  }

  bool _allItemsVerified(Delivery d) {
    if (d.items.isEmpty) return false;
    for (int i = 0; i < d.items.length; i++) {
      final ctrl = _receivedQtyControllers[d.id]?[i];
      final received = int.tryParse(ctrl?.text ?? '') ?? 0;
      if (received != d.items[i].expectedQuantity) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Delivery>>(
      stream: widget.firestore.getDeliveries(),
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
              Text('Verify Deliveries', style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (pending.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No deliveries to verify', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...pending.map((d) => _buildDeliveryVerificationItem(d)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryVerificationItem(Delivery d) {
    final allVerified = d.items.isNotEmpty && _allItemsVerified(d);
    final hasDiscrepancy = d.items.any((item) {
      final ctrl = _receivedQtyControllers[d.id]?[d.items.indexOf(item)];
      final received = int.tryParse(ctrl?.text ?? '') ?? 0;
      return received > 0 && received != item.expectedQuantity;
    });

    return Container(
      margin: EdgeInsets.only(bottom: BaycelSpacing.md),
      padding: EdgeInsets.all(BaycelSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5),
        borderRadius: BorderRadius.circular(BaycelRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
                child: Icon(Icons.local_shipping_outlined, color: BaycelColors.textSecondary, size: 15),
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
              if (allVerified)
                BaycelPill(label: 'Received', color: BaycelColors.success)
              else if (hasDiscrepancy)
                BaycelPill(label: 'Discrepancy', color: BaycelColors.error)
              else
                BaycelPill(label: 'Pending', color: BaycelColors.marigoldDark),
            ],
          ),
          if (d.items.isNotEmpty) ...[
            SizedBox(height: BaycelSpacing.sm),
            Divider(height: 1, color: BaycelColors.divider),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: d.items.length,
                itemBuilder: (context, i) {
                  final item = d.items[i];
                  final ctrl = _getReceivedController(d.id, i);
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: BaycelTypography.bodySm.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
                              SizedBox(height: 2),
                              Text('Expected: ${item.expectedQuantity}', style: BaycelTypography.labelXs.copyWith(color: BaycelColors.textMuted)),
                            ],
                          ),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            final current = int.tryParse(ctrl.text) ?? 0;
                            if (current > 0) {
                              ctrl.text = (current - 1).toString();
                            }
                          },
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: BaycelColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(BaycelRadius.sm),
                            ),
                            child: Icon(Icons.remove, size: 14, color: BaycelColors.error),
                          ),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        ListenableBuilder(
                          listenable: ctrl,
                          builder: (context, _) => Text('x${ctrl.text.isEmpty ? '0' : ctrl.text}', style: BaycelTypography.dataMono.copyWith(fontSize: 11, color: BaycelColors.crimson)),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            final current = int.tryParse(ctrl.text) ?? 0;
                            ctrl.text = (current + 1).toString();
                          },
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: BaycelColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(BaycelRadius.sm),
                            ),
                            child: Icon(Icons.add, size: 14, color: BaycelColors.success),
                          ),
                        ),
                        SizedBox(width: BaycelSpacing.sm),
                        ListenableBuilder(
                          listenable: ctrl,
                          builder: (context, _) {
                            final r = int.tryParse(ctrl.text) ?? 0;
                            final verified = r == item.expectedQuantity;
                            final discrepancy = r > 0 && !verified;
                            if (verified) return Icon(Icons.check_circle, size: 16, color: BaycelColors.success);
                            if (discrepancy) return Icon(Icons.warning, size: 16, color: BaycelColors.error);
                            return Icon(Icons.radio_button_unchecked, size: 16, color: BaycelColors.textDisabled);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: BaycelSpacing.sm),
          if (d.items.isEmpty)
            Text('No products recorded', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
          SizedBox(height: BaycelSpacing.sm),
          ListenableBuilder(
            listenable: Listenable.merge([
              for (int i = 0; i < d.items.length; i++)
                _getReceivedController(d.id, i),
            ]),
            builder: (context, _) {
              final allVerified = d.items.isNotEmpty && _allItemsVerified(d);
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: allVerified ? () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Mark as Received'),
                        content: Text('Confirm all ${d.items.length} products from ${d.supplierName} verified?'),
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
                    final updatedItems = List.generate(d.items.length, (i) {
                      final received = int.tryParse(_receivedQtyControllers[d.id]?[i]?.text ?? '') ?? 0;
                      return DeliveryItem(
                        productId: d.items[i].productId,
                        productName: d.items[i].productName,
                        expectedQuantity: d.items[i].expectedQuantity,
                        receivedQuantity: received,
                      );
                    });
                    await widget.firestore.updateDelivery(d.id, {
                      'items': updatedItems.map((item) => item.toMap()).toList(),
                      'status': 'delivered',
                      'checkedBy': FirebaseAuth.instance.currentUser?.uid,
                      'receivedAt': DateTime.now(),
                    });
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${d.supplierName} marked as received')),
                    );
                  } : null,
                  style: BaycelComponents.buttonPrimary.copyWith(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                  ),
                  child: Text('Mark Received', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 11.5)),
                ),
              ),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    _discrepancyNoteControllers.putIfAbsent(d.id, () => TextEditingController());
                    final noteCtrl = _discrepancyNoteControllers[d.id]!;
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                        builder: (ctx, setDialogState) {
                          bool damagedFlag = false;
                          return AlertDialog(
                            title: Text('Report Discrepancy'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Report issue with delivery from ${d.supplierName}?'),
                                SizedBox(height: BaycelSpacing.md),
                                TextField(
                                  controller: noteCtrl,
                                  maxLines: 3,
                                  style: BaycelTypography.body.copyWith(fontSize: 13),
                                  decoration: BaycelComponents.input.copyWith(
                                    hintText: 'Note missing/damaged items...',
                                    filled: true, fillColor: BaycelColors.card),
                                ),
                                SizedBox(height: BaycelSpacing.sm),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: damagedFlag,
                                      onChanged: (v) => setDialogState(() => damagedFlag = v ?? false),
                                      activeColor: BaycelColors.error,
                                    ),
                                    Text('Products arrived damaged', style: BaycelTypography.bodySm.copyWith(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, {'note': noteCtrl.text, 'damaged': damagedFlag}),
                                style: BaycelComponents.buttonPrimary.copyWith(
                                  backgroundColor: WidgetStatePropertyAll(BaycelColors.error),
                                ),
                                child: Text('Report', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                    if (result == null) return;
                    final noteText = (result['note'] as String).trim();
                    final damaged = result['damaged'] as bool;
                    final finalNote = noteText.isEmpty
                      ? (damaged ? 'Products arrived damaged' : 'Reported incomplete')
                      : (damaged ? '$noteText (products arrived damaged)' : noteText);
                    final updatedItems = List.generate(d.items.length, (i) {
                      final received = int.tryParse(_receivedQtyControllers[d.id]?[i]?.text ?? '') ?? 0;
                      return DeliveryItem(
                        productId: d.items[i].productId,
                        productName: d.items[i].productName,
                        expectedQuantity: d.items[i].expectedQuantity,
                        receivedQuantity: received,
                      );
                    });
                    await widget.firestore.updateDelivery(d.id, {
                      'items': updatedItems.map((item) => item.toMap()).toList(),
                      'status': 'discrepancy',
                      'checkedBy': FirebaseAuth.instance.currentUser?.uid,
                      'note': finalNote,
                    });
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${d.supplierName} reported with discrepancy')),
                    );
                  },
                  style: BaycelComponents.buttonOutlined.copyWith(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                  ),
                  child: Text('Report Discrepancy', style: BaycelTypography.label.copyWith(fontSize: 11.5)),
                ),
                ),
              ],
            );
            },
          ),
        ],
      ),
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

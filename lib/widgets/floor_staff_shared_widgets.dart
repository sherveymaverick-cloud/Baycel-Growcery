import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/cash_advance.dart';
import '../models/attendance.dart';
import '../services/firestore_service.dart';
import 'floor_staff_helpers.dart';
import '../screens/floor_staff/delivery_scanner_screen.dart';

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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    ),
                    SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: onToggleClockIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(BaycelRadius.md),
                        ),
                      ),
                      child: Text('Time Out',
                        style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12)),
                    ),
                  ],
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
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.shopping_cart, size: 80, color: Colors.white),
            ),
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
    final amountText = _amountController.text;
    final reason = _reasonController.text;
    if (amountText.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid amount and reason')));
      return;
    }
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Amount must be greater than 0')));
      return;
    }
    if (amount > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maximum cash advance is ₱10,000')));
      return;
    }
    widget.onSubmit(amountText, reason);
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
  int _qty = 1;

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
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFieldLabel('Product'),
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
                          decoration: BoxDecoration(
                            color: BaycelColors.card,
                            border: Border.all(color: BaycelColors.divider),
                            borderRadius: BorderRadius.circular(BaycelRadius.md),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedProduct.isNotEmpty && products.any((p) => p.name == _selectedProduct) ? _selectedProduct : null,
                              isExpanded: true,
                              style: BaycelTypography.body.copyWith(fontSize: 13),
                              dropdownColor: BaycelColors.card,
                              hint: Text('Select product', style: BaycelTypography.body.copyWith(fontSize: 13, color: BaycelColors.textDisabled)),
                              items: products.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                              onChanged: (v) => setState(() => _selectedProduct = v ?? ''),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFieldLabel('Qty'),
                      SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: BaycelColors.card,
                          border: Border.all(color: BaycelColors.divider),
                          borderRadius: BorderRadius.circular(BaycelRadius.md),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_qty > 1) setState(() => _qty--);
                              },
                              child: Container(
                                width: 32, height: 36,
                                decoration: BoxDecoration(
                                  color: BaycelColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(BaycelRadius.md),
                                    bottomLeft: Radius.circular(BaycelRadius.md),
                                  ),
                                ),
                                child: Icon(Icons.remove, size: 16, color: BaycelColors.error),
                              ),
                            ),
                            Container(
                              width: 40, height: 36,
                              alignment: Alignment.center,
                              child: Text('$_qty', style: BaycelTypography.dataMono.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _qty++),
                              child: Container(
                                width: 32, height: 36,
                                decoration: BoxDecoration(
                                  color: BaycelColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(BaycelRadius.md),
                                    bottomRight: Radius.circular(BaycelRadius.md),
                                  ),
                                ),
                                child: Icon(Icons.add, size: 16, color: BaycelColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedProduct.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select a product')));
                      return;
                    }
                    widget.onSubmit(_selectedProduct, _qty);
                    setState(() => _qty = 1);
                  },
                  style: BaycelComponents.buttonPrimary.copyWith(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical)),
                  ),
                  child: Text('Record Transfer', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BarcodeScannerSheet extends StatefulWidget {
  final void Function(String code) onScanned;

  const BarcodeScannerSheet({required this.onScanned});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
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

class CreateDeliveryCard extends StatefulWidget {
  final FirestoreService firestore;
  final void Function(String supplier, List<Map<String, String>> items) onSubmit;

  const CreateDeliveryCard({super.key, required this.firestore, required this.onSubmit});

  @override
  State<CreateDeliveryCard> createState() => _CreateDeliveryCardState();
}

class _CreateDeliveryCardState extends State<CreateDeliveryCard> {
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
      builder: (ctx) => BarcodeScannerSheet(
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
              showDialog(
                context: context,
                builder: (dCtx) {
                  final nameCtrl = TextEditingController();
                  final qtyCtrl = TextEditingController(text: '1');
                  return AlertDialog(
                    title: Text('Product Not Found'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Barcode "$code" has no matching product. Add manually?'),
                        SizedBox(height: BaycelSpacing.sm),
                        TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'Product name', contentPadding: EdgeInsets.all(10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.sm)))),
                        SizedBox(height: BaycelSpacing.xs),
                        TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Quantity', contentPadding: EdgeInsets.all(10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaycelRadius.sm)))),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dCtx);
                          final name = nameCtrl.text.trim();
                          final qty = qtyCtrl.text.trim();
                          if (name.isNotEmpty) {
                            final existing = _items.indexWhere((i) => i['name']!.toLowerCase() == name.toLowerCase());
                            if (existing >= 0) {
                              final currentQty = int.tryParse(_items[existing]['qty']!) ?? 0;
                              setState(() => _items[existing]['qty'] = (currentQty + (int.tryParse(qty) ?? 1)).toString());
                            } else {
                              setState(() => _items.add({'name': name, 'qty': qty}));
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added')));
                          }
                        },
                        child: Text('Add', style: TextStyle(color: BaycelColors.crimson)),
                      ),
                    ],
                  );
                },
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
          Wrap(
            spacing: BaycelSpacing.sm,
            runSpacing: BaycelSpacing.sm,
            children: [
              _buildScanChip(
                icon: Icons.document_scanner_outlined,
                label: 'Scan Paper List',
                onTap: _scanPaperList,
              ),
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

class VerifyDeliveriesCard extends StatefulWidget {
  final FirestoreService firestore;

  const VerifyDeliveriesCard({super.key, required this.firestore});

  @override
  State<VerifyDeliveriesCard> createState() => _VerifyDeliveriesCardState();
}

class _VerifyDeliveriesCardState extends State<VerifyDeliveriesCard> {
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

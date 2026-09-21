import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/floor_staff_shared_widgets.dart';
import '../services/firestore_service.dart';
import '../models/delivery.dart';
import '../models/stock_movement.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/absence_form.dart';
import 'floor_staff/cashier_dashboard.dart';
import 'floor_staff/bagger_dashboard.dart';
import 'floor_staff/bodegero_dashboard.dart';
import 'floor_staff/delivery_checker_dashboard.dart';
import 'floor_staff/merchandiser_dashboard.dart';

class FloorStaffDashboard extends StatefulWidget {
  final String role;

  const FloorStaffDashboard({super.key, this.role = 'cashier'});

  @override
  State<FloorStaffDashboard> createState() => _FloorStaffDashboardState();
}

class _FloorStaffDashboardState extends State<FloorStaffDashboard> {
  final _firestore = FirestoreService();
  String get _role => widget.role.toLowerCase();
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  String _clockTime = '';
  String _todayAttendanceId = '';
  String _staffName = 'Staff';
  String _staffRole = 'Floor Staff';
  StoreUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final user = await _firestore.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _staffName = user.name.split(' ').first;
          _staffRole = _getRoleLabel();
        });
        _restoreClockInState();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _staffRole = _getRoleLabel());
      }
    }
  }

  void _restoreClockInState() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final today = await _firestore.getTodaysAttendance(uid);
      if (today != null && today.timeOut == null && mounted) {
        final onBreak = today.timeOut2 != null && today.timeIn2 == null;
        setState(() {
          _isClockedIn = true;
          _isOnBreak = onBreak;
          _todayAttendanceId = today.id;
          _clockTime = onBreak ? 'On break since ${today.timeOut2}' : 'Since ${today.timeIn}';
        });
      }
    } catch (e) {
      debugPrint('Failed to restore clock-in state: $e');
    }
  }

  String _getRoleLabel() {
    switch (_role) {
      case 'cashier': return 'Cashier';
      case 'bagger': return 'Bagger';
      case 'bodegero': return 'Bodegero \u00b7 Stockroom';
      case 'delivery_checker': return 'Delivery Checker';
      case 'merchandiser': return 'Merchandiser';
      default: return 'Floor Staff';
    }
  }

  void _toggleClockIn() async {
    try {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      if (!_isClockedIn) {
        final ref = await _firestore.addAttendanceAndReturnId(AttendanceRecord(
          id: '',
          employeeId: uid,
          date: dateStr,
          timeIn: timeStr,
          totalHours: 0,
          status: AttendanceStatus.present,
        ));
        if (mounted) {
          setState(() {
            _isClockedIn = true;
            _todayAttendanceId = ref;
            _clockTime = 'Since $timeStr';
          });
        }
      } else {
        if (_todayAttendanceId.isNotEmpty) {
          final today = await _firestore.getTodaysAttendance(uid);
          final timeInStr = today?.timeIn ?? _clockTime.replaceFirst('Since ', '');
          final timeInParts = timeInStr.split(':');
          final timeOutParts = timeStr.split(':');
          final inMinutes = int.parse(timeInParts[0]) * 60 + int.parse(timeInParts[1]);
          final outMinutes = int.parse(timeOutParts[0]) * 60 + int.parse(timeOutParts[1]);
          final totalHours = (outMinutes - inMinutes) / 60.0;

          final updateData = <String, dynamic>{
            'timeOut': timeStr,
            'totalHours': totalHours,
            'status': 'complete',
          };
          if (_isOnBreak && today != null && (today.timeIn2 == null || today.timeIn2!.isEmpty)) {
            updateData['timeIn2'] = timeStr;
          }
          await _firestore.updateAttendance(_todayAttendanceId, updateData);
        }
        if (mounted) {
          setState(() {
            _isClockedIn = false;
            _isOnBreak = false;
            _todayAttendanceId = '';
            _clockTime = '';
          });
        }
      }
    } catch (e) {
      debugPrint('Clock in/out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clock in/out failed: $e'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _toggleBreak() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final today = await _firestore.getTodaysAttendance(uid);
      if (today == null || today.timeOut != null) return;

      if (!_isOnBreak) {
        await _firestore.updateAttendance(today.id, {'timeOut2': timeStr});
        setState(() {
          _isOnBreak = true;
          _clockTime = 'On break since $timeStr';
        });
      } else {
        await _firestore.updateAttendance(today.id, {'timeIn2': timeStr});
        setState(() {
          _isOnBreak = false;
          _clockTime = 'Since ${today.timeIn}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to toggle break. Try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _handleSalesSubmission(double amount, double expectedCash, double actualCash, String shift, String register, File receiptImage) async {
    try {
      if (amount <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a valid amount')));
        return;
      }
      final shortOver = expectedCash - actualCash;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (shortOver > 0 && expectedCash > 0) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Confirm Cash Shortage'),
            content: Text('Your count shows a shortage of \u20B1${shortOver.toStringAsFixed(2)}. This amount will be deducted from your payroll. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Confirm', style: TextStyle(color: BaycelColors.crimson)),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      await _firestore.addStockMovement(StockMovement(
        id: '',
        productId: 'sales',
        productName: 'Daily Sales - $shift - $register',
        type: StockMovementType.adjustment,
        quantity: amount.toInt(),
        balanceAfter: amount.toInt(),
        performedBy: uid,
        note: shortOver != 0 && expectedCash > 0
            ? 'Sales counter | Short/Over: \u20B1${shortOver.toStringAsFixed(2)}'
            : 'Sales counter submission',
        createdAt: DateTime.now(),
        expectedCash: expectedCash > 0 ? expectedCash : null,
        actualCash: expectedCash > 0 ? actualCash : null,
      ));

      if (shortOver != 0 && expectedCash > 0) {
        await _firestore.addStockMovement(StockMovement(
          id: '',
          productId: 'deduction',
          productName: shortOver > 0 ? 'Cash Shortage' : 'Cash Overage',
          type: StockMovementType.adjustment,
          quantity: 0,
          balanceAfter: 0,
          performedBy: uid,
          note: shortOver > 0
              ? 'Cash shortage of \u20B1${shortOver.toStringAsFixed(2)} deducted from payroll'
              : 'Cash overage of \u20B1${(-shortOver).toStringAsFixed(2)} recorded',
          createdAt: DateTime.now(),
          expectedCash: expectedCash,
          actualCash: actualCash,
        ));
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(shortOver > 0 && expectedCash > 0
            ? 'Submitted \u2014 Short: \u20B1${shortOver.toStringAsFixed(2)} (deducted from payroll)'
            : shortOver < 0 && expectedCash > 0
                ? 'Submitted \u2014 Over: \u20B1${(-shortOver).toStringAsFixed(2)}'
                : 'Sales counter submitted'),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit sales counter. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _handleAbsenceSubmission(DateTime startDate, DateTime endDate, String reason) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _firestore.addAbsenceForm(AbsenceForm(
        id: '',
        employeeId: uid,
        employeeName: _currentUser?.name ?? _staffName,
        reason: reason,
        startDate: startDate,
        endDate: endDate,
        status: AbsenceStatus.pending,
        submittedAt: DateTime.now(),
      ));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absence form submitted')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit absence form. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _handleDeliveryCreation(String supplier, List<Map<String, String>> items) async {
    try {
      final products = await _firestore.getProducts().first;
      final deliveryItems = items.map((entry) {
        final matched = products.where((p) => p.name.toLowerCase() == entry['name']!.toLowerCase()).toList();
        return DeliveryItem(
          productId: matched.isNotEmpty ? matched.first.id : '',
          productName: entry['name']!,
          expectedQuantity: int.parse(entry['qty']!),
          receivedQuantity: 0,
        );
      }).toList();
      await _firestore.addDelivery(Delivery(
        id: '',
        supplierName: supplier,
        items: deliveryItems,
        status: DeliveryStatus.pending,
        createdAt: DateTime.now(),
      ));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery record created')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create delivery record. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _handleConfirmDelivery(String deliveryId) async {
    try {
      final deliveries = await _firestore.getDeliveries().first;
      final delivery = deliveries.where((d) => d.id == deliveryId).firstOrNull;
      if (delivery == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery not found'), backgroundColor: BaycelColors.error));
        return;
      }

      for (final item in delivery.items) {
        final products = await _firestore.getProducts().first;
        final product = products.where((p) => p.id == item.productId || p.name == item.productName).firstOrNull;
        if (product != null) {
          final newQty = product.stockQuantity + item.expectedQuantity;
          await _firestore.updateProduct(product.id, {'stockQuantity': newQty});
          await _firestore.addStockMovement(StockMovement(
            id: '',
            productId: product.id,
            productName: product.name,
            type: StockMovementType.stockIn,
            quantity: item.expectedQuantity,
            balanceAfter: newQty,
            performedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
            createdAt: DateTime.now(),
          ));
        }
      }

      await _firestore.updateDelivery(deliveryId, {
        'status': 'delivered',
        'receivedBy': FirebaseAuth.instance.currentUser?.uid,
        'receivedAt': DateTime.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery confirmed and stock updated')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to confirm delivery. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _handleStockOut(String productName, int qty) async {
    try {
      if (qty <= 0 || productName.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select product and enter quantity')));
        return;
      }
      final products = await _firestore.getProducts().first;
      final product = products.where((p) => p.name == productName).firstOrNull;
      if (product == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product not found'), backgroundColor: BaycelColors.error));
        return;
      }
      final currentStock = product.stockQuantity;
      if (qty > currentStock) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient stock ($currentStock available)'), backgroundColor: BaycelColors.error));
        return;
      }
      final newBalance = currentStock - qty;

      await _firestore.updateProduct(product.id, {'stockQuantity': newBalance});
      await _firestore.addStockMovement(StockMovement(
        id: '',
        productId: product.id,
        productName: productName,
        type: StockMovementType.stockOut,
        quantity: qty,
        balanceAfter: newBalance,
        performedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        createdAt: DateTime.now(),
      ));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock-out recorded')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to record stock-out. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppBar(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: BaycelSpacing.base),
                StaggeredItem(index: 0, child: ClockCard(
                  isClockedIn: _isClockedIn,
                  isOnBreak: _isOnBreak,
                  clockTime: _clockTime,
                  onToggleClockIn: _toggleClockIn,
                  onToggleBreak: _toggleBreak,
                )),
                SizedBox(height: BaycelSpacing.md),
                ..._buildRoleContent().asMap().entries.map((e) =>
                  StaggeredItem(index: e.key + 1, child: e.value),
                ),
                SizedBox(height: BaycelSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BaycelColors.crimson, BaycelColors.crimsonDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(BaycelRadius.xl),
          bottomRight: Radius.circular(BaycelRadius.xl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(BaycelSpacing.base, BaycelSpacing.lg, BaycelSpacing.base, BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
              SizedBox(width: BaycelSpacing.sm),
              Text('Baycel Growcery', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 13)),
            ],
          ),
          SizedBox(height: BaycelSpacing.lg),
          Text('Hi, $_staffName', style: BaycelTypography.headline.copyWith(color: Colors.white, letterSpacing: -0.01)),
          SizedBox(height: BaycelSpacing.xxs),
          Text(_staffRole, style: BaycelTypography.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _buildRoleContent() {
    switch (_role) {
      case 'cashier': return [
        CashierDashboard(
          firestore: _firestore,
          staffName: _staffName,
          onSubmitSales: _handleSalesSubmission,
          onSubmitAbsence: _handleAbsenceSubmission,
          cashAdvancesStream: _firestore.getCashAdvancesByUser(FirebaseAuth.instance.currentUser?.uid ?? ''),
          attendanceStream: _firestore.getAttendance(),
        ),
      ];
      case 'bagger': return [
        BaggerDashboard(
          firestore: _firestore,
          staffName: _staffName,
          onSubmitAbsence: _handleAbsenceSubmission,
          cashAdvancesStream: _firestore.getCashAdvancesByUser(FirebaseAuth.instance.currentUser?.uid ?? ''),
          attendanceStream: _firestore.getAttendance(),
        ),
      ];
      case 'bodegero': return [
        BodegeroDashboard(
          firestore: _firestore,
          staffName: _staffName,
          onSubmitAbsence: _handleAbsenceSubmission,
          deliveriesStream: _firestore.getDeliveries(),
          stockMovementsStream: _firestore.getStockMovements(),
          productsStream: _firestore.getProducts(),
          cashAdvancesStream: _firestore.getCashAdvancesByUser(FirebaseAuth.instance.currentUser?.uid ?? ''),
          onConfirmDelivery: _handleConfirmDelivery,
          onStockOut: _handleStockOut,
          onCreateDelivery: _handleDeliveryCreation,
        ),
      ];
      case 'delivery_checker': return [
        DeliveryCheckerDashboard(
          firestore: _firestore,
          staffName: _staffName,
          onSubmitAbsence: _handleAbsenceSubmission,
          deliveriesStream: _firestore.getDeliveries(),
          productsStream: _firestore.getProducts(),
          cashAdvancesStream: _firestore.getCashAdvancesByUser(FirebaseAuth.instance.currentUser?.uid ?? ''),
          onCreateDelivery: _handleDeliveryCreation,
        ),
      ];
      case 'merchandiser': return [
        MerchandiserDashboard(
          firestore: _firestore,
          currentUser: _currentUser,
          productsStream: _firestore.getProducts(),
          stockMovementsStream: _firestore.getStockMovements(),
          onStockOut: _handleStockOut,
          onSubmitAbsence: _handleAbsenceSubmission,
        ),
      ];
      default: return [
        CashierDashboard(
          firestore: _firestore,
          staffName: _staffName,
          onSubmitSales: _handleSalesSubmission,
          onSubmitAbsence: _handleAbsenceSubmission,
          cashAdvancesStream: _firestore.getCashAdvancesByUser(FirebaseAuth.instance.currentUser?.uid ?? ''),
          attendanceStream: _firestore.getAttendance(),
        ),
      ];
    }
  }
}

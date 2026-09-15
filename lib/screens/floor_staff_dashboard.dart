import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/stock_movement.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/absence_form.dart';

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
  String _clockTime = '';
  String _staffName = 'Staff';
  String _staffRole = 'Floor Staff';
  StoreUser? _currentUser;

  // Sales counter form
  final _salesController = TextEditingController();
  String _selectedShift = 'Morning (7AM\u20133PM)';

  // Absence form
  final _absenceDateController = TextEditingController();
  final _absenceReasonController = TextEditingController();

  // Delivery checker form
  final _supplierController = TextEditingController();
  final _productsController = TextEditingController();

  // Bodegero stock-out
  String _selectedProduct = '';
  final _stockOutQtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _salesController.dispose();
    _absenceDateController.dispose();
    _absenceReasonController.dispose();
    _supplierController.dispose();
    _productsController.dispose();
    _stockOutQtyController.dispose();
    super.dispose();
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
      final latest = await _firestore.getLatestAttendance(uid);
      if (latest != null && latest.timeOut == null && mounted) {
        setState(() {
          _isClockedIn = true;
          _clockTime = 'Since ${latest.timeIn}';
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

      if (!_isClockedIn) {
        await _firestore.addAttendance(AttendanceRecord(
          id: '',
          employeeId: uid,
          date: dateStr,
          timeIn: timeStr,
          totalHours: 0,
          status: AttendanceStatus.present,
        ));
        setState(() {
          _isClockedIn = true;
          _clockTime = 'Since $timeStr';
        });
      } else {
        final latest = await _firestore.getLatestAttendance(uid);
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        if (latest != null && latest.timeOut == null && latest.date == todayStr) {
          final timeInParts = latest.timeIn.split(':');
          final timeOutParts = timeStr.split(':');
          final inMinutes = int.parse(timeInParts[0]) * 60 + int.parse(timeInParts[1]);
          final outMinutes = int.parse(timeOutParts[0]) * 60 + int.parse(timeOutParts[1]);
          final totalHours = (outMinutes - inMinutes) / 60.0;

          await _firestore.updateAttendance(latest.id, {
            'timeOut': timeStr,
            'totalHours': totalHours,
            'status': 'complete',
          });
        }
        setState(() {
          _isClockedIn = false;
          _clockTime = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to clock in/out. Check your connection and try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _submitSalesCounter() async {
    try {
      final amount = double.tryParse(_salesController.text) ?? 0;
      if (amount <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a valid amount')));
        return;
      }
      await _firestore.addStockMovement(StockMovement(
        id: '',
        productId: 'sales',
        productName: 'Daily Sales - $_selectedShift',
        type: StockMovementType.adjustment,
        quantity: amount.toInt(),
        balanceAfter: amount.toInt(),
        performedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        note: 'Sales counter submission',
        createdAt: DateTime.now(),
      ));
      _salesController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sales counter submitted')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit sales counter. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _submitAbsenceForm() async {
    try {
      final dates = _absenceDateController.text.trim();
      final reason = _absenceReasonController.text.trim();
      if (dates.isEmpty || reason.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fill in all fields')));
        return;
      }
      final now = DateTime.now();
      DateTime startDate = now;
      DateTime endDate = now.add(Duration(days: 1));

      // Parse formats: "Sep 15-16" or "Sep 15" or "2026-09-15" or "09/15"
      final months = {'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,'jul':7,'aug':8,'sep':9,'oct':10,'nov':11,'dec':12};
      final lower = dates.toLowerCase();

      if (lower.contains('-') && !lower.contains(' ')) {
        // "Sep 15-16" or "Sep15-16"
        final monthMatch = RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)').firstMatch(lower);
        final dayMatch = RegExp(r'(\d{1,2})\s*[-–]\s*(\d{1,2})').firstMatch(dates);
        if (monthMatch != null && dayMatch != null) {
          final month = months[monthMatch.group(0)] ?? now.month;
          final d1 = int.tryParse(dayMatch.group(1)!) ?? now.day;
          final d2 = int.tryParse(dayMatch.group(2)!) ?? d1;
          startDate = DateTime(now.year, month, d1);
          endDate = DateTime(now.year, month, d2);
        }
      } else if (lower.contains(' to ') || lower.contains(' - ') || lower.contains('–')) {
        // "Sep 15 to Sep 16" or "Sep 15 - Sep 16"
        final parts = RegExp(r'(\w+)\s+(\d{1,2})').allMatches(dates).toList();
        if (parts.length >= 2) {
          final m1 = months[parts[0].group(1)!.toLowerCase()] ?? now.month;
          final d1 = int.tryParse(parts[0].group(2)!) ?? now.day;
          final m2 = months[parts[1].group(1)!.toLowerCase()] ?? m1;
          final d2 = int.tryParse(parts[1].group(2)!) ?? d1;
          startDate = DateTime(now.year, m1, d1);
          endDate = DateTime(now.year, m2, d2);
        }
      } else {
        // Single date like "Sep 15" or "2026-09-15" or "09/15"
        if (lower.contains('/')) {
          final parts = dates.split('/');
          if (parts.length >= 2) {
            final month = int.tryParse(parts[0]) ?? now.month;
            final day = int.tryParse(parts[1]) ?? now.day;
            startDate = DateTime(now.year, month, day);
            endDate = startDate;
          }
        } else if (lower.contains('-')) {
          final parts = dates.split('-');
          if (parts.length >= 3) {
            final y = int.tryParse(parts[0]) ?? now.year;
            final m = int.tryParse(parts[1]) ?? now.month;
            final d = int.tryParse(parts[2]) ?? now.day;
            startDate = DateTime(y, m, d);
            endDate = startDate;
          }
        } else {
          final monthMatch = RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)').firstMatch(lower);
          final dayMatch = RegExp(r'(\d{1,2})').firstMatch(dates);
          if (monthMatch != null && dayMatch != null) {
            final month = months[monthMatch.group(0)] ?? now.month;
            final day = int.tryParse(dayMatch.group(1)!) ?? now.day;
            startDate = DateTime(now.year, month, day);
            endDate = startDate;
          }
        }
      }

      await _firestore.addAbsenceForm(AbsenceForm(
        id: '',
        employeeId: FirebaseAuth.instance.currentUser?.uid ?? '',
        employeeName: _currentUser?.name ?? _staffName,
        reason: reason,
        startDate: startDate,
        endDate: endDate,
        status: AbsenceStatus.pending,
        submittedAt: DateTime.now(),
      ));
      _absenceDateController.clear();
      _absenceReasonController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absence form submitted')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit absence form. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _submitDelivery() async {
    try {
      final supplier = _supplierController.text.trim();
      if (supplier.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter supplier name')));
        return;
      }
      await _firestore.addDelivery(Delivery(
        id: '',
        supplierName: supplier,
        items: [],
        status: DeliveryStatus.pending,
        createdAt: DateTime.now(),
      ));
      _supplierController.clear();
      _productsController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery record created')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create delivery record. Please try again.'), backgroundColor: BaycelColors.error),
        );
      }
    }
  }

  void _submitStockOut() async {
    try {
      final qty = int.tryParse(_stockOutQtyController.text) ?? 0;
      if (qty <= 0 || _selectedProduct.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select product and enter quantity')));
        return;
      }
      final products = await _firestore.getProducts().first;
      final product = products.where((p) => p.name == _selectedProduct).firstOrNull;
      final currentStock = product?.stockQuantity ?? 0;
      final newBalance = (currentStock - qty).clamp(0, currentStock);

      await _firestore.addStockMovement(StockMovement(
        id: '',
        productId: product?.id ?? '',
        productName: _selectedProduct,
        type: StockMovementType.stockOut,
        quantity: qty,
        balanceAfter: newBalance,
        performedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        createdAt: DateTime.now(),
      ));
      _stockOutQtyController.clear();
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
                StaggeredItem(index: 0, child: _buildClockCard()),
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
              Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: Icon(Icons.notifications_outlined, color: Colors.white, size: 15),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: BaycelColors.marigold, shape: BoxShape.circle,
                        border: Border.all(color: BaycelColors.crimsonDark, width: 1.5)),
                    ),
                  ),
                ],
              ),
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

  Widget _buildClockCard() {
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
                child: Icon(Icons.access_time, color: Colors.white, size: 26),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isClockedIn ? 'Clocked in' : 'Not clocked in',
                      style: BaycelTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      )),
                    SizedBox(height: BaycelSpacing.xxs),
                    Text(_isClockedIn ? _clockTime : 'Tap to start your shift',
                      style: BaycelTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                      )),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _toggleClockIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: BaycelColors.crimson,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BaycelRadius.md),
                  ),
                ),
                child: Text(_isClockedIn ? 'Time Out' : 'Time In',
                  style: BaycelTypography.label.copyWith(color: BaycelColors.crimson, fontSize: 12.5)),
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

  List<Widget> _buildRoleContent() {
    switch (_role) {
      case 'cashier': return _buildCashierContent();
      case 'bagger': return _buildBaggerContent();
      case 'bodegero': return _buildBodegeroContent();
      case 'delivery_checker': return _buildDeliveryCheckerContent();
      case 'merchandiser': return _buildMerchandiserContent();
      default: return _buildCashierContent();
    }
  }

  // ── Cashier ──────────────────────────────────────────
  List<Widget> _buildCashierContent() {
    return [
      _buildSalesCounterCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildRecentSubmissionsCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildAttendanceCard(),
    ];
  }

  Widget _buildSalesCounterCard() {
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
          _buildFieldLabel('Shift'),
          SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: _selectedShift,
            decoration: BaycelComponents.input.copyWith(filled: true, fillColor: BaycelColors.card),
            style: BaycelTypography.body.copyWith(fontSize: 13),
            items: [
              DropdownMenuItem(value: 'Morning (7AM\u20133PM)', child: Text('Morning (7AM\u20133PM)')),
              DropdownMenuItem(value: 'Afternoon (3PM\u201311PM)', child: Text('Afternoon (3PM\u201311PM)')),
            ],
            onChanged: (v) => setState(() => _selectedShift = v ?? _selectedShift),
          ),
          SizedBox(height: BaycelSpacing.md),
          _buildFieldLabel('Total Sales (\u20B1)'),
          SizedBox(height: 5),
          TextField(
            controller: _salesController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: BaycelTypography.dataMono.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: '0.00', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitSalesCounter,
              style: BaycelComponents.buttonPrimary.copyWith(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
              ),
              child: Text('Submit Counter Record', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSubmissionsCard() {
    return StreamBuilder<List<StockMovement>>(
      stream: _firestore.getStockMovements(),
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
                    ],
                  ),
                ))
              else
                ...submissions.map((m) {
                  final date = '${m.createdAt.month}/${m.createdAt.day}';
                  final time = '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
                  return _buildSubmissionRow(
                    '$date \u00b7 ${m.note ?? "Sales"}',
                    'Submitted $time',
                    '\u20B1${m.quantity}',
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmissionRow(String title, String meta, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
            child: Icon(Icons.attach_money, color: BaycelColors.textSecondary, size: 15),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ),
          ),
          Text(value, style: BaycelTypography.dataMono.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Bagger ──────────────────────────────────────────
  List<Widget> _buildBaggerContent() {
    return [
      _buildAbsenceFormCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildAbsenceRequestsCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildAttendanceCard(),
    ];
  }

  Widget _buildAbsenceFormCard() {
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
          _buildFieldLabel('Date(s)'),
          SizedBox(height: 5),
          Tooltip(
            message: 'Enter date or range, e.g. "Sep 15" or "Sep 15\u201316"',
            child: TextField(
              controller: _absenceDateController,
              style: BaycelTypography.body.copyWith(fontSize: 13),
              decoration: BaycelComponents.input.copyWith(
                hintText: 'e.g. Sep 15\u201316, 2026', filled: true, fillColor: BaycelColors.card),
            ),
          ),
          SizedBox(height: BaycelSpacing.md),
          _buildFieldLabel('Reason'),
          SizedBox(height: 5),
          TextField(
            controller: _absenceReasonController,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: 'Brief reason for absence', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAbsenceForm,
              style: BaycelComponents.buttonPrimary.copyWith(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
              ),
              child: Text('Submit Request', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceRequestsCard() {
    return StreamBuilder<List<AbsenceForm>>(
      stream: _firestore.getAbsenceForms(),
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
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
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
                  return _buildAbsenceRequestRow(
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

  Widget _buildAbsenceRequestRow(String title, String meta, String status, Color statusColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
            child: Icon(Icons.calendar_today_outlined, color: BaycelColors.textSecondary, size: 15),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ),
          ),
          _buildPill(status, statusColor),
        ],
      ),
    );
  }

  // ── Bodegero ──────────────────────────────────────────
  List<Widget> _buildBodegeroContent() {
    return [
      _buildBodegeroSummaryCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildStockLevelsCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildPendingDeliveryCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildStockOutCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildRecentTransfersCard(),
    ];
  }

  Widget _buildBodegeroSummaryCard() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
      builder: (context, deliverySnap) {
        final deliveries = deliverySnap.data ?? [];
        final pending = deliveries.where((d) =>
          d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).toList();
        final pendingName = pending.isNotEmpty ? pending.first.supplierName : '';

        return StreamBuilder<List<StockMovement>>(
          stream: _firestore.getStockMovements(),
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
                    _buildSummaryRow(
                      Icons.local_shipping_outlined,
                      '${pending.length} delivery awaiting stock-in',
                      pendingName,
                      pillLabel: 'Pending',
                      pillColor: BaycelColors.marigoldDark,
                    ),
                  if (todayTransfers > 0)
                    _buildSummaryRow(
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
                          Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
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

  Widget _buildSummaryRow(IconData icon, String title, String meta, {String? pillLabel, Color? pillColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
            child: Icon(icon, color: BaycelColors.textSecondary, size: 15),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                if (meta.isNotEmpty) ...[
                  SizedBox(height: 1),
                  Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                ],
              ],
            ),
          ),
          if (pillLabel != null && pillColor != null)
            _buildPill(pillLabel, pillColor),
        ],
      ),
    );
  }

  Widget _buildStockLevelsCard() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
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
                ...top.map((p) => Container(
                  padding: EdgeInsets.symmetric(vertical: 9),
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
                    ],
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTransfersCard() {
    return StreamBuilder<List<StockMovement>>(
      stream: _firestore.getStockMovements(),
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
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No transfers yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...transfers.map((m) => _buildMovementRow(
                  '${m.productName} \u00b7 \u2212${m.quantity}',
                  '${m.createdAt.month}/${m.createdAt.day}',
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingDeliveryCard() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
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
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No pending deliveries', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...pending.take(5).map((d) => Container(
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
                            Text('${d.items.length} SKUs', style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              if (pending.isNotEmpty) ...[
                SizedBox(height: BaycelSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Confirm Stock-In'),
                          content: Text('Mark ${pending.length} deliveries as received and stock-in complete?'),
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
                      for (final d in pending) {
                        await _firestore.updateDelivery(d.id, {
                          'status': 'delivered',
                          'receivedBy': FirebaseAuth.instance.currentUser?.uid,
                          'receivedAt': DateTime.now(),
                        });
                      }
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${pending.length} deliveries confirmed')),
                      );
                    },
                    style: BaycelComponents.buttonPrimary.copyWith(
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                    ),
                    child: Text('Confirm Stock-In', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockOutCard() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
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
              _buildFieldLabel('Product'),
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
                        _buildFieldLabel('Quantity'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _stockOutQtyController,
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
                      onPressed: _submitStockOut,
                      style: BaycelComponents.buttonPrimary.copyWith(
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
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

  // ── Delivery Checker ──────────────────────────────────
  List<Widget> _buildDeliveryCheckerContent() {
    return [
      _buildDeliveryCheckerSummaryCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildStockLevelsCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildCreateDeliveryCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildVerifyDeliveriesCard(),
    ];
  }

  Widget _buildDeliveryCheckerSummaryCard() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
      builder: (context, snapshot) {
        final deliveries = snapshot.data ?? [];
        final pending = deliveries.where((d) =>
          d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).toList();
        final pendingName = pending.isNotEmpty ? pending.first.supplierName : '';

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Summary", style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              if (pending.isNotEmpty)
                _buildSummaryRow(
                  Icons.local_shipping_outlined,
                  '${pending.length} delivery pending verification',
                  pendingName,
                  pillLabel: 'Pending',
                  pillColor: BaycelColors.marigoldDark,
                )
              else
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No pending deliveries', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateDeliveryCard() {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Delivery Record', style: BaycelTypography.title),
          SizedBox(height: BaycelSpacing.md),
          _buildFieldLabel('Supplier'),
          SizedBox(height: 5),
          TextField(
            controller: _supplierController,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: 'e.g. Golden Grain Traders', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          _buildFieldLabel('Products & Quantities'),
          SizedBox(height: 5),
          TextField(
            controller: _productsController,
            style: BaycelTypography.body.copyWith(fontSize: 13),
            decoration: BaycelComponents.input.copyWith(
              hintText: 'Add SKUs and expected quantities', filled: true, fillColor: BaycelColors.card),
          ),
          SizedBox(height: BaycelSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitDelivery,
              style: BaycelComponents.buttonPrimary.copyWith(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
              ),
              child: Text('Encode Delivery', style: BaycelTypography.label.copyWith(color: Colors.white, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyDeliveriesCard() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
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
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No deliveries to verify', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...pending.take(5).map((d) => Container(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Row(
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
                            Text('${d.items.length} SKUs', style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                          ],
                        ),
                      ),
                      _buildPill('Pending', BaycelColors.marigoldDark),
                    ],
                  ),
                )),
              if (pending.isNotEmpty) ...[
                SizedBox(height: BaycelSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final d = pending.first;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Mark as Received'),
                              content: Text('Confirm delivery from ${d.supplierName} has been received?'),
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
                          await _firestore.updateDelivery(d.id, {
                            'status': 'delivered',
                            'checkedBy': FirebaseAuth.instance.currentUser?.uid,
                            'receivedAt': DateTime.now(),
                          });
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${d.supplierName} marked as received')),
                          );
                        },
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
                          final d = pending.first;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Report Incomplete'),
                              content: Text('Report delivery from ${d.supplierName} as incomplete or with discrepancy?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: BaycelComponents.buttonPrimary.copyWith(
                                    backgroundColor: WidgetStatePropertyAll(BaycelColors.error),
                                  ),
                                  child: Text('Report', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          await _firestore.updateDelivery(d.id, {
                            'status': 'discrepancy',
                            'checkedBy': FirebaseAuth.instance.currentUser?.uid,
                            'note': 'Reported incomplete on ${DateTime.now()}',
                          });
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${d.supplierName} reported as incomplete')),
                          );
                        },
                        style: BaycelComponents.buttonOutlined.copyWith(
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                        ),
                        child: Text('Report Incomplete', style: BaycelTypography.label.copyWith(fontSize: 11.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Merchandiser ──────────────────────────────────────
  List<Widget> _buildMerchandiserContent() {
    return [
      _buildMerchandiserSummaryCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildAssignedProductsCard(),
      SizedBox(height: BaycelSpacing.md),
      _buildStockMovementsCard(),
    ];
  }

  Widget _buildMerchandiserSummaryCard() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final assignedIds = _currentUser?.assignedProducts ?? [];
        final assigned = assignedIds.isEmpty ? products.take(3).toList() : products.where((p) => assignedIds.contains(p.id)).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Summary", style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              _buildSummaryRow(
                Icons.swap_horiz,
                '${assigned.length} assigned products',
                'Tap Products to stock-out',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignedProductsCard() {
    final assignedIds = _currentUser?.assignedProducts ?? [];

    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
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

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Assigned Products', style: BaycelTypography.title),
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
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No products assigned', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...assigned.map((p) => _buildProductStockOutRow(p.name, '${p.stockQuantity} ${p.unit} on shelf')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductStockOutRow(String title, String meta) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9),
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
                Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ),
          ),
          SizedBox(width: BaycelSpacing.sm),
          OutlinedButton(
            onPressed: () {
              _selectedProduct = title;
              _showStockOutDialog(title);
            },
            style: BaycelComponents.buttonOutlined.copyWith(
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
            ),
            child: Text('Stock Out', style: BaycelTypography.label.copyWith(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  void _showStockOutDialog(String productName) {
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
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > 0) {
                _stockOutQtyController.text = qtyController.text;
                _selectedProduct = productName;
                _submitStockOut();
              }
              if (mounted) Navigator.pop(ctx);
            },
            style: BaycelComponents.buttonPrimary,
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockMovementsCard() {
    return StreamBuilder<List<StockMovement>>(
      stream: _firestore.getStockMovements(),
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
                      Icon(Icons.shopping_cart_outlined, size: 32, color: BaycelColors.textDisabled),
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
                  return _buildMovementRow(
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

  Widget _buildMovementRow(String title, String meta) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.lg)),
            child: Icon(Icons.swap_horiz, color: BaycelColors.textSecondary, size: 15),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared ──────────────────────────────────────────
  Widget _buildAttendanceCard() {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _firestore.getAttendance(),
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
                  Expanded(child: _buildStatBox('$daysPresent', 'Days Present')),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(child: _buildStatBox('$late', 'Late')),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(child: _buildStatBox(totalHrs.toStringAsFixed(1), 'Total Hrs')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.md),
      decoration: BoxDecoration(
        color: BaycelColors.card,
        borderRadius: BorderRadius.circular(BaycelRadius.lg),
        border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.5)),
        boxShadow: [BaycelShadows.shadowSm],
      ),
      child: Column(
        children: [
          Text(value, style: BaycelTypography.display.copyWith(fontSize: 17), textAlign: TextAlign.center),
          SizedBox(height: BaycelSpacing.xxs),
          Text(label, style: BaycelTypography.labelSm.copyWith(fontSize: 10, color: BaycelColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(BaycelRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 5),
          Text(label, style: BaycelTypography.labelSm.copyWith(color: color, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: BaycelTypography.labelSm.copyWith(
      fontSize: 11, fontWeight: FontWeight.w500, color: BaycelColors.textMuted, letterSpacing: 0.03));
  }
}

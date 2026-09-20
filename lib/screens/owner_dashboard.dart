import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/absence_form.dart';
import '../models/cash_advance.dart';
import '../models/stock_movement.dart';
import '../widgets/floor_staff_shared_widgets.dart';
import 'floor_staff/delivery_scanner_screen.dart';

class OwnerDashboard extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const OwnerDashboard({super.key, this.onNavigate});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> with TickerProviderStateMixin {
  final _firestore = FirestoreService();
  String _userName = 'Owner';
  bool _isProcessingAbsence = false;
  bool _isProcessingCashAdvance = false;
  final Set<String> _recentlyActionedAbsences = {};
  final Set<String> _recentlyActionedCashAdvances = {};


  final _statsKey = GlobalKey();
  final _absencesKey = GlobalKey();
  final _cashAdvanceKey = GlobalKey();
  final _chartsKey = GlobalKey();
  final _productsKey = GlobalKey();
  final _deliveriesKey = GlobalKey();
  final _deliveryMgmtKey = GlobalKey();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserName() async {
    try {
      final user = await _firestore.getCurrentUser();
      if (user != null && mounted) setState(() => _userName = user.name.split(' ').first);
    } catch (_) {}
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_greeting()}, $_userName', style: BaycelTypography.display),
          SizedBox(height: BaycelSpacing.xxs),
          Text("Here's what's happening at Baycel Growcery today.",
            style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary)),
          SizedBox(height: BaycelSpacing.lg),
          _buildScannerSection(),
          SizedBox(height: BaycelSpacing.lg),
          KeyedSubtree(key: _statsKey, child: _buildStatGrid()),
          SizedBox(height: BaycelSpacing.lg),
          KeyedSubtree(key: _absencesKey, child: _buildAbsenceForms()),
          SizedBox(height: BaycelSpacing.lg),
          KeyedSubtree(key: _cashAdvanceKey, child: _buildCashAdvanceApprovals()),
          SizedBox(height: BaycelSpacing.lg),
          KeyedSubtree(key: _chartsKey, child: _buildChartsRow()),
          SizedBox(height: BaycelSpacing.lg),
          KeyedSubtree(key: _deliveryMgmtKey, child: _buildDeliveryManagement()),
          SizedBox(height: BaycelSpacing.lg),
          _buildBottomRow(key: _productsKey, deliveriesKey: _deliveriesKey),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: BaycelTypography.headlineMd),
          SizedBox(height: BaycelSpacing.md),
          Row(
            children: [
              Expanded(
                child: _OwnerQuickActionCard(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                  onTap: () => _scanBarcode(),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _OwnerQuickActionCard(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Paper List',
                  onTap: () => _scanPaperList(),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _OwnerQuickActionCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  onTap: () => widget.onNavigate?.call(1),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _OwnerQuickActionCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Deliveries',
                  onTap: () => widget.onNavigate?.call(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _scanPaperList() async {
    final result = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryScannerScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.length} items scanned')),
      );
    }
  }

  void _scanBarcode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Barcode Scanner'),
        content: Text('Barcode scanner will open here. Point camera at barcode.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
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
                  firestore: _firestore,
                  onSubmit: (supplier, items) async {
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
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery created')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create delivery'), backgroundColor: BaycelColors.error),
                      );
                    }
                  },
                ),
                VerifyDeliveriesCard(firestore: _firestore),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, productSnap) {
        final products = productSnap.data ?? [];
        final totalStock = products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
        final lowStock = products.where((p) => p.stockQuantity <= p.reorderLevel && p.stockQuantity > 0).length;

        return StreamBuilder<List<Delivery>>(
          stream: _firestore.getDeliveries(),
          builder: (context, deliverySnap) {
            final deliveries = deliverySnap.data ?? [];
            final today = DateTime.now();
            final todayOrders = deliveries.where((d) =>
              d.createdAt.year == today.year && d.createdAt.month == today.month && d.createdAt.day == today.day).length;

            return StreamBuilder<List<StoreUser>>(
              stream: _firestore.getUsers(),
              builder: (context, userSnap) {
                final users = userSnap.data ?? [];
                final employees = users.where((u) => u.role != UserRole.owner).toList();
                final totalEmployees = employees.length;

                return StreamBuilder<List<AttendanceRecord>>(
                  stream: _firestore.getAttendance(),
                  builder: (context, attSnap) {
                    final records = attSnap.data ?? [];
                    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                    final present = records.where((r) => r.date == todayStr && r.timeOut == null).length;
                    final onLeave = (totalEmployees - present).clamp(0, totalEmployees);

                    return StreamBuilder<List<StockMovement>>(
                      stream: _firestore.getStockMovements(),
                      builder: (context, movSnap) {
                        final movements = movSnap.data ?? [];
                        final todaySales = movements.where((m) =>
                          m.productId == 'sales' &&
                          m.createdAt.year == today.year &&
                          m.createdAt.month == today.month &&
                          m.createdAt.day == today.day);
                        final todayRevenue = todaySales.fold<double>(0, (s, m) => s + m.quantity);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final crossCount = constraints.maxWidth > 900 ? 4 : 2;
                            final statCards = [
                              BaycelStatCard(
                                iconColor: BaycelColors.crimson,
                                icon: Icons.attach_money_rounded,
                                value: todayRevenue > 0 ? '\u20B1${todayRevenue.toStringAsFixed(0)}' : '\u20B10',
                                title: "Today's Revenue",
                                subtitle: todayRevenue > 0 ? 'Sales today' : 'No sales yet today',
                                subtitleColor: todayRevenue > 0 ? BaycelColors.success : BaycelColors.textMuted,
                              ),
                              BaycelStatCard(
                                iconColor: BaycelColors.marigoldDark,
                                icon: Icons.shopping_cart_rounded,
                                value: '$todayOrders',
                                title: 'Orders Today',
                                subtitle: 'Deliveries logged',
                                subtitleColor: BaycelColors.textMuted,
                              ),
                              BaycelStatCard(
                                iconColor: BaycelColors.viz4,
                                icon: Icons.inventory_2_rounded,
                                value: '$totalStock',
                                title: 'Products in Stock',
                                subtitle: '$lowStock low-stock alerts',
                                subtitleColor: lowStock > 0 ? BaycelColors.crimson : BaycelColors.textMuted,
                              ),
                              BaycelStatCard(
                                iconColor: BaycelColors.viz5,
                                icon: Icons.people_rounded,
                                value: '$present/$totalEmployees',
                                title: 'Employees Present',
                                subtitle: '$onLeave on leave',
                                subtitleColor: BaycelColors.textMuted,
                              ),
                            ];
                            return GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: crossCount,
                              crossAxisSpacing: BaycelSpacing.md,
                              mainAxisSpacing: BaycelSpacing.md,
                              childAspectRatio: crossCount == 1 ? 1.8 : 2.0,
                              physics: const NeverScrollableScrollPhysics(),
                              children: statCards.asMap().entries.map((e) =>
                                StaggeredItem(index: e.key, child: e.value),
                              ).toList(),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAbsenceForms() {
    return StreamBuilder<List<AbsenceForm>>(
      stream: _firestore.getAbsenceForms(),
      builder: (context, snapshot) {
        final forms = snapshot.data ?? [];
        final pending = forms.where((f) => f.status == AbsenceStatus.pending).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Absence Requests', style: BaycelTypography.headlineMd),
                      if (pending.isNotEmpty) ...[
                        SizedBox(width: BaycelSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs),
                          decoration: BoxDecoration(color: BaycelColors.marigoldDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(BaycelRadius.full)),
                          child: Text('${pending.length} pending', style: BaycelTypography.labelXs.copyWith(color: BaycelColors.marigoldDark)),
                        ),
                      ],
                    ],
                  ),
                  if (pending.length > 1)
                    SizedBox(
                      height: 30,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessingAbsence ? null : () => _bulkApproveAbsences(pending),
                        icon: _isProcessingAbsence
                          ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                          : Icon(Icons.done_all, size: 14, color: Colors.white),
                        label: Text('Approve All', style: BaycelTypography.labelSm.copyWith(color: Colors.white, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BaycelColors.success,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.md)),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              if (forms.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No absence requests', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                      SizedBox(height: BaycelSpacing.xxs),
                      Text('Requests from employees will appear here', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 10)),
                    ],
                  ),
                ))
              else
                ...forms.take(5).map((f) => _buildAbsenceFormRow(f)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAbsenceFormRow(AbsenceForm form) {
    final statusColor = form.status == AbsenceStatus.approved
      ? BaycelColors.success
      : form.status == AbsenceStatus.rejected
        ? BaycelColors.error
        : BaycelColors.marigoldDark;
    final statusLabel = form.status.value[0].toUpperCase() + form.status.value.substring(1);
    final dateRange = '${form.startDate.month}/${form.startDate.day} - ${form.endDate.month}/${form.endDate.day}';
    final isRecentlyActioned = _recentlyActionedAbsences.contains(form.id);

    if (isRecentlyActioned) {
      return Container(
        margin: EdgeInsets.only(bottom: BaycelSpacing.sm),
        padding: EdgeInsets.symmetric(vertical: 9, horizontal: BaycelSpacing.sm),
        decoration: BoxDecoration(
          color: (form.status == AbsenceStatus.approved ? BaycelColors.success : BaycelColors.error).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BaycelRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              form.status == AbsenceStatus.approved ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: form.status == AbsenceStatus.approved ? BaycelColors.success : BaycelColors.error,
            ),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(
              child: Text(
                '${form.employeeName} — ${form.status == AbsenceStatus.approved ? 'Approved' : 'Rejected'}',
                style: BaycelTypography.bodySm.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: form.status == AbsenceStatus.approved ? BaycelColors.success : BaycelColors.error,
                ),
              ),
            ),
            if (form.status == AbsenceStatus.rejected && form.rejectionComment != null && form.rejectionComment!.isNotEmpty)
              Icon(Icons.comment_outlined, size: 14, color: BaycelColors.error),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: BaycelSpacing.sm),
          padding: EdgeInsets.all(BaycelSpacing.md),
          decoration: BoxDecoration(
            color: BaycelColors.card,
            border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5),
            borderRadius: BorderRadius.circular(BaycelRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline, color: statusColor, size: 18),
                  ),
                  SizedBox(width: BaycelSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(form.employeeName, style: BaycelTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(BaycelRadius.full),
                          ),
                          child: Text(statusLabel, style: BaycelTypography.labelXs.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(BaycelSpacing.sm),
                decoration: BoxDecoration(
                  color: BaycelColors.surface,
                  borderRadius: BorderRadius.circular(BaycelRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: BaycelColors.textMuted),
                    SizedBox(width: BaycelSpacing.xs),
                    Text(dateRange, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              if (form.status == AbsenceStatus.pending) ...[
                SizedBox(height: BaycelSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAbsenceDetailDialog(form),
                    icon: Icon(Icons.visibility_outlined, size: 14, color: BaycelColors.crimson),
                    label: Text('View Details', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: BaycelColors.crimson.withValues(alpha: 0.3)),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAbsenceDetailDialog(AbsenceForm form) {
    final commentController = TextEditingController();
    bool isProcessing = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(BaycelSpacing.md),
            padding: EdgeInsets.all(BaycelSpacing.lg),
            decoration: BoxDecoration(
              color: BaycelColors.card,
              borderRadius: BorderRadius.circular(BaycelRadius.lg),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: BaycelColors.marigoldDark.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_outline, color: BaycelColors.marigoldDark, size: 20),
                      ),
                      SizedBox(width: BaycelSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(form.employeeName, style: BaycelTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('${form.startDate.month}/${form.startDate.day} - ${form.endDate.month}/${form.endDate.day}', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, size: 20, color: BaycelColors.textMuted),
                      ),
                    ],
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(BaycelSpacing.sm),
                    decoration: BoxDecoration(
                      color: BaycelColors.surface,
                      borderRadius: BorderRadius.circular(BaycelRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes, size: 13, color: BaycelColors.textMuted),
                            SizedBox(width: BaycelSpacing.xs),
                            Text('Reason', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        SizedBox(height: BaycelSpacing.xs),
                        Text(form.reason, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, color: BaycelColors.textSecondary)),
                      ],
                    ),
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Text('Rejection Comment (optional)', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                  SizedBox(height: BaycelSpacing.xs),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    style: BaycelTypography.bodySm.copyWith(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'State the reason for rejection...',
                      hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12),
                      contentPadding: EdgeInsets.all(BaycelSpacing.sm),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BaycelRadius.sm),
                        borderSide: BorderSide(color: BaycelColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BaycelRadius.sm),
                        borderSide: BorderSide(color: BaycelColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BaycelRadius.sm),
                        borderSide: BorderSide(color: BaycelColors.crimson),
                      ),
                    ),
                  ),
                  SizedBox(height: BaycelSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : () async {
                            setDialogState(() => isProcessing = true);
                            final comment = commentController.text.trim();
                            try {
                              await _firestore.updateAbsenceFormStatus(form.id, 'rejected', rejectionComment: comment);
                              _recentlyActionedAbsences.add(form.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absence rejected')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update'), backgroundColor: BaycelColors.error));
                            }
                            if (mounted) Navigator.pop(ctx);
                          },
                          icon: Icon(Icons.close, size: 14, color: BaycelColors.error),
                          label: Text('Reject', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: BaycelColors.error.withValues(alpha: 0.3)),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : () async {
                            setDialogState(() => isProcessing = true);
                            try {
                              await _firestore.updateAbsenceFormStatus(form.id, 'approved');
                              _recentlyActionedAbsences.add(form.id);
                              DateTime current = form.startDate;
                              while (!current.isAfter(form.endDate)) {
                                final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
                                await _firestore.addAttendance(AttendanceRecord(
                                  id: '', employeeId: form.employeeId, date: dateStr, timeIn: '', totalHours: 0, status: AttendanceStatus.onLeave,
                                ));
                                current = current.add(Duration(days: 1));
                              }
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absence approved')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update'), backgroundColor: BaycelColors.error));
                            }
                            if (mounted) Navigator.pop(ctx);
                          },
                          icon: Icon(Icons.check, size: 14, color: Colors.white),
                          label: Text('Approve', style: BaycelTypography.labelSm.copyWith(color: Colors.white, fontSize: 11)),
                          style: BaycelComponents.buttonPrimary.copyWith(
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _bulkApproveAbsences(List<AbsenceForm> pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve All Absences'),
        content: Text('Approve ${pending.length} absence request${pending.length > 1 ? 's' : ''}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Approve All', style: TextStyle(color: BaycelColors.success)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessingAbsence = true);
    try {
      for (final form in pending) {
        await _firestore.updateAbsenceFormStatus(form.id, 'approved');
        _recentlyActionedAbsences.add(form.id);
        DateTime current = form.startDate;
        while (!current.isAfter(form.endDate)) {
          final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
          await _firestore.addAttendance(AttendanceRecord(
            id: '',
            employeeId: form.employeeId,
            date: dateStr,
            timeIn: '',
            totalHours: 0,
            status: AttendanceStatus.onLeave,
          ));
          current = current.add(Duration(days: 1));
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pending.length} absence${pending.length > 1 ? 's' : ''} approved')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve some requests'), backgroundColor: BaycelColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessingAbsence = false);
    }
  }

  Widget _buildCashAdvanceApprovals() {
    return StreamBuilder<List<CashAdvance>>(
      stream: _firestore.getCashAdvances(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(BaycelSpacing.base),
            decoration: BaycelComponents.card,
            child: const SkeletonListTile(),
          );
        }
        final requests = snapshot.data ?? [];
        final pending = requests.where((r) => r.status == CashAdvanceStatus.pending).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Cash Advance Requests', style: BaycelTypography.headlineMd),
                      if (pending.isNotEmpty) ...[
                        SizedBox(width: BaycelSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs),
                          decoration: BoxDecoration(color: BaycelColors.marigoldDark.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(BaycelRadius.full)),
                          child: Text('${pending.length} pending', style: BaycelTypography.labelXs.copyWith(color: BaycelColors.marigoldDark)),
                        ),
                      ],
                    ],
                  ),
                  if (pending.length > 1)
                    SizedBox(
                      height: 30,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessingCashAdvance ? null : () => _bulkApproveCashAdvances(pending),
                        icon: _isProcessingCashAdvance
                          ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                          : Icon(Icons.done_all, size: 14, color: Colors.white),
                        label: Text('Approve All', style: BaycelTypography.labelSm.copyWith(color: Colors.white, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BaycelColors.success,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.md)),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              if (requests.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: BaycelSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No cash advance requests', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                      SizedBox(height: BaycelSpacing.xxs),
                      Text('Employee requests will appear here', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 10)),
                    ],
                  ),
                ))
              else
                ...requests.take(5).map((r) => _buildCashAdvanceRow(r)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashAdvanceRow(CashAdvance advance) {
    final statusColor = advance.status == CashAdvanceStatus.approved
      ? BaycelColors.success
      : advance.status == CashAdvanceStatus.rejected
        ? BaycelColors.error
        : BaycelColors.marigoldDark;
    final statusLabel = advance.status.value[0].toUpperCase() + advance.status.value.substring(1);
    final date = '${advance.requestedAt.month}/${advance.requestedAt.day}';
    final isRecentlyActioned = _recentlyActionedCashAdvances.contains(advance.id);

    if (isRecentlyActioned) {
      return Container(
        margin: EdgeInsets.only(bottom: BaycelSpacing.sm),
        padding: EdgeInsets.symmetric(vertical: 9, horizontal: BaycelSpacing.sm),
        decoration: BoxDecoration(
          color: (advance.status == CashAdvanceStatus.approved ? BaycelColors.success : BaycelColors.error).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BaycelRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              advance.status == CashAdvanceStatus.approved ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: advance.status == CashAdvanceStatus.approved ? BaycelColors.success : BaycelColors.error,
            ),
            SizedBox(width: BaycelSpacing.sm),
            Expanded(
              child: Text(
                '${advance.employeeName} — ${advance.status == CashAdvanceStatus.approved ? 'Approved' : 'Rejected'} \u20B1${advance.amount.toStringAsFixed(0)}',
                style: BaycelTypography.bodySm.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: advance.status == CashAdvanceStatus.approved ? BaycelColors.success : BaycelColors.error,
                ),
              ),
            ),
            if (advance.status == CashAdvanceStatus.rejected && advance.reviewNote != null && advance.reviewNote!.isNotEmpty)
              Icon(Icons.comment_outlined, size: 14, color: BaycelColors.error),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: BaycelSpacing.sm),
      padding: EdgeInsets.all(BaycelSpacing.md),
      decoration: BoxDecoration(
        color: BaycelColors.card,
        border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.6), width: 0.5),
        borderRadius: BorderRadius.circular(BaycelRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payments_outlined, color: statusColor, size: 18),
              ),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(advance.employeeName, style: BaycelTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BaycelRadius.full),
                      ),
                      child: Text(statusLabel, style: BaycelTypography.labelXs.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Text('\u20B1${advance.amount.toStringAsFixed(0)}', style: BaycelTypography.title.copyWith(fontSize: 16, color: BaycelColors.crimson)),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(BaycelSpacing.sm),
            decoration: BoxDecoration(
              color: BaycelColors.surface,
              borderRadius: BorderRadius.circular(BaycelRadius.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: BaycelColors.textMuted),
                SizedBox(width: BaycelSpacing.xs),
                Text(date, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (advance.status == CashAdvanceStatus.pending) ...[
            SizedBox(height: BaycelSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCashAdvanceDetailDialog(advance),
                icon: Icon(Icons.visibility_outlined, size: 14, color: BaycelColors.crimson),
                label: Text('View Details', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: BaycelColors.crimson.withValues(alpha: 0.3)),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCashAdvanceDetailDialog(CashAdvance advance) {
    final commentController = TextEditingController();
    bool isProcessing = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(BaycelSpacing.md),
            padding: EdgeInsets.all(BaycelSpacing.lg),
            decoration: BoxDecoration(
              color: BaycelColors.card,
              borderRadius: BorderRadius.circular(BaycelRadius.lg),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: BaycelColors.crimson.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.payments_outlined, color: BaycelColors.crimson, size: 20),
                      ),
                      SizedBox(width: BaycelSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(advance.employeeName, style: BaycelTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('${advance.requestedAt.month}/${advance.requestedAt.day}', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('\u20B1${advance.amount.toStringAsFixed(0)}', style: BaycelTypography.title.copyWith(fontSize: 18, color: BaycelColors.crimson)),
                      SizedBox(width: BaycelSpacing.xs),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, size: 20, color: BaycelColors.textMuted),
                      ),
                    ],
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(BaycelSpacing.sm),
                    decoration: BoxDecoration(
                      color: BaycelColors.surface,
                      borderRadius: BorderRadius.circular(BaycelRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes, size: 13, color: BaycelColors.textMuted),
                            SizedBox(width: BaycelSpacing.xs),
                            Text('Reason', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        SizedBox(height: BaycelSpacing.xs),
                        Text(advance.reason, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5, color: BaycelColors.textSecondary)),
                      ],
                    ),
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Text('Rejection Comment (optional)', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                  SizedBox(height: BaycelSpacing.xs),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    style: BaycelTypography.bodySm.copyWith(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'State the reason for rejection...',
                      hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 12),
                      contentPadding: EdgeInsets.all(BaycelSpacing.sm),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BaycelRadius.sm),
                        borderSide: BorderSide(color: BaycelColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BaycelRadius.sm),
                        borderSide: BorderSide(color: BaycelColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BaycelRadius.sm),
                        borderSide: BorderSide(color: BaycelColors.crimson),
                      ),
                    ),
                  ),
                  SizedBox(height: BaycelSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : () async {
                            setDialogState(() => isProcessing = true);
                            final comment = commentController.text.trim();
                            try {
                              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                              await _firestore.updateCashAdvance(advance.id, {
                                'status': 'rejected',
                                'reviewedAt': DateTime.now(),
                                'reviewedBy': uid,
                                if (comment.isNotEmpty) 'reviewNote': comment,
                              });
                              _recentlyActionedCashAdvances.add(advance.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cash advance rejected')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update'), backgroundColor: BaycelColors.error));
                            }
                            if (mounted) Navigator.pop(ctx);
                          },
                          icon: Icon(Icons.close, size: 14, color: BaycelColors.error),
                          label: Text('Reject', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: BaycelColors.error.withValues(alpha: 0.3)),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : () async {
                            setDialogState(() => isProcessing = true);
                            try {
                              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                              await _firestore.updateCashAdvance(advance.id, {
                                'status': 'approved',
                                'reviewedAt': DateTime.now(),
                                'reviewedBy': uid,
                              });
                              _recentlyActionedCashAdvances.add(advance.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cash advance approved')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update'), backgroundColor: BaycelColors.error));
                            }
                            if (mounted) Navigator.pop(ctx);
                          },
                          icon: Icon(Icons.check, size: 14, color: Colors.white),
                          label: Text('Approve', style: BaycelTypography.labelSm.copyWith(color: Colors.white, fontSize: 11)),
                          style: BaycelComponents.buttonPrimary.copyWith(
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _bulkApproveCashAdvances(List<CashAdvance> pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve All Cash Advances'),
        content: Text('Approve ${pending.length} cash advance request${pending.length > 1 ? 's' : ''}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Approve All', style: TextStyle(color: BaycelColors.success)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessingCashAdvance = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      for (final advance in pending) {
        await _firestore.updateCashAdvance(advance.id, {
          'status': 'approved',
          'reviewedAt': DateTime.now(),
          'reviewedBy': uid,
        });
        _recentlyActionedCashAdvances.add(advance.id);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pending.length} cash advance${pending.length > 1 ? 's' : ''} approved')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve some requests'), backgroundColor: BaycelColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessingCashAdvance = false);
    }
  }

  Widget _buildChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              _buildRevenueTrend(),
              SizedBox(height: BaycelSpacing.base),
              _buildCategoryDonut(),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 16, child: _buildRevenueTrend()),
              SizedBox(width: BaycelSpacing.base),
              Expanded(flex: 10, child: _buildCategoryDonut()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueTrend() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
      builder: (context, snapshot) {
        final deliveries = snapshot.data ?? [];
        final now = DateTime.now();
        final dailyRevenue = <String, double>{};
        const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final label = dayLabels[day.weekday - 1];
          final dayDeliveries = deliveries.where((d) =>
            d.createdAt.year == day.year && d.createdAt.month == day.month && d.createdAt.day == day.day);
          dailyRevenue[label] = dayDeliveries.length.toDouble();
        }

        final entries = dailyRevenue.entries.toList();
        final maxVal = entries.isEmpty ? 1.0 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Volume', style: BaycelTypography.headlineMd),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.md)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: BaycelColors.textMuted),
                        SizedBox(width: 2),
                        Text('This week', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.base),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: entries.map((e) {
                      final pct = maxVal > 0 ? e.value / maxVal : 0.0;
                      final hasSales = e.value > 0;
                      return SizedBox(
                        width: 44,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasSales)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text('${e.value.toInt()}', style: BaycelTypography.labelSm.copyWith(
                                    color: BaycelColors.crimson, fontSize: 9, fontWeight: FontWeight.w600)),
                                ),
                              Container(
                                height: 120 * (pct > 0 ? pct : 0.03),
                                decoration: BoxDecoration(
                                  color: hasSales ? BaycelColors.crimson : BaycelColors.divider.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(e.key, style: BaycelTypography.labelSm.copyWith(
                                color: hasSales ? BaycelColors.textPrimary : BaycelColors.textMuted,
                                fontSize: 11,
                                fontWeight: hasSales ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryDonut() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final catCount = <String, int>{};
        for (final p in products) {
          catCount[p.category] = (catCount[p.category] ?? 0) + p.stockQuantity;
        }
        final total = catCount.values.fold<int>(0, (s, v) => s + v);
        final colors = [BaycelColors.viz1, BaycelColors.viz2, BaycelColors.viz3, BaycelColors.viz4, BaycelColors.viz5];

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock by Category', style: BaycelTypography.headlineMd),
              SizedBox(height: BaycelSpacing.sm),
              Text('$total total units across ${catCount.length} categories',
                style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
              SizedBox(height: BaycelSpacing.base),
              if (catCount.isEmpty)
                Center(
                  child: Text('No data', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                )
              else
                Column(
                  children: [
                    ...catCount.entries.toList().asMap().entries.map((e) {
                      final name = e.value.key;
                      final count = e.value.value;
                      final color = colors[e.key % colors.length];
                      final pct = total > 0 ? (count / total * 100).round() : 0;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            SizedBox(width: BaycelSpacing.sm),
                            Expanded(child: Text(name, style: BaycelTypography.bodySm)),
                            Text('$pct%', style: BaycelTypography.bodySm.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomRow({GlobalKey? key, GlobalKey? deliveriesKey}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              KeyedSubtree(key: key, child: _buildTopProducts()),
              SizedBox(height: BaycelSpacing.base),
              KeyedSubtree(key: deliveriesKey, child: _buildRecentDeliveries()),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 10, child: KeyedSubtree(key: key, child: _buildTopProducts())),
              SizedBox(width: BaycelSpacing.base),
              Expanded(flex: 15, child: KeyedSubtree(key: deliveriesKey, child: _buildRecentDeliveries())),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopProducts() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final sorted = List<Product>.from(products)..sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        final top = sorted.take(4).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Top Products This Week', style: BaycelTypography.headlineMd),
                  GestureDetector(
                    onTap: () => widget.onNavigate?.call(1),
                    child: Text('View all', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              if (top.isEmpty)
                Center(child: Text('No products', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)))
              else
                Column(
                  children: top.asMap().entries.map((e) {
                      final p = e.value;
                      final revenue = p.stockQuantity * p.price;
                      return StaggeredItem(
                        index: e.key,
                        child: _LeaderboardRow(
                          rank: '${e.key + 1}',
                          name: p.name,
                          meta: '${p.stockQuantity} ${p.unit} in stock',
                          value: '\u20B1${revenue.toStringAsFixed(0)}',
                          showDivider: e.key < top.length - 1,
                        ),
                      );
                    }).toList(),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentDeliveries() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
      builder: (context, snapshot) {
        final deliveries = snapshot.data ?? [];
        final recent = deliveries.take(5).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Deliveries', style: BaycelTypography.headlineMd),
                  GestureDetector(
                    onTap: () => widget.onNavigate?.call(2),
                    child: Text('View all', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              if (recent.isEmpty)
                Center(child: Padding(
                  padding: EdgeInsets.all(BaycelSpacing.xl),
                  child: Text('No deliveries yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                ))
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Table(
                            columnWidths: {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              _buildDeliveryTableHeaderRow(),
                              ...recent.map((d) => _buildDeliveryTableRow(
                                supplier: d.supplierName,
                                items: '${d.items.length} SKUs',
                                receivedBy: d.receivedBy ?? '\u2014',
                                status: d.status,
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  TableRow _buildDeliveryTableHeaderRow() {
    final style = BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.03);
    return TableRow(
      children: [
        _buildDeliveryTh('SUPPLIER', style),
        _buildDeliveryTh('ITEMS', style),
        _buildDeliveryTh('RECEIVED BY', style),
        _buildDeliveryTh('STATUS', style),
      ],
    );
  }

  Widget _buildDeliveryTh(String text, TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
      child: Text(text, style: style),
    );
  }

  TableRow _buildDeliveryTableRow({
    required String supplier,
    required String items,
    required String receivedBy,
    required DeliveryStatus status,
  }) {
    return TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5))),
      children: [
        _buildDeliveryTr(supplier, BaycelTypography.bodySm.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        _buildDeliveryTr(items, BaycelTypography.bodySm.copyWith(fontSize: 12.5)),
        _buildDeliveryTr(receivedBy, BaycelTypography.bodySm.copyWith(fontSize: 12.5)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
          child: DeliveryStatusPill(status: status),
        ),
      ],
    );
  }

  Widget _buildDeliveryTr(String text, TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
      child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

}

class _LeaderboardRow extends StatelessWidget {
  final String rank;
  final String name;
  final String meta;
  final String value;
  final bool showDivider;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.meta,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: showDivider
          ? BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5))))
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(rank, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: BaycelColors.surface,
              borderRadius: BorderRadius.circular(BaycelRadius.xl),
            ),
            child: Icon(Icons.inventory_2_rounded, size: 16, color: BaycelColors.textSecondary),
          ),
          SizedBox(width: BaycelSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(value, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _OwnerQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OwnerQuickActionCard({
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

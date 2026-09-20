import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/floor_staff_shared_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/cash_advance.dart';
import '../models/absence_form.dart';
import '../widgets/floor_staff_helpers.dart';
import 'floor_staff/delivery_scanner_screen.dart';
import 'inventory_screen.dart';
import 'delivery_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final _firestore = FirestoreService();
  String _userName = 'Manager';
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  String _clockTime = '';
  String _todayAttendanceId = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _restoreClockInState();
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_greeting()}, $_userName', style: BaycelTypography.display),
          SizedBox(height: BaycelSpacing.xxs),
          Text('Store operations overview for Baycel Growcery.',
            style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary)),
          SizedBox(height: BaycelSpacing.lg),
          ClockCard(
            isClockedIn: _isClockedIn,
            isOnBreak: _isOnBreak,
            clockTime: _clockTime,
            onToggleClockIn: _toggleClockIn,
            onToggleBreak: _toggleBreak,
          ),
          SizedBox(height: BaycelSpacing.lg),
          _buildScannerSection(),
          SizedBox(height: BaycelSpacing.lg),
          _buildStatGrid(),
          SizedBox(height: BaycelSpacing.lg),
          _buildChartsRow(),
          SizedBox(height: BaycelSpacing.lg),
          _buildBottomRow(),
          SizedBox(height: BaycelSpacing.lg),
          CashAdvanceCard(onSubmit: (amount, reason) async {
            try {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              await _firestore.addCashAdvance(CashAdvance(
                id: '',
                employeeId: uid,
                employeeName: _userName,
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
          SizedBox(height: BaycelSpacing.lg),
          MyRequestsCard(requestsStream: _firestore.getCashAdvancesByUser(FirebaseAuth.instance.currentUser?.uid ?? '')),
          SizedBox(height: BaycelSpacing.lg),
          _AbsenceFormCard(onSubmit: (startDate, endDate, reason) async {
            try {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final user = await _firestore.getCurrentUser();
              await _firestore.addAbsenceForm(AbsenceForm(
                id: '',
                employeeId: uid,
                employeeName: user?.name ?? _userName,
                reason: reason,
                startDate: startDate,
                endDate: endDate,
                submittedAt: DateTime.now(),
              ));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absence request submitted')));
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unable to submit request'), backgroundColor: BaycelColors.error),
                );
              }
            }
          }),
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
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                  onTap: () => _scanBarcode(),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Paper List',
                  onTap: () => _scanPaperList(),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(role: 'manager'))),
                ),
              ),
              SizedBox(width: BaycelSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Deliveries',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryScreen())),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BarcodeScannerSheet(
        onScanned: (code) async {
          Navigator.pop(ctx);
          final product = await _firestore.getProductByBarcode(code);
          if (product != null) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} found')),
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

  Widget _buildStatGrid() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, productSnap) {
        final products = productSnap.data ?? [];
        final totalStock = products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
        final lowStock = products.where((p) => p.stockQuantity <= p.reorderLevel).length;
        final categories = <String, int>{};
        for (final p in products) {
          categories[p.category] = (categories[p.category] ?? 0) + p.stockQuantity;
        }
        final catCount = categories.length;

        return StreamBuilder<List<Delivery>>(
          stream: _firestore.getDeliveries(),
          builder: (context, deliverySnap) {
            final deliveries = deliverySnap.data ?? [];
            final pending = deliveries.where((d) =>
              d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).length;

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
                    final today = DateTime.now();
                    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                    final present = records.where((r) => r.date == todayStr && r.timeOut == null).length;
                    final onLeave = (totalEmployees - present).clamp(0, totalEmployees);

                    final statCards = [
                      BaycelStatCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: BaycelColors.viz4,
                        value: '$totalStock',
                        title: 'Products in Stock',
                        subtitle: 'Across $catCount categories',
                        subtitleColor: BaycelColors.textMuted,
                      ),
                      BaycelStatCard(
                        icon: Icons.warning_amber_rounded,
                        iconColor: BaycelColors.crimson,
                        value: '$lowStock',
                        title: 'Low-Stock Alerts',
                        subtitle: lowStock > 0 ? 'Needs reordering' : 'All stocked',
                        subtitleColor: lowStock > 0 ? BaycelColors.crimson : BaycelColors.success,
                      ),
                      BaycelStatCard(
                        icon: Icons.local_shipping_outlined,
                        iconColor: BaycelColors.blue,
                        value: '$pending',
                        title: 'Deliveries Pending',
                        subtitle: pending > 0 ? 'Awaiting verification' : 'All delivered',
                        subtitleColor: BaycelColors.textMuted,
                      ),
                      BaycelStatCard(
                        icon: Icons.groups_outlined,
                        iconColor: BaycelColors.viz5,
                        value: '$present / $totalEmployees',
                        title: 'Employees Present',
                        subtitle: '$onLeave on leave',
                        subtitleColor: BaycelColors.textMuted,
                      ),
                    ];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth > 900 ? 4 : 2;
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
  }

  Widget _buildChartsRow() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final categories = <String, int>{};
        for (final p in products) {
          categories[p.category] = (categories[p.category] ?? 0) + p.stockQuantity;
        }

        return StreamBuilder<List<StoreUser>>(
          stream: _firestore.getUsers(),
          builder: (context, userSnap) {
            final users = userSnap.data ?? [];
            final totalEmployees = users.where((u) => u.role != UserRole.owner).length;

            return StreamBuilder<List<AttendanceRecord>>(
              stream: _firestore.getAttendance(),
              builder: (context, attSnap) {
                final records = attSnap.data ?? [];
                final now = DateTime.now();
                final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final attendanceRates = <double>[];

                for (int i = 6; i >= 0; i--) {
                  final day = now.subtract(Duration(days: i));
                  final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final present = records.where((r) => r.date == dateStr && r.timeOut == null).length;
                  final rate = totalEmployees > 0 ? (present / totalEmployees * 100).clamp(0.0, 100.0) : 0.0;
                  attendanceRates.add(rate);
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                        child: Column(
                          children: [
                            _buildStockChart(categories),
                            SizedBox(height: BaycelSpacing.base),
                            Expanded(child: _buildAttendanceChart(dayLabels, attendanceRates)),
                          ],
                        ),
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 10, child: _buildStockChart(categories)),
                          SizedBox(width: BaycelSpacing.base),
                          Expanded(flex: 12, child: _buildAttendanceChart(dayLabels, attendanceRates)),
                        ],
                      ),
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

  Widget _buildStockChart(Map<String, int> categories) {
    final total = categories.values.fold<int>(0, (s, v) => s + v);
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock Levels by Category', style: BaycelTypography.headlineMd),
              SizedBox(height: 2),
              Text('Units on hand, current snapshot',
                style: BaycelTypography.labelSm.copyWith(fontSize: 11.5, color: BaycelColors.textMuted)),
            ],
          ),
          SizedBox(height: BaycelSpacing.md),
          if (categories.isEmpty)
            Center(child: Padding(
              padding: EdgeInsets.all(BaycelSpacing.xl),
              child: Text('No products yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
            ))
          else
            ...categories.entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: BaycelTypography.body.copyWith(fontSize: 13)),
                        Text('${e.value}', style: BaycelTypography.dataMono.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(BaycelRadius.full),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: BaycelColors.divider.withValues(alpha: 0.3),
                        color: BaycelColors.crimson,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart(List<String> labels, List<double> rates) {
    final maxRate = rates.isEmpty ? 0.0 : rates.reduce((a, b) => a > b ? a : b);
    final minRate = rates.isEmpty ? 0.0 : rates.reduce((a, b) => a < b ? a : b);
    final range = maxRate - minRate;

    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Rate', style: BaycelTypography.headlineMd),
          SizedBox(height: BaycelSpacing.sm),
          if (rates.isEmpty || maxRate == 0)
            Expanded(
              child: Center(child: Text('No attendance data', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled))),
            )
          else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(rates.length, (i) {
                  final normalizedHeight = range > 0
                    ? (rates[i] - minRate) / range
                    : 0.5;
                  final barHeight = 30.0 + normalizedHeight * 80.0;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${rates[i].round()}%', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 9)),
                          SizedBox(height: 3),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: BaycelColors.viz5,
                              borderRadius: BorderRadius.circular(BaycelRadius.md),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(labels[i], style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                  }),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, productSnap) {
        final products = productSnap.data ?? [];
        final lowStockProducts = products.where((p) => p.stockQuantity <= p.reorderLevel).toList()
          ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

        return StreamBuilder<List<Delivery>>(
          stream: _firestore.getDeliveries(),
          builder: (context, deliverySnap) {
            final deliveries = deliverySnap.data ?? [];
            final pendingDeliveries = deliveries.where((d) =>
              d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      _buildNeedsReordering(lowStockProducts),
                      SizedBox(height: BaycelSpacing.base),
                      _buildDeliveriesAwaiting(pendingDeliveries),
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 10, child: _buildNeedsReordering(lowStockProducts)),
                      SizedBox(width: BaycelSpacing.base),
                      Expanded(flex: 15, child: _buildDeliveriesAwaiting(pendingDeliveries)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNeedsReordering(List<Product> products) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Needs Reordering', style: BaycelTypography.headlineMd),
              Text('View all', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          if (products.isEmpty)
            Center(child: Padding(
              padding: EdgeInsets.all(BaycelSpacing.xl),
              child: Text('All products are stocked', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.success)),
            ))
          else
            ...products.take(4).map((p) {
              final isOut = p.stockQuantity == 0;
              return _ReorderRow(
                icon: Icons.inventory_2_outlined,
                name: p.name,
                meta: '${p.stockQuantity} ${p.unit} left',
                pillLabel: isOut ? 'Out' : 'Low',
                pillColor: isOut ? BaycelColors.crimsonDark : BaycelColors.marigoldDark,
                pillBg: isOut ? BaycelColors.crimson : BaycelColors.marigold,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDeliveriesAwaiting(List<Delivery> deliveries) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deliveries Awaiting Verification', style: BaycelTypography.headlineMd),
              Text('View all', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: BaycelSpacing.sm),
          if (deliveries.isEmpty)
            Center(child: Padding(
              padding: EdgeInsets.all(BaycelSpacing.xl),
              child: Text('No pending deliveries', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
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
                        TableRow(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider))),
                          children: [
                            _buildDeliveryTh('SUPPLIER'),
                            _buildDeliveryTh('ITEMS'),
                            _buildDeliveryTh('RECEIVED BY'),
                            _buildDeliveryTh('STATUS'),
                          ],
                        ),
                        ...deliveries.take(3).map((d) => _buildDeliveryTr(
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
  }

  Widget _buildDeliveryTh(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.03)),
    );
  }

  TableRow _buildDeliveryTr({
    required String supplier,
    required String items,
    required String receivedBy,
    required DeliveryStatus status,
  }) {
    return TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5))),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
          child: Text(supplier, style: BaycelTypography.bodySm.copyWith(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
          child: Text(items, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
          child: Text(receivedBy, style: BaycelTypography.bodySm.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 9),
          child: DeliveryStatusPill(status: status),
        ),
      ],
    );
  }
}

class _ReorderRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String meta;
  final String pillLabel;
  final Color pillColor;
  final Color pillBg;

  const _ReorderRow({
    required this.icon,
    required this.name,
    required this.meta,
    required this.pillLabel,
    required this.pillColor,
    required this.pillBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5)))),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: BaycelColors.surface, borderRadius: BorderRadius.circular(BaycelRadius.xl)),
            child: Icon(icon, size: 16, color: BaycelColors.textSecondary),
          ),
          SizedBox(width: BaycelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BaycelTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 1),
                Text(meta, style: BaycelTypography.labelSm.copyWith(fontSize: 11.5, color: BaycelColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(width: BaycelSpacing.sm),
          _Pill(label: pillLabel, color: pillColor, bgColor: pillBg),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Pill({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs + 1),
      decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(BaycelRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: BaycelSpacing.xxs + 2),
          Text(label, style: BaycelTypography.labelXs.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
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
          Text('Requests are reviewed by the Owner',
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

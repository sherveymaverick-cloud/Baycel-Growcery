import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/shared_widgets.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../models/stock_movement.dart';
import '../widgets/search_scope.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _firestore = FirestoreService();
  String _salesPeriod = 'weekly';
  bool _isOwner = false;
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  void _loadRole() async {
    final user = await _firestore.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _isOwner = user?.role == UserRole.owner;
      _roleLoaded = true;
    });
  }

  List<_SalesBucket> _aggregateSales(List<StockMovement> movements, String period) {
    final now = DateTime.now();
    final sales = movements.where((m) => m.productId == 'sales').toList();
    
    final Map<String, double> buckets = {};
    String Function(DateTime) keyFn;
    List<String> labels;

    if (period == 'daily') {
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      keyFn = (dt) => '${dt.year}-${dt.month}-${dt.day}';
      labels = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return dayLabels[d.weekday - 1];
      });
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        buckets['${d.year}-${d.month}-${d.day}'] = 0;
      }
    } else if (period == 'weekly') {
      keyFn = (dt) => '${dt.year}-W${_weekNumber(dt)}';
      labels = List.generate(8, (i) {
        final d = now.subtract(Duration(days: (7 - i) * 7));
        return 'W${_weekNumber(d)}';
      });
      for (int i = 0; i < 8; i++) {
        final d = now.subtract(Duration(days: (7 - i) * 7));
        buckets['${d.year}-W${_weekNumber(d)}'] = 0;
      }
    } else if (period == 'monthly') {
      keyFn = (dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      labels = List.generate(6, (i) {
        final d = DateTime(now.year, now.month - 5 + i, 1);
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return months[d.month - 1];
      });
      for (int i = 0; i < 6; i++) {
        final d = DateTime(now.year, now.month - 5 + i, 1);
        buckets['${d.year}-${d.month.toString().padLeft(2, '0')}'] = 0;
      }
    } else {
      keyFn = (dt) => '${dt.year}';
      labels = List.generate(5, (i) => '${now.year - 4 + i}');
      for (int i = 0; i < 5; i++) {
        buckets['${now.year - 4 + i}'] = 0;
      }
    }

    for (final m in sales) {
      final key = keyFn(m.createdAt);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + m.quantity;
      }
    }

    return List.generate(labels.length, (i) {
      final key = period == 'daily'
          ? '${now.subtract(Duration(days: 6 - i)).year}-${now.subtract(Duration(days: 6 - i)).month}-${now.subtract(Duration(days: 6 - i)).day}'
          : period == 'weekly'
          ? '${now.subtract(Duration(days: (7 - i) * 7)).year}-${_weekNumber(now.subtract(Duration(days: (7 - i) * 7)))}'
          : period == 'monthly'
              ? '${now.year}-${(now.month - 5 + i).toString().padLeft(2, '0')}'
              : '${now.year - 4 + i}';
      return _SalesBucket(label: labels[i], amount: buckets[key] ?? 0);
    });
  }

  int _weekNumber(DateTime dt) {
    final firstDay = DateTime(dt.year, 1, 1);
    final days = dt.difference(firstDay).inDays;
    return ((days + firstDay.weekday - 1) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) {
      return const SkeletonReportsPage();
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredItem(index: 0, child: _buildHeader()),
          SizedBox(height: BaycelSpacing.lg),
          StaggeredItem(index: 1, child: _buildSalesGraph()),
          SizedBox(height: BaycelSpacing.lg),
          StaggeredItem(index: 2, child: _buildReportCards(context)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reports', style: BaycelTypography.display),
        SizedBox(height: BaycelSpacing.xxs),
        Text(
          'Generate sales, attendance, and inventory reports',
          style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _buildSalesGraph() {
    return StreamBuilder<List<StockMovement>>(
      stream: _firestore.getStockMovements(),
      builder: (context, snapshot) {
        final movements = snapshot.data ?? [];
        final buckets = _aggregateSales(movements, _salesPeriod);
        final maxVal = buckets.fold<double>(0, (s, b) => b.amount > s ? b.amount : s);

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sales Overview', style: BaycelTypography.headlineMd.copyWith(fontSize: 14)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm),
                    decoration: BoxDecoration(
                      color: BaycelColors.card,
                      border: Border.all(color: BaycelColors.divider),
                      borderRadius: BorderRadius.circular(BaycelRadius.md),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _salesPeriod,
                        isDense: true,
                        style: BaycelTypography.bodySm.copyWith(fontSize: 11),
                        dropdownColor: BaycelColors.card,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                        ],
                        onChanged: (v) => setState(() => _salesPeriod = v ?? 'weekly'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: BaycelSpacing.base),
              SizedBox(
                height: 140,
                child: maxVal == 0
                    ? Center(
                        child: Text('No sales data yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: buckets.map((b) {
                            final fraction = maxVal > 0 ? b.amount / maxVal : 0.0;
                            return SizedBox(
                              width: 48,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      b.amount > 0 ? _formatShort(b.amount) : '',
                                      style: BaycelTypography.labelSm.copyWith(fontSize: 8, color: BaycelColors.textMuted),
                                    ),
                                    SizedBox(height: 2),
                                    Container(
                                      height: (fraction * 100).clamp(4.0, 100.0),
                                      decoration: BoxDecoration(
                                        color: BaycelColors.crimson,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(b.label, style: BaycelTypography.labelSm.copyWith(fontSize: 8, color: BaycelColors.textMuted)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatShort(double amount) {
    if (amount >= 1000) return '\u20B1${(amount / 1000).toStringAsFixed(1)}k';
    return '\u20B1${amount.toStringAsFixed(0)}';
  }

  Widget _buildReportCards(BuildContext context) {
    final query = context.searchQuery;
    final cards = <_ReportSpec>[
      _ReportSpec(
        title: 'Sales Report',
        description: 'Daily and weekly revenue and order volume, broken down by category.',
        icon: Icons.assessment_rounded,
        iconColor: BaycelColors.crimson,
      ),
      _ReportSpec(
        title: 'Attendance Report',
        description: 'Time-in/out records, lateness, undertime, and overtime by employee and role.',
        icon: Icons.access_time_rounded,
        iconColor: BaycelColors.viz5,
      ),
      if (_isOwner)
        _ReportSpec(
          title: 'Payroll Summary',
          description: 'Gross pay, deductions, and net pay totals for any completed pay period.',
          icon: Icons.receipt_long_rounded,
          iconColor: BaycelColors.marigoldDark,
        ),
      _ReportSpec(
        title: 'Employee Performance',
        description: 'Attendance consistency and task completion, ranked by role.',
        icon: Icons.people_rounded,
        iconColor: BaycelColors.blue,
      ),
      _ReportSpec(
        title: 'Inventory Report',
        description: 'Stock levels and reorder alerts across every product category.',
        icon: Icons.inventory_2_rounded,
        iconColor: BaycelColors.viz4,
      ),
      _ReportSpec(
        title: 'Delivery Report',
        description: 'Supplier reliability, on-time rate, and discrepancy history by vendor.',
        icon: Icons.local_shipping_rounded,
        iconColor: BaycelColors.success,
      ),
    ];
    final visible = query.isEmpty
        ? cards
        : cards.where((c) =>
            '${c.title} ${c.description}'.toLowerCase().contains(query)).toList();
    final visibleTitles = visible.map((c) => c.title).toSet();
    if (query.isNotEmpty && visible.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xl),
        child: Center(
          child: Text('No reports match "$query"',
            style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossCount,
          crossAxisSpacing: BaycelSpacing.md,
          mainAxisSpacing: BaycelSpacing.md,
          childAspectRatio: 1.8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (visibleTitles.contains('Sales Report'))
            _StreamReportCard<StockMovement>(
              title: 'Sales Report',
              description: 'Daily and weekly revenue and order volume, broken down by category.',
              icon: Icons.assessment_rounded,
              iconColor: BaycelColors.crimson,
              stream: _firestore.getStockMovements(),
              builder: (context, movements) {
                final sales = movements.where((m) => m.productId == 'sales').toList();
                final today = DateTime.now();
                final todaySales = sales.where((m) =>
                  m.createdAt.year == today.year && m.createdAt.month == today.month && m.createdAt.day == today.day);
                final todayTotal = todaySales.fold<double>(0, (s, m) => s + m.quantity);
                final weekAgo = today.subtract(Duration(days: 7));
                final weekSales = sales.where((m) => m.createdAt.isAfter(weekAgo));
                final weekTotal = weekSales.fold<double>(0, (s, m) => s + m.quantity);
                final monthStart = DateTime(today.year, today.month, 1);
                final monthSales = sales.where((m) => m.createdAt.isAfter(monthStart));
                final monthTotal = monthSales.fold<double>(0, (s, m) => s + m.quantity);
                final totalRevenue = sales.fold<double>(0, (s, m) => s + m.quantity);
                return _ReportCard(
                  title: 'Sales Report',
                  description: 'Daily and weekly revenue and order volume, broken down by category.',
                  icon: Icons.assessment_rounded,
                  iconColor: BaycelColors.crimson,
                  summary: {
                    'Today\'s Sales': '\u20B1${todayTotal.toStringAsFixed(0)}',
                    'This Week': '\u20B1${weekTotal.toStringAsFixed(0)}',
                    'This Month': '\u20B1${monthTotal.toStringAsFixed(0)}',
                    'Total Revenue': '\u20B1${totalRevenue.toStringAsFixed(0)}',
                    'Total Transactions': sales.length.toString(),
                  },
                  onGenerate: () => PdfService.generateSalesReport(
                    movements: movements,
                    dateRange: 'As of ${today.toString().split(' ')[0]}',
                  ),
                );
              },
            ),
            if (visibleTitles.contains('Attendance Report'))
            _StreamReportCard<AttendanceRecord>(
              title: 'Attendance Report',
              description: 'Time-in/out records, lateness, undertime, and overtime by employee and role.',
              icon: Icons.access_time_rounded,
              iconColor: BaycelColors.viz5,
              stream: _firestore.getAttendance(),
              builder: (context, attendance) {
                final present = attendance.where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.complete).length;
                final late = attendance.where((r) => r.lateMinutes > 0).length;
                final totalHrs = attendance.fold<double>(0, (s, r) => s + r.totalHours);
                return _ReportCard(
                  title: 'Attendance Report',
                  description: 'Time-in/out records, lateness, undertime, and overtime by employee and role.',
                  icon: Icons.access_time_rounded,
                  iconColor: BaycelColors.viz5,
                  summary: {
                    'Total Records': attendance.length.toString(),
                    'Present': present.toString(),
                    'Late': late.toString(),
                    'Total Hours': totalHrs.toStringAsFixed(1),
                  },
                  onGenerate: () async {
                    final users = await _firestore.getUsers().first;
                    if (context.mounted) {
                      PdfService.generateAttendanceReport(
                        attendance: attendance,
                        users: users,
                        dateRange: 'As of ${DateTime.now().toString().split(' ')[0]}',
                      );
                    }
                  },
                );
              },
            ),
            if (_isOwner && visibleTitles.contains('Payroll Summary'))
            _StreamReportCard<StoreUser>(
              title: 'Payroll Summary',
              description: 'Gross pay, deductions, and net pay totals for any completed pay period.',
              icon: Icons.receipt_long_rounded,
              iconColor: BaycelColors.marigoldDark,
              stream: _firestore.getUsers().map(
                    (users) => users
                        .where((u) =>
                            u.role != UserRole.owner &&
                            u.role != UserRole.merchandiser)
                        .toList(),
                  ),
              builder: (context, users) {
                return _ReportCard(
                  title: 'Payroll Summary',
                  description: 'Gross pay, deductions, and net pay totals for any completed pay period.',
                  icon: Icons.receipt_long_rounded,
                  iconColor: BaycelColors.marigoldDark,
                  summary: {
                    'Total Employees': users.length.toString(),
                    'Roles': users.map((u) => u.role.value).toSet().length.toString(),
                  },
                  onGenerate: () async {
                    final payrolls = (await _firestore.getPayrollsOnce())
                        .where((p) => p.role != 'merchandiser')
                        .toList();
                    if (context.mounted) {
                      PdfService.generatePayrollReport(
                        payrolls: payrolls,
                        users: users,
                        dateRange: 'As of ${DateTime.now().toString().split(' ')[0]}',
                      );
                    }
                  },
                );
              },
            ),
            if (visibleTitles.contains('Employee Performance'))
            _StreamReportCard<StoreUser>(
              title: 'Employee Performance',
              description: 'Attendance consistency and task completion, ranked by role.',
              icon: Icons.people_rounded,
              iconColor: BaycelColors.blue,
              stream: _firestore.getUsers(),
              builder: (context, users) {
                return _ReportCard(
                  title: 'Employee Performance',
                  description: 'Attendance consistency and task completion, ranked by role.',
                  icon: Icons.people_rounded,
                  iconColor: BaycelColors.blue,
                  summary: {
                    'Total Employees': users.length.toString(),
                  },
                  onGenerate: () async {
                    final attendance = await _firestore.getAttendance().first;
                    if (context.mounted) {
                      PdfService.generateAttendanceReport(
                        attendance: attendance,
                        users: users,
                        dateRange: 'Performance - ${DateTime.now().toString().split(' ')[0]}',
                      );
                    }
                  },
                );
              },
            ),
            if (visibleTitles.contains('Inventory Report'))
            _StreamReportCard<Product>(
              title: 'Inventory Report',
              description: 'Stock levels and reorder alerts across every product category.',
              icon: Icons.inventory_2_rounded,
              iconColor: BaycelColors.viz4,
              stream: _firestore.getProducts(),
              builder: (context, products) {
                final totalStock = products.fold<int>(0, (s, p) => s + p.stockQuantity);
                final lowStock = products.where((p) => p.stockQuantity <= p.reorderLevel).length;
                final totalValue = products.fold<double>(0, (s, p) => s + (p.price * p.stockQuantity));
                return _ReportCard(
                  title: 'Inventory Report',
                  description: 'Stock levels and reorder alerts across every product category.',
                  icon: Icons.inventory_2_rounded,
                  iconColor: BaycelColors.viz4,
                  summary: {
                    'Total Products': products.length.toString(),
                    'Total Stock Units': totalStock.toString(),
                    'Low Stock Items': lowStock.toString(),
                    'Categories': products.map((p) => p.category).toSet().length.toString(),
                    'Inventory Value': '\u20B1${totalValue.toStringAsFixed(0)}',
                  },
                  onGenerate: () => PdfService.generateInventoryReport(
                    products: products,
                    dateRange: 'As of ${DateTime.now().toString().split(' ')[0]}',
                  ),
                );
              },
            ),
            if (visibleTitles.contains('Delivery Report'))
            _StreamReportCard<Delivery>(
              title: 'Delivery Report',
              description: 'Supplier reliability, on-time rate, and discrepancy history by vendor.',
              icon: Icons.local_shipping_rounded,
              iconColor: BaycelColors.success,
              stream: _firestore.getDeliveries(),
              builder: (context, deliveries) {
                final verified = deliveries.where((d) => d.status == DeliveryStatus.delivered).length;
                final discrepancy = deliveries.where((d) => d.status == DeliveryStatus.discrepancy).length;
                return _ReportCard(
                  title: 'Delivery Report',
                  description: 'Supplier reliability, on-time rate, and discrepancy history by vendor.',
                  icon: Icons.local_shipping_rounded,
                  iconColor: BaycelColors.success,
                  summary: {
                    'Total Deliveries': deliveries.length.toString(),
                    'Verified': verified.toString(),
                    'Discrepancies': discrepancy.toString(),
                    'Pending': deliveries.where((d) => d.status == DeliveryStatus.pending).length.toString(),
                  },
                  onGenerate: () => PdfService.generateDeliveryReport(
                    deliveries: deliveries,
                    dateRange: 'As of ${DateTime.now().toString().split(' ')[0]}',
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ReportSpec {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  const _ReportSpec({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onGenerate;
  final Map<String, String>? summary;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onGenerate,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.base),
      decoration: BaycelComponents.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(BaycelRadius.lg),
                      ),
                      child: Icon(icon, size: 15, color: iconColor),
                    ),
                    SizedBox(width: BaycelSpacing.sm),
                    Expanded(child: Text(title, style: BaycelTypography.headlineMd.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                SizedBox(height: BaycelSpacing.xs),
                Text(description, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted, fontSize: 11.5, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (summary != null && summary!.isNotEmpty) ...[
                  SizedBox(height: BaycelSpacing.xs),
                  ...summary!.entries.take(3).map((e) => Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 10)),
                        Text(e.value, style: BaycelTypography.labelSm.copyWith(fontWeight: FontWeight.w600, fontSize: 10)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              style: BaycelComponents.buttonOutlined.copyWith(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.sm)),
              ),
              onPressed: onGenerate,
              icon: const Icon(Icons.picture_as_pdf, size: 14),
              label: const Text('Generate PDF', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamReportCard<T> extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Stream<List<T>> stream;
  final Widget Function(BuildContext context, List<T> data) builder;

  const _StreamReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.stream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        return builder(context, data);
      },
    );
  }
}

class _SalesBucket {
  final String label;
  final double amount;
  const _SalesBucket({required this.label, required this.amount});
}

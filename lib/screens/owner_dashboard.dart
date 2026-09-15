import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/user.dart';
import '../models/attendance.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final _firestore = FirestoreService();
  String _userName = 'Owner';

  @override
  void initState() {
    super.initState();
    _loadUserName();
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
          _buildStatGrid(),
          SizedBox(height: BaycelSpacing.lg),
          _buildChartsRow(),
          SizedBox(height: BaycelSpacing.lg),
          _buildBottomRow(),
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
                final totalEmployees = users.length;

                return StreamBuilder<List<AttendanceRecord>>(
                  stream: _firestore.getAttendance(),
                  builder: (context, attSnap) {
                    final records = attSnap.data ?? [];
                    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                    final todayPresent = records.where((r) => r.date == todayStr && r.timeOut == null).length;
                    final present = todayPresent;
                    final onLeave = (totalEmployees - present).clamp(0, totalEmployees);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth > 900 ? 4 : 2;
                        final ratio = constraints.maxWidth > 900 ? 1.8 : 2.0;
                        final statCards = [
                          BaycelStatCard(
                            iconColor: BaycelColors.crimson,
                            icon: Icons.attach_money_rounded,
                            value: 'No data',
                            title: "Today's Revenue",
                            subtitle: 'Connect sales module',
                            subtitleColor: BaycelColors.textMuted,
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
                          childAspectRatio: ratio,
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
          dailyRevenue[label] = dayDeliveries.length * 260.0;
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
                  Text('Revenue Trend', style: BaycelTypography.headlineMd),
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
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: entries.map((e) {
                    final pct = maxVal > 0 ? e.value / maxVal : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 120 * pct,
                              decoration: BoxDecoration(
                                color: BaycelColors.crimson,
                                borderRadius: BorderRadius.circular(BaycelRadius.md),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(e.key, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
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
              Text('Sales by Category', style: BaycelTypography.headlineMd),
              SizedBox(height: BaycelSpacing.base),
              if (catCount.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No data', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\u20B1${(total * 0.1).toStringAsFixed(1)}K',
                                style: BaycelTypography.headline.copyWith(fontSize: 18)),
                              Text('Total', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: BaycelSpacing.base),
                      ...catCount.entries.toList().asMap().entries.map((e) {
                        final entry = e.value.value;
                        final color = colors[e.key % colors.length];
                        final pct = total > 0 ? (entry / total * 100).round() : 0;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              SizedBox(width: BaycelSpacing.sm),
                              Expanded(child: Text(e.value.key, style: BaycelTypography.bodySm)),
                              Text('$pct%', style: BaycelTypography.bodySm.copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              _buildTopProducts(),
              SizedBox(height: BaycelSpacing.base),
              _buildRecentDeliveries(),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 10, child: _buildTopProducts()),
              SizedBox(width: BaycelSpacing.base),
              Expanded(flex: 15, child: _buildRecentDeliveries()),
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
                  Text('View all', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              if (top.isEmpty)
                Expanded(child: Center(child: Text('No products', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled))))
              else
                Expanded(
                  child: Column(
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
                  Text('View all', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: BaycelSpacing.sm),
              if (recent.isEmpty)
                Expanded(child: Center(child: Padding(
                  padding: EdgeInsets.all(BaycelSpacing.xl),
                  child: Text('No deliveries yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                )))
              else
                Expanded(
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
          child: _buildStatusPill(status),
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

  Widget _buildStatusPill(DeliveryStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case DeliveryStatus.delivered:
        bgColor = BaycelColors.success.withValues(alpha: 0.12);
        textColor = BaycelColors.success;
        label = 'Verified';
      case DeliveryStatus.pending:
        bgColor = BaycelColors.marigoldDark.withValues(alpha: 0.18);
        textColor = BaycelColors.marigoldDark;
        label = 'Pending';
      case DeliveryStatus.inTransit:
        bgColor = BaycelColors.blue.withValues(alpha: 0.1);
        textColor = BaycelColors.blue;
        label = 'In Transit';
      case DeliveryStatus.discrepancy:
        bgColor = BaycelColors.crimson.withValues(alpha: 0.1);
        textColor = BaycelColors.crimsonDark;
        label = 'Discrepancy';
      case DeliveryStatus.cancelled:
        bgColor = BaycelColors.textDisabled.withValues(alpha: 0.12);
        textColor = BaycelColors.textDisabled;
        label = 'Cancelled';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xxs + 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(BaycelRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
          SizedBox(width: BaycelSpacing.xxs + 2),
          Text(label, style: BaycelTypography.labelSm.copyWith(color: textColor, fontSize: 10.5)),
        ],
      ),
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

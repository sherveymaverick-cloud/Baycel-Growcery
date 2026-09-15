import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/delivery.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  DeliveryStatus? _selectedFilter;
  final _firestore = FirestoreService();
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _detectRole();
  }

  void _detectRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() => _userRole = data['role'] as String? ?? '');
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredItem(index: 0, child: _buildHeader()),
          SizedBox(height: BaycelSpacing.lg),
          if (_userRole == 'manager') ...[
            StaggeredItem(index: 1, child: _buildViewOnlyBanner()),
            SizedBox(height: BaycelSpacing.lg),
          ],
          StaggeredItem(index: 2, child: _buildFilterChips()),
          SizedBox(height: BaycelSpacing.lg),
          Expanded(child: StaggeredItem(index: 3, child: _buildDeliveryTable())),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliveries', style: BaycelTypography.display),
            SizedBox(height: BaycelSpacing.xxs),
            Text('$count deliveries logged today',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5)),
          ],
        );
      },
    );
  }

  Widget _buildViewOnlyBanner() {
    return Container(
      padding: EdgeInsets.all(BaycelSpacing.md),
      decoration: BoxDecoration(
        color: BaycelColors.blue.withValues(alpha: 0.07),
        border: Border.all(color: BaycelColors.blue.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(BaycelRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: BaycelColors.blue),
          SizedBox(width: BaycelSpacing.sm),
          Expanded(
            child: Text(
              'View-only \u2014 delivery receiving is logged by the Bodegero and Delivery Checker roles.',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.blue, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      (label: 'All', status: null),
      (label: 'Verified', status: DeliveryStatus.delivered),
      (label: 'Pending', status: DeliveryStatus.pending),
      (label: 'Discrepancy', status: DeliveryStatus.discrepancy),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.status;
          return Padding(
            padding: EdgeInsets.only(right: BaycelSpacing.sm),
            child: ChoiceChip(
              label: Text(filter.label, style: BaycelTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : BaycelColors.textPrimary,
              )),
              selected: isSelected,
              selectedColor: BaycelColors.crimson,
              backgroundColor: BaycelColors.card,
              side: BorderSide(
                color: isSelected ? BaycelColors.crimson : BaycelColors.divider,
              ),
              onSelected: (_) {
                setState(() => _selectedFilter = filter.status);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryTable() {
    return StreamBuilder<List<Delivery>>(
      stream: _firestore.getDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SkeletonTable(rows: 6));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Unable to load deliveries', style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)));
        }

        final deliveries = snapshot.data ?? [];
        final filtered = _selectedFilter == null
            ? deliveries
            : deliveries.where((d) => d.status == _selectedFilter).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text('No deliveries found', style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)),
          );
        }

        return Container(
          decoration: BaycelComponents.card,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTh('Supplier'),
                    _buildTh('Date'),
                    _buildTh('Items'),
                    _buildTh('Received By'),
                    _buildTh('Status'),
                  ],
                ),
                ...filtered.map((d) => _buildTr(d)),
              ],
            ),
          ),
        );
      },
    );
  }

  Padding _buildTh(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary)),
    );
  }

  TableRow _buildTr(Delivery delivery) {
    final date = delivery.receivedAt ?? delivery.scheduledAt ?? delivery.createdAt;
    final dateStr = '${_monthName(date.month)} ${date.day.toString().padLeft(2, '0')}';

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5)),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(delivery.supplierName, style: BaycelTypography.body.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(dateStr, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text('${delivery.items.length}', style: BaycelTypography.body.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(delivery.receivedBy ?? '—', style: BaycelTypography.body.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: _buildStatusPill(delivery),
        ),
      ],
    );
  }

  Widget _buildStatusPill(Delivery delivery) {
    String label;
    Color color;

    switch (delivery.status) {
      case DeliveryStatus.delivered:
        label = 'Verified';
        color = BaycelColors.success;
        break;
      case DeliveryStatus.pending:
        label = 'Pending';
        color = BaycelColors.marigold;
        break;
      case DeliveryStatus.discrepancy:
        final short = delivery.items
            .where((i) => i.receivedQuantity < i.expectedQuantity)
            .fold<int>(0, (acc, i) => acc + (i.expectedQuantity - i.receivedQuantity));
        label = short > 0 ? '$short short' : 'Discrepancy';
        color = BaycelColors.error;
        break;
      case DeliveryStatus.inTransit:
        label = 'In Transit';
        color = BaycelColors.blue;
        break;
      case DeliveryStatus.cancelled:
        label = 'Cancelled';
        color = BaycelColors.textMuted;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: BaycelSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BaycelRadius.full),
      ),
      child: Text(
        label,
        style: BaycelTypography.labelSm.copyWith(color: color, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

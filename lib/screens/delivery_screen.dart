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
      child: StreamBuilder<List<Delivery>>(
        stream: _firestore.getDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deliveries', style: BaycelTypography.display),
                SizedBox(height: BaycelSpacing.xxs),
                Text('Loading...', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5)),
                SizedBox(height: BaycelSpacing.lg),
                const Expanded(child: Center(child: SkeletonTable(rows: 6))),
              ],
            );
          }

          final deliveries = snapshot.data ?? [];
          final count = deliveries.length;
          final filtered = _selectedFilter == null
              ? deliveries
              : deliveries.where((d) => d.status == _selectedFilter).toList();
          final counts = {
            null: deliveries.length,
            DeliveryStatus.delivered: deliveries.where((d) => d.status == DeliveryStatus.delivered).length,
            DeliveryStatus.pending: deliveries.where((d) => d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).length,
            DeliveryStatus.discrepancy: deliveries.where((d) => d.status == DeliveryStatus.discrepancy).length,
          };
          final filters = [
            (label: 'All', status: null),
            (label: 'Verified', status: DeliveryStatus.delivered),
            (label: 'Pending', status: DeliveryStatus.pending),
            (label: 'Discrepancy', status: DeliveryStatus.discrepancy),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredItem(index: 0, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deliveries', style: BaycelTypography.display),
                  SizedBox(height: BaycelSpacing.xxs),
                  Text('$count deliveries logged',
                    style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5)),
                ],
              )),
              SizedBox(height: BaycelSpacing.lg),
              StaggeredItem(index: 1, child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((filter) {
                    final isSelected = _selectedFilter == filter.status;
                    final c = counts[filter.status] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(right: BaycelSpacing.sm),
                      child: ChoiceChip(
                        label: Text('${filter.label} ($c)', style: BaycelTypography.labelSm.copyWith(
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
              )),
              SizedBox(height: BaycelSpacing.lg),
              Expanded(
                child: StaggeredItem(
                  index: 2,
                  child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: BaycelSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 40, color: BaycelColors.textDisabled),
                              SizedBox(height: BaycelSpacing.sm),
                              Text('No deliveries found', style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted)),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BaycelComponents.card,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: constraints.maxWidth < 900 ? 900 : constraints.maxWidth,
                                        child: Table(
                                          columnWidths: const {
                                            0: FlexColumnWidth(3),
                                            1: FlexColumnWidth(2),
                                            2: FlexColumnWidth(1.5),
                                            3: FlexColumnWidth(2.5),
                                            4: FlexColumnWidth(2.5),
                                            5: FlexColumnWidth(2),
                                          },
                                          children: [
                                            TableRow(
                                              decoration: BoxDecoration(
                                                color: BaycelColors.surface,
                                                border: Border(bottom: BorderSide(color: BaycelColors.divider, width: 1)),
                                              ),
                                              children: [
                                                _buildTh('SUPPLIER'),
                                                _buildTh('DATE'),
                                                _buildTh('ITEMS'),
                                                _buildTh('RECEIVED BY'),
                                                _buildTh('STATUS'),
                                                _buildTh('ACTIONS'),
                                              ],
                                            ),
                                            ...filtered.map((d) => _buildTr(d)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: BaycelSpacing.sm),
                              alignment: Alignment.center,
                              child: Text('${filtered.length} of $count deliveries',
                                style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textDisabled, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Padding _buildTh(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.03)),
    );
  }

  TableRow _buildTr(Delivery delivery) {
    final date = delivery.receivedAt ?? delivery.scheduledAt ?? delivery.createdAt;
    final dateStr = '${_monthName(date.month)} ${date.day.toString().padLeft(2, '0')}';
    final canManage = _userRole == 'owner' || _userRole == 'manager';
    final isPending = delivery.status == DeliveryStatus.pending || delivery.status == DeliveryStatus.inTransit;

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
          child: Builder(builder: (context) {
            final short = delivery.status == DeliveryStatus.discrepancy
                ? delivery.items.where((i) => i.receivedQuantity < i.expectedQuantity)
                    .fold<int>(0, (acc, i) => acc + (i.expectedQuantity - i.receivedQuantity))
                : 0;
            return DeliveryStatusPill(
              status: delivery.status,
              overrideLabel: short > 0 ? '$short short' : null,
            );
          }),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 6),
          child: canManage && isPending
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () => _acceptDelivery(delivery),
                          style: BaycelComponents.buttonPrimary.copyWith(
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                          ),
                          child: Text('Accept', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: () => _reportDiscrepancy(delivery),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(color: BaycelColors.divider),
                          ),
                          child: Text('Issue', style: TextStyle(fontSize: 11, color: BaycelColors.textSecondary)),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _acceptDelivery(Delivery delivery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Accept Delivery'),
        content: Text('Mark delivery from ${delivery.supplierName} as received?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: BaycelComponents.buttonPrimary,
            child: Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final updatedItems = delivery.items.map((item) => DeliveryItem(
        productId: item.productId,
        productName: item.productName,
        expectedQuantity: item.expectedQuantity,
        receivedQuantity: item.expectedQuantity,
      )).toList();
      await _firestore.updateDelivery(delivery.id, {
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'status': 'delivered',
        'checkedBy': FirebaseAuth.instance.currentUser?.uid,
        'receivedBy': FirebaseAuth.instance.currentUser?.uid,
        'receivedAt': DateTime.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${delivery.supplierName} marked as received')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update delivery'), backgroundColor: BaycelColors.error),
      );
    }
  }

  void _reportDiscrepancy(Delivery delivery) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report Discrepancy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Report issue with delivery from ${delivery.supplierName}?'),
            SizedBox(height: BaycelSpacing.md),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: BaycelTypography.body.copyWith(fontSize: 13),
              decoration: BaycelComponents.input.copyWith(
                hintText: 'Describe the issue...',
                filled: true, fillColor: BaycelColors.card),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: BaycelColors.marigoldDark),
            child: Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _firestore.updateDelivery(delivery.id, {
        'status': 'discrepancy',
        'checkedBy': FirebaseAuth.instance.currentUser?.uid,
        'receivedBy': FirebaseAuth.instance.currentUser?.uid,
        'receivedAt': DateTime.now(),
        'note': noteController.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Discrepancy reported for ${delivery.supplierName}')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report discrepancy'), backgroundColor: BaycelColors.error),
      );
    }
  }
}

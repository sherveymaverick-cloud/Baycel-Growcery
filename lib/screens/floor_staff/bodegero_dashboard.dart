import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../widgets/floor_staff_shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../models/delivery.dart';
import '../../models/stock_movement.dart';

class BodegeroDashboard extends StatelessWidget {
  final FirestoreService firestore;
  final Stream<List<Delivery>> deliveriesStream;
  final Stream<List<StockMovement>> stockMovementsStream;
  final Stream<List<Product>> productsStream;
  final void Function(String deliveryId) onConfirmDelivery;
  final void Function(String productName, int quantity) onStockOut;

  const BodegeroDashboard({
    super.key,
    required this.firestore,
    required this.deliveriesStream,
    required this.stockMovementsStream,
    required this.productsStream,
    required this.onConfirmDelivery,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BodegeroSummaryCard(firestore: firestore),
        SizedBox(height: BaycelSpacing.md),
        StockLevelsCard(
          productsStream: productsStream,
          onProductTap: (productName) => _showStockOutDialog(context, productName),
        ),
        SizedBox(height: BaycelSpacing.md),
        _PendingDeliveryCard(firestore: firestore, onConfirmDelivery: onConfirmDelivery),
        SizedBox(height: BaycelSpacing.md),
        StockOutCard(productsStream: productsStream, onSubmit: onStockOut),
        SizedBox(height: BaycelSpacing.md),
        _RecentTransfersCard(stockMovementsStream: stockMovementsStream),
      ],
    );
  }

  void _showStockOutDialog(BuildContext context, String productName) {
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
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > 0) {
                onStockOut(productName, qty);
              }
              Navigator.pop(ctx);
            },
            style: BaycelComponents.buttonPrimary,
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BodegeroSummaryCard extends StatelessWidget {
  final FirestoreService firestore;

  const _BodegeroSummaryCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Delivery>>(
      stream: firestore.getDeliveries(),
      builder: (context, deliverySnap) {
        final deliveries = deliverySnap.data ?? [];
        final pending = deliveries.where((d) =>
          d.status == DeliveryStatus.pending || d.status == DeliveryStatus.inTransit).toList();
        final pendingName = pending.isNotEmpty ? pending.first.supplierName : '';

        return StreamBuilder<List<StockMovement>>(
          stream: firestore.getStockMovements(),
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
                    buildSummaryRow(
                      Icons.local_shipping_outlined,
                      '${pending.length} delivery awaiting stock-in',
                      pendingName,
                      pillLabel: 'Pending',
                      pillColor: BaycelColors.marigoldDark,
                    ),
                  if (todayTransfers > 0)
                    buildSummaryRow(
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
                          Icon(Icons.local_shipping_outlined, size: 32, color: BaycelColors.textDisabled),
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
}

class _PendingDeliveryCard extends StatelessWidget {
  final FirestoreService firestore;
  final void Function(String deliveryId) onConfirmDelivery;

  const _PendingDeliveryCard({required this.firestore, required this.onConfirmDelivery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Delivery>>(
      stream: firestore.getDeliveries(),
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
                      Icon(Icons.local_shipping_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No pending deliveries', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...pending.map((d) => InkWell(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Confirm Stock-In'),
                        content: Text('Mark delivery from ${d.supplierName} as received?'),
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
                    onConfirmDelivery(d.id);
                  },
                  borderRadius: BorderRadius.circular(BaycelRadius.md),
                  child: Container(
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
                              Text('${d.items.length} products', style: BaycelTypography.labelSm.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
                            ],
                          ),
                        ),
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

class _RecentTransfersCard extends StatelessWidget {
  final Stream<List<StockMovement>> stockMovementsStream;

  const _RecentTransfersCard({required this.stockMovementsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockMovement>>(
      stream: stockMovementsStream,
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
                      Icon(Icons.swap_horiz, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No transfers yet', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...transfers.map((m) => buildMovementRow(
                  '${m.productName} \u00b7 \u2212${m.quantity}',
                  '${m.createdAt.month}/${m.createdAt.day}',
                )),
            ],
          ),
        );
      },
    );
  }
}

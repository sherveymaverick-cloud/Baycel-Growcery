import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/floor_staff_helpers.dart';
import '../../widgets/floor_staff_shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../models/user.dart';

class MerchandiserDashboard extends StatelessWidget {
  final FirestoreService firestore;
  final StoreUser? currentUser;
  final Stream<List<Product>> productsStream;
  final Stream<List<StockMovement>> stockMovementsStream;
  final void Function(String productName, int quantity) onStockOut;

  const MerchandiserDashboard({
    super.key,
    required this.firestore,
    required this.currentUser,
    required this.productsStream,
    required this.stockMovementsStream,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MerchandiserSummaryCard(
          firestore: firestore,
          currentUser: currentUser,
        ),
        SizedBox(height: BaycelSpacing.md),
        StockLevelsCard(
          productsStream: productsStream,
          onProductTap: (productName) => _showStockOutDialog(context, productName),
        ),
        SizedBox(height: BaycelSpacing.md),
        StockOutCard(productsStream: productsStream, onSubmit: onStockOut),
        SizedBox(height: BaycelSpacing.md),
        _AssignedProductsCard(
          currentUser: currentUser,
          productsStream: productsStream,
          onStockOut: (productName) => _showStockOutDialog(context, productName),
        ),
        SizedBox(height: BaycelSpacing.md),
        _StockMovementsCard(stockMovementsStream: stockMovementsStream),
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

class _MerchandiserSummaryCard extends StatelessWidget {
  final FirestoreService firestore;
  final StoreUser? currentUser;

  const _MerchandiserSummaryCard({required this.firestore, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: firestore.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final assignedIds = currentUser?.assignedProducts ?? [];
        final assigned = assignedIds.isEmpty ? products.take(3).toList() : products.where((p) => assignedIds.contains(p.id)).toList();

        return Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BaycelComponents.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Summary", style: BaycelTypography.title),
              SizedBox(height: BaycelSpacing.sm),
              buildSummaryRow(
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
}

class _AssignedProductsCard extends StatelessWidget {
  final StoreUser? currentUser;
  final Stream<List<Product>> productsStream;
  final void Function(String productName) onStockOut;

  const _AssignedProductsCard({
    required this.currentUser,
    required this.productsStream,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    final assignedIds = currentUser?.assignedProducts ?? [];

    return StreamBuilder<List<Product>>(
      stream: productsStream,
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
                      Icon(Icons.inventory_2_outlined, size: 32, color: BaycelColors.textDisabled),
                      SizedBox(height: BaycelSpacing.sm),
                      Text('No products assigned', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled)),
                    ],
                  ),
                ))
              else
                ...assigned.map((p) => buildProductStockOutRow(p.name, '${p.stockQuantity} ${p.unit} on shelf', onTap: () => onStockOut(p.name))),
            ],
          ),
        );
      },
    );
  }
}

class _StockMovementsCard extends StatelessWidget {
  final Stream<List<StockMovement>> stockMovementsStream;

  const _StockMovementsCard({required this.stockMovementsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockMovement>>(
      stream: stockMovementsStream,
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
                      Icon(Icons.swap_horiz, size: 32, color: BaycelColors.textDisabled),
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
                  return buildMovementRow(
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
}

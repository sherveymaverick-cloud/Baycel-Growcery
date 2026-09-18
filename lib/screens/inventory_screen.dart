import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  final _firestore = FirestoreService();

  final List<String> _categories = [
    'All',
    'Groceries & Canned',
    'Beverages',
    'Frozen & Dairy',
    'Snacks',
    'Household',
  ];

  List<Product> _filterProducts(List<Product> products) {
    if (_selectedCategory == 'All') return products;
    return products.where((p) => p.category == _selectedCategory).toList();
  }

  String _status(Product product) {
    if (product.stockQuantity <= 0) return 'Out of Stock';
    if (product.stockQuantity <= product.reorderLevel) return 'Low Stock';
    return 'In Stock';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In Stock':
        return BaycelColors.success;
      case 'Low Stock':
        return BaycelColors.marigoldDark;
      case 'Out of Stock':
        return BaycelColors.error;
      default:
        return BaycelColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(BaycelSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: BaycelSpacing.lg),
          _buildCategoryChips(),
          SizedBox(height: BaycelSpacing.lg),
          _buildInventoryTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final lowStock = products.where((p) => p.stockQuantity <= p.reorderLevel).length;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory', style: BaycelTypography.display),
                  SizedBox(height: BaycelSpacing.xxs),
                  Text('${products.length} products \u00b7 $lowStock need reordering',
                    style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary, fontSize: 12.5),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(width: BaycelSpacing.md),
            ElevatedButton.icon(
              style: BaycelComponents.buttonPrimary,
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final barcodeController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final reorderController = TextEditingController();
    String category = 'Groceries & Canned';
    String unit = 'pcs';

    InputDecoration _fieldDeco(String hint) => BaycelComponents.input.copyWith(
      hintText: hint,
      filled: true,
      fillColor: BaycelColors.card,
      contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 12),
    );

    Widget _label(String text, {bool required = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: BaycelSpacing.xs),
        child: Row(
          children: [
            Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
            if (required) ...[
              SizedBox(width: 3),
              Text('*', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontSize: 12)),
            ],
          ],
        ),
      );
    }

    Widget _sectionTitle(String text) {
      return Padding(
        padding: EdgeInsets.only(top: BaycelSpacing.md, bottom: BaycelSpacing.sm),
        child: Text(text, style: BaycelTypography.labelSm.copyWith(
          color: BaycelColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.05)),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Product', style: BaycelTypography.title),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Basic Info'),
                _label('Product Name', required: true),
                TextField(controller: nameController, decoration: _fieldDeco('e.g. Campbell Soup')),
                SizedBox(height: BaycelSpacing.md),
                _label('SKU'),
                TextField(controller: skuController, decoration: _fieldDeco('e.g. CS-001')),
                SizedBox(height: BaycelSpacing.md),
                _label('Barcode'),
                TextField(controller: barcodeController, decoration: _fieldDeco('e.g. 4800000000012')),
                SizedBox(height: BaycelSpacing.md),
                _label('Category'),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _fieldDeco(''),
                  style: BaycelTypography.body.copyWith(fontSize: 13),
                  items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v ?? category,
                ),
                _sectionTitle('Stock Settings'),
                _label('Price'),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: _fieldDeco('0.00')),
                SizedBox(height: BaycelSpacing.md),
                _label('Stock Quantity'),
                TextField(controller: stockController, keyboardType: TextInputType.number, decoration: _fieldDeco('0')),
                SizedBox(height: BaycelSpacing.md),
                _label('Reorder Level'),
                TextField(controller: reorderController, keyboardType: TextInputType.number, decoration: _fieldDeco('0')),
                SizedBox(height: BaycelSpacing.md),
                _label('Unit'),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: _fieldDeco(''),
                  style: BaycelTypography.body.copyWith(fontSize: 13),
                  items: ['pcs', 'kg', 'L', 'pack', 'box'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => unit = v ?? unit,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
          ),
          SizedBox(width: BaycelSpacing.sm),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter product name')));
                return;
              }
              try {
                final product = Product(
                  id: '',
                  name: nameController.text.trim(),
                  sku: skuController.text.trim(),
                  barcode: barcodeController.text.trim(),
                  category: category,
                  price: double.tryParse(priceController.text) ?? 0,
                  stockQuantity: int.tryParse(stockController.text) ?? 0,
                  reorderLevel: int.tryParse(reorderController.text) ?? 0,
                  unit: unit,
                  isActive: true,
                );
                await _firestore.addProduct(product);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to add product. Please try again.'), backgroundColor: BaycelColors.error),
                  );
                }
              }
            },
            style: BaycelComponents.buttonPrimary,
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: EdgeInsets.only(right: BaycelSpacing.sm),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              selectedColor: BaycelColors.crimson,
              backgroundColor: BaycelColors.card,
              labelStyle: BaycelTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : BaycelColors.textPrimary,
              ),
              side: BorderSide(
                color: isSelected ? BaycelColors.crimson : BaycelColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BaycelRadius.full),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: BaycelSpacing.md,
                vertical: BaycelSpacing.xs,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInventoryTable() {
    return StreamBuilder<List<Product>>(
      stream: _firestore.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(BaycelSpacing.xxl),
              child: SkeletonTable(rows: 8),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading inventory',
              style: BaycelTypography.body.copyWith(color: BaycelColors.error),
            ),
          );
        }

        final products = _filterProducts(snapshot.data ?? []);

        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(BaycelSpacing.xxl),
              child: Text(
                'No products found',
                style: BaycelTypography.body.copyWith(color: BaycelColors.textMuted),
              ),
            ),
          );
        }

        return StaggeredItem(
          index: 0,
          child: Container(
            decoration: BaycelComponents.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(BaycelSpacing.lg),
                  child: Row(
                    children: [
                      Text('Products', style: BaycelTypography.headlineMd),
                      SizedBox(width: BaycelSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: BaycelSpacing.sm,
                          vertical: BaycelSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: BaycelColors.surface,
                          borderRadius: BorderRadius.circular(BaycelRadius.full),
                        ),
                        child: Text(
                          '${products.length}',
                          style: BaycelTypography.labelSm.copyWith(
                            color: BaycelColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: BaycelColors.divider),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(2),
                            5: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: BaycelColors.surface),
                              children: [
                                _buildTh('PRODUCT'),
                                _buildTh('SKU'),
                                _buildTh('CATEGORY'),
                                _buildTh('STOCK'),
                                _buildTh('UNIT PRICE'),
                                _buildTh('STATUS'),
                              ],
                            ),
                            ...products.map((product) => _buildTr(product)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTh(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: BaycelSpacing.sm),
      child: Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, letterSpacing: 0.03)),
    );
  }

  TableRow _buildTr(Product product) {
    final status = _status(product);
    final statusColor = _statusColor(status);
    final border = Border(bottom: BorderSide(color: BaycelColors.divider.withValues(alpha: 0.5), width: 0.5));

    return TableRow(
      decoration: BoxDecoration(border: border),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(product.name, style: BaycelTypography.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(product.sku, style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text(product.category, style: BaycelTypography.bodySm.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text('${product.stockQuantity}', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Text('\u20B1${product.price.toStringAsFixed(2)}', style: BaycelTypography.dataMono.copyWith(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: BaycelSpacing.sm,
              vertical: BaycelSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BaycelRadius.full),
            ),
            child: Text(
              status,
              style: BaycelTypography.labelSm.copyWith(
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

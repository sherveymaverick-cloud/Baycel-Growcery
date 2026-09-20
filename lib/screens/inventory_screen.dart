import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  final String? role;
  const InventoryScreen({super.key, this.role});

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
            if (widget.role == 'owner' || widget.role == 'manager')
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
      fillColor: BaycelColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BaycelRadius.md),
        borderSide: BorderSide(color: BaycelColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BaycelRadius.md),
        borderSide: BorderSide(color: BaycelColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BaycelRadius.md),
        borderSide: BorderSide(color: BaycelColors.crimson),
      ),
    );

    Widget _label(String text, {bool required = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: BaycelSpacing.xs),
        child: Row(
          children: [
            Text(text, style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
            if (required) ...[
              SizedBox(width: 3),
              Text('*', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson, fontSize: 12)),
            ],
          ],
        ),
      );
    }

    Widget _sectionTitle(String text) {
      return Padding(
        padding: EdgeInsets.only(top: BaycelSpacing.md, bottom: BaycelSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 3, height: 14,
              decoration: BoxDecoration(
                color: BaycelColors.crimson,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: BaycelSpacing.sm),
            Text(text, style: BaycelTypography.labelSm.copyWith(
              color: BaycelColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BaycelColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BaycelRadius.md),
              ),
              child: Icon(Icons.inventory_2_outlined, color: BaycelColors.crimson, size: 20),
            ),
            SizedBox(width: BaycelSpacing.sm),
            Text('Add Product', style: BaycelTypography.headlineMd),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Basic Info'),
                _label('Product Name', required: true),
                TextField(controller: nameController, decoration: _fieldDeco('e.g. Campbell Soup')),
                SizedBox(height: BaycelSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('SKU'),
                          TextField(controller: skuController, decoration: _fieldDeco('e.g. CS-001')),
                        ],
                      ),
                    ),
                    SizedBox(width: BaycelSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Barcode'),
                          TextField(controller: barcodeController, decoration: _fieldDeco('e.g. 4800012')),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: BaycelSpacing.md),
                _label('Category'),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _fieldDeco(''),
                  style: BaycelTypography.body.copyWith(fontSize: 13),
                  items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v ?? category,
                ),
                _sectionTitle('Stock & Pricing'),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Price (\u20B1)'),
                          TextField(controller: priceController, keyboardType: TextInputType.number, decoration: _fieldDeco('0.00')),
                        ],
                      ),
                    ),
                    SizedBox(width: BaycelSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  ],
                ),
                SizedBox(height: BaycelSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Stock Qty'),
                          TextField(controller: stockController, keyboardType: TextInputType.number, decoration: _fieldDeco('0')),
                        ],
                      ),
                    ),
                    SizedBox(width: BaycelSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Reorder Level'),
                          TextField(controller: reorderController, keyboardType: TextInputType.number, decoration: _fieldDeco('0')),
                        ],
                      ),
                    ),
                  ],
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
          ElevatedButton.icon(
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
                  _showSuccessDialog('Product Added', '${product.name} has been added to inventory.');
                }
              } catch (e) {
                if (ctx.mounted) {
                  _showErrorDialog('Failed', 'Unable to add product. Please try again.');
                }
              }
            },
            style: BaycelComponents.buttonPrimary.copyWith(
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10)),
            ),
            icon: Icon(Icons.add, size: 16, color: Colors.white),
            label: Text('Add Product', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BaycelColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: BaycelColors.success, size: 48),
            ),
            SizedBox(height: BaycelSpacing.md),
            Text(title, style: BaycelTypography.headlineMd, textAlign: TextAlign.center),
            SizedBox(height: BaycelSpacing.sm),
            Text(message, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: BaycelComponents.buttonPrimary,
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BaycelColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: BaycelColors.error, size: 48),
            ),
            SizedBox(height: BaycelSpacing.md),
            Text(title, style: BaycelTypography.headlineMd, textAlign: TextAlign.center),
            SizedBox(height: BaycelSpacing.sm),
            Text(message, style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: BaycelComponents.buttonPrimary.copyWith(
                backgroundColor: WidgetStatePropertyAll(BaycelColors.error),
              ),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
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

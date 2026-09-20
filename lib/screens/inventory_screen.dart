import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class InventoryScreen extends StatefulWidget {
  final String? role;
  const InventoryScreen({super.key, this.role});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  final _firestore = FirestoreService();
  final _db = FirebaseFirestore.instance;

  List<Product> _products = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);
    Query query = _db.collection('products').orderBy('name').limit(20);
    final snap = await query.get();
    setState(() {
      _products = snap.docs.map((d) => Product.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length >= 20;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_lastDoc == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    Query query = _db.collection('products').orderBy('name').startAfterDocument(_lastDoc!).limit(20);
    final snap = await query.get();
    setState(() {
      _products.addAll(snap.docs.map((d) => Product.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
      _hasMore = snap.docs.length >= 20;
      _isLoadingMore = false;
    });
  }

  Future<void> _loadProductsByCategory(String category) async {
    setState(() { _isLoading = true; _products = []; _hasMore = true; });
    Query query = _db.collection('products').where('category', isEqualTo: category).orderBy('name').limit(20);
    final snap = await query.get();
    setState(() {
      _products = snap.docs.map((d) => Product.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length >= 20;
      _isLoading = false;
    });
  }

  final List<String> _categories = [
    'All',
    'Canned Goods',
    'Beverages',
    'Rice & Grains',
    'Flour & Sugar',
    'Cooking Oil & Condiments',
    'Dairy & Eggs',
    'Frozen Foods',
    'Bread & Bakery',
    'Snacks',
    'Cleaning',
    'Personal Care',
    'Baby Products',
    'Other',
  ];

  bool get _canStockOut => widget.role == 'bodegero' || widget.role == 'merchandiser';
  bool get _canStockIn => widget.role == 'bodegero' || widget.role == 'delivery_checker';
  bool get _canManage => widget.role == 'owner' || widget.role == 'manager';

  void _showStockOutDialog(Product product) {
    int qty = 1;
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Stock Out: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current stock: ${product.stockQuantity} ${product.unit}', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
              SizedBox(height: BaycelSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (qty > 1) { qty--; qtyController.text = qty.toString(); setDialogState(() {}); }
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: BaycelColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Icon(Icons.remove, size: 18, color: BaycelColors.error),
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.md),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: BaycelTypography.dataMono.copyWith(fontSize: 18),
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                      onChanged: (v) { final p = int.tryParse(v); if (p != null && p > 0) qty = p; },
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.md),
                  GestureDetector(
                    onTap: () { qty++; qtyController.text = qty.toString(); setDialogState(() {}); },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: BaycelColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Icon(Icons.add, size: 18, color: BaycelColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final finalQty = int.tryParse(qtyController.text) ?? 0;
                if (finalQty <= 0 || finalQty > product.stockQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid quantity'), backgroundColor: BaycelColors.error));
                  return;
                }
                final newBalance = product.stockQuantity - finalQty;
                await _firestore.updateProduct(product.id, {'stockQuantity': newBalance});
                await _firestore.addStockMovement(StockMovement(
                  id: '', productId: product.id, productName: product.name,
                  type: StockMovementType.stockOut, quantity: finalQty, balanceAfter: newBalance,
                  performedBy: FirebaseAuth.instance.currentUser?.uid ?? '', createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock-out recorded')));
              },
              style: BaycelComponents.buttonPrimary,
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockInDialog(Product product) {
    int qty = 1;
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Stock In: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current stock: ${product.stockQuantity} ${product.unit}', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
              SizedBox(height: BaycelSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (qty > 1) { qty--; qtyController.text = qty.toString(); setDialogState(() {}); }
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: BaycelColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Icon(Icons.remove, size: 18, color: BaycelColors.error),
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.md),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: BaycelTypography.dataMono.copyWith(fontSize: 18),
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                      onChanged: (v) { final p = int.tryParse(v); if (p != null && p > 0) qty = p; },
                    ),
                  ),
                  SizedBox(width: BaycelSpacing.md),
                  GestureDetector(
                    onTap: () { qty++; qtyController.text = qty.toString(); setDialogState(() {}); },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: BaycelColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Icon(Icons.add, size: 18, color: BaycelColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final finalQty = int.tryParse(qtyController.text) ?? 0;
                if (finalQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid quantity'), backgroundColor: BaycelColors.error));
                  return;
                }
                final newBalance = product.stockQuantity + finalQty;
                await _firestore.updateProduct(product.id, {'stockQuantity': newBalance});
                await _firestore.addStockMovement(StockMovement(
                  id: '', productId: product.id, productName: product.name,
                  type: StockMovementType.stockIn, quantity: finalQty, balanceAfter: newBalance,
                  performedBy: FirebaseAuth.instance.currentUser?.uid ?? '', createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock-in recorded')));
              },
              style: BaycelComponents.buttonPrimary,
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku);
    final barcodeController = TextEditingController(text: product.barcode);
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));
    final stockController = TextEditingController(text: product.stockQuantity.toString());
    final reorderController = TextEditingController(text: product.reorderLevel.toString());
    String category = product.category;
    String unit = product.unit;
    final formKey = GlobalKey<FormState>();

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaycelRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BaycelColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BaycelRadius.md),
              ),
              child: Icon(Icons.edit_outlined, color: BaycelColors.blue, size: 20),
            ),
            SizedBox(width: BaycelSpacing.sm),
            Text('Edit Product', style: BaycelTypography.headlineMd),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product Name', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                  SizedBox(height: BaycelSpacing.xs),
                  TextFormField(
                    controller: nameController,
                    decoration: _fieldDeco('Product name'),
                    maxLength: 100,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Product name is required';
                      if (v.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SKU', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                            SizedBox(height: BaycelSpacing.xs),
                            TextFormField(controller: skuController, decoration: _fieldDeco('SKU'), maxLength: 30),
                          ],
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Barcode', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                            SizedBox(height: BaycelSpacing.xs),
                            TextFormField(controller: barcodeController, decoration: _fieldDeco('Barcode'), maxLength: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Text('Category', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                  SizedBox(height: BaycelSpacing.xs),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: _fieldDeco(''),
                    style: BaycelTypography.body.copyWith(fontSize: 13),
                    items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => category = v ?? category,
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price (\u20B1)', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                            SizedBox(height: BaycelSpacing.xs),
                            TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDeco('0.00'),
                              maxLength: 10,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Price is required';
                                final price = double.tryParse(v);
                                if (price == null) return 'Enter a valid number';
                                if (price < 0) return 'Price cannot be negative';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unit', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                            SizedBox(height: BaycelSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: unit,
                              decoration: _fieldDeco(''),
                              style: BaycelTypography.body.copyWith(fontSize: 13),
                              items: ['box', 'case', 'pack', 'sack', 'kg', 'L', 'bottle', 'carton', 'roll', 'dozen'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
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
                            Text('Stock Qty', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                            SizedBox(height: BaycelSpacing.xs),
                            TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDeco('0'),
                              maxLength: 10,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final qty = int.tryParse(v);
                                if (qty == null) return 'Enter a whole number';
                                if (qty < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reorder Level', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.textSecondary, fontSize: 12)),
                            SizedBox(height: BaycelSpacing.xs),
                            TextFormField(
                              controller: reorderController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDeco('0'),
                              maxLength: 10,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final lvl = int.tryParse(v);
                                if (lvl == null) return 'Enter a whole number';
                                if (lvl < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              if (!formKey.currentState!.validate()) return;
              try {
                await _firestore.updateProduct(product.id, {
                  'name': nameController.text.trim(),
                  'sku': skuController.text.trim(),
                  'barcode': barcodeController.text.trim(),
                  'category': category,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'stockQuantity': int.tryParse(stockController.text) ?? 0,
                  'reorderLevel': int.tryParse(reorderController.text) ?? 0,
                  'unit': unit,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _showSuccessDialog('Product Updated', '${nameController.text.trim()} has been updated.');
                  _loadInitialProducts();
                }
              } catch (e) {
                if (ctx.mounted) {
                  _showErrorDialog('Failed', 'Unable to update product. Please try again.');
                }
              }
            },
            style: BaycelComponents.buttonPrimary.copyWith(
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10)),
            ),
            icon: Icon(Icons.check, size: 16, color: Colors.white),
            label: Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
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
              child: Icon(Icons.delete_outline, color: BaycelColors.error, size: 48),
            ),
            SizedBox(height: BaycelSpacing.md),
            Text('Delete Product', style: BaycelTypography.headlineMd, textAlign: TextAlign.center),
            SizedBox(height: BaycelSpacing.sm),
            Text(
              'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
          ),
          SizedBox(width: BaycelSpacing.sm),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await _firestore.deleteProduct(product.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _showSuccessDialog('Product Deleted', '${product.name} has been removed from inventory.');
                  _loadInitialProducts();
                }
              } catch (e) {
                if (ctx.mounted) {
                  _showErrorDialog('Failed', 'Unable to delete product. Please try again.');
                }
              }
            },
            style: BaycelComponents.buttonPrimary.copyWith(
              backgroundColor: WidgetStatePropertyAll(BaycelColors.error),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: BaycelSpacing.base, vertical: 10)),
            ),
            icon: Icon(Icons.delete, size: 16, color: Colors.white),
            label: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    String category = 'Canned Goods';
    String unit = 'box';
    final formKey = GlobalKey<FormState>();

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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Basic Info'),
                  _label('Product Name', required: true),
                  TextFormField(
                    controller: nameController,
                    decoration: _fieldDeco('e.g. Campbell Soup'),
                    maxLength: 100,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Product name is required';
                      if (v.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: BaycelSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('SKU'),
                            TextFormField(
                              controller: skuController,
                              decoration: _fieldDeco('e.g. CS-001'),
                              maxLength: 30,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Barcode'),
                            TextFormField(
                              controller: barcodeController,
                              decoration: _fieldDeco('e.g. 4800012'),
                              maxLength: 30,
                            ),
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
                            TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDeco('0.00'),
                              maxLength: 10,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Price is required';
                                final price = double.tryParse(v);
                                if (price == null) return 'Enter a valid number';
                                if (price < 0) return 'Price cannot be negative';
                                return null;
                              },
                            ),
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
                              items: ['box', 'case', 'pack', 'sack', 'kg', 'L', 'bottle', 'carton', 'roll', 'dozen'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
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
                            TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDeco('0'),
                              maxLength: 10,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final qty = int.tryParse(v);
                                if (qty == null) return 'Enter a whole number';
                                if (qty < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: BaycelSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Reorder Level'),
                            TextFormField(
                              controller: reorderController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDeco('0'),
                              maxLength: 10,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final lvl = int.tryParse(v);
                                if (lvl == null) return 'Enter a whole number';
                                if (lvl < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              if (!formKey.currentState!.validate()) return;
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
                if (cat == 'All') {
                  _loadInitialProducts();
                } else {
                  _loadProductsByCategory(cat);
                }
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(BaycelSpacing.xxl),
          child: SkeletonTable(rows: 8),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(BaycelSpacing.xxl),
          child: Text(
            'No data',
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
                      '${_products.length}',
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
                      columnWidths: {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(2),
                        5: FlexColumnWidth(2),
                        if (_canStockIn || _canStockOut || _canManage) 6: FlexColumnWidth(2),
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
                            if (_canStockIn || _canStockOut || _canManage) _buildTh('ACTIONS'),
                          ],
                        ),
                        ..._products.map((product) => _buildTr(product)),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_hasMore)
              Padding(
                padding: EdgeInsets.symmetric(vertical: BaycelSpacing.base),
                child: Center(
                  child: _isLoadingMore
                      ? SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: BaycelColors.crimson),
                        )
                      : GestureDetector(
                          onTap: _loadMoreProducts,
                          child: Text('Load More',
                            style: BaycelTypography.bodySm.copyWith(
                              color: BaycelColors.crimson, fontWeight: FontWeight.w600)),
                        ),
                ),
              ),
          ],
        ),
      ),
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
        if (_canStockIn || _canStockOut || _canManage)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: BaycelSpacing.sm, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_canManage)
                  GestureDetector(
                    onTap: () => _showEditProductDialog(product),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BaycelColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Text('Edit', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.blue, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ),
                if (_canManage) SizedBox(width: 4),
                if (_canManage)
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(product),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BaycelColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Text('Delete', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ),
                if (_canManage && (_canStockIn || _canStockOut)) SizedBox(width: 4),
                if (_canStockIn)
                  GestureDetector(
                    onTap: () => _showStockInDialog(product),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BaycelColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Text('Stock In', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.success, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ),
                if (_canStockIn && _canStockOut) SizedBox(width: 4),
                if (_canStockOut)
                  GestureDetector(
                    onTap: () => _showStockOutDialog(product),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BaycelColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BaycelRadius.sm)),
                      child: Text('Stock Out', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.error, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

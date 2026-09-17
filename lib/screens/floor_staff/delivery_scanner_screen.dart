import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';

class ParsedItem {
  String name;
  int quantity;
  Product? matchedProduct;

  ParsedItem({required this.name, required this.quantity, this.matchedProduct});
}

class DeliveryScannerScreen extends StatefulWidget {
  const DeliveryScannerScreen({super.key});

  @override
  State<DeliveryScannerScreen> createState() => _DeliveryScannerScreenState();
}

class _DeliveryScannerScreenState extends State<DeliveryScannerScreen> {
  final _firestore = FirestoreService();
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;
  List<ParsedItem> _parsedItems = [];
  String? _rawText;
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _firestore.getProducts().first;
    setState(() => _allProducts = products);
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xfile == null) return;

      setState(() {
        _isProcessing = true;
        _parsedItems = [];
        _rawText = null;
      });

      try {
        final inputImage = InputImage.fromFilePath(xfile.path);
        final recognized = await _textRecognizer.processImage(inputImage);
        final text = recognized.text;

        setState(() => _rawText = text);

        final items = _parseText(text);
        await _matchProducts(items);

        setState(() {
          _parsedItems = items;
          _isProcessing = false;
        });
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to process image: $e'), backgroundColor: BaycelColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera. Please check camera permissions.'),
            backgroundColor: BaycelColors.error,
          ),
        );
      }
    }
  }

  List<ParsedItem> _parseText(String text) {
    final lines = text.split(RegExp(r'[\n\r]+')).where((l) => l.trim().isNotEmpty).toList();
    final items = <ParsedItem>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip header-like lines
      if (_isHeaderLine(trimmed)) continue;

      String name = trimmed;
      int qty = 1;

      // Pattern 1: "name x qty" or "name × qty" or "name X qty"
      final matchXQty = RegExp(r'^(.+?)\s*[xX×]\s*(\d+(?:\.\d+)?)\s*$', caseSensitive: false).firstMatch(trimmed);
      if (matchXQty != null) {
        name = matchXQty.group(1)!.trim();
        qty = _parseQty(matchXQty.group(2)!);
      } else {
        // Pattern 2: "qty - name" or "qty. name" or "qty name"
        final matchQtyFirst = RegExp(r'^(\d+(?:\.\d+)?)\s*[-–.\s]\s*(.+)$').firstMatch(trimmed);
        if (matchQtyFirst != null) {
          qty = _parseQty(matchQtyFirst.group(1)!);
          name = matchQtyFirst.group(2)!.trim();
        } else {
          // Pattern 3: "name    qty" (name followed by number at end)
          final matchNameQty = RegExp(r'^(.+?)\s{2,}(\d+(?:\.\d+)?)\s*$').firstMatch(trimmed);
          if (matchNameQty != null) {
            name = matchNameQty.group(1)!.trim();
            qty = _parseQty(matchNameQty.group(2)!);
          } else {
            // Pattern 4: "name (qty)" or "name [qty]"
            final matchParens = RegExp(r'^(.+?)\s*[(\[]\s*(\d+(?:\.\d+)?)\s*[)\]]\s*$').firstMatch(trimmed);
            if (matchParens != null) {
              name = matchParens.group(1)!.trim();
              qty = _parseQty(matchParens.group(2)!);
            } else {
              // Pattern 5: trailing number "name 10pcs" or "name 10pcs"
              final matchTrailing = RegExp(r'^(.+?)\s+(\d+)\s*(?:pcs?|kg|ltr?|pack|box|ea|each|doz|dz|cs|crt|btl|bg|bgs|tn|roll|rolls)\s*$', caseSensitive: false).firstMatch(trimmed);
              if (matchTrailing != null) {
                name = matchTrailing.group(1)!.trim();
                qty = _parseQty(matchTrailing.group(2)!);
              }
            }
          }
        }
      }

      // Clean up name: remove bullet points, dashes, numbers at start
      name = name.replaceAll(RegExp(r'^[\-•*\d.)\]\[]+\s*'), '').trim();
      if (name.isEmpty) continue;

      // Skip lines that are just quantities or too short
      if (name.length < 2) continue;

      items.add(ParsedItem(name: name, quantity: qty));
    }

    return items;
  }

  bool _isHeaderLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('delivery') ||
        lower.contains('invoice') ||
        lower.contains('receipt') ||
        lower.contains('order') ||
        lower.contains('date') ||
        lower.contains('supplier') ||
        lower.contains('customer') ||
        lower.contains('address') ||
        lower.contains('phone') ||
        lower.contains('tel') ||
        lower.contains('fax') ||
        lower.contains('page') ||
        lower.contains('item') &&
            (lower.contains('description') || lower.contains('qty') || lower.contains('quantity'));
  }

  int _parseQty(String raw) {
    final n = double.tryParse(raw.trim());
    if (n == null) return 1;
    return n <= 0 ? 1 : n.toInt();
  }

  Future<void> _matchProducts(List<ParsedItem> items) async {
    for (final item in items) {
      final lowerName = item.name.toLowerCase();

      // Exact match
      item.matchedProduct = _allProducts.where((p) => p.name.toLowerCase() == lowerName).firstOrNull;

      // Partial match (product name contains the scanned text or vice versa)
      item.matchedProduct ??= _allProducts.where((p) {
        final pLower = p.name.toLowerCase();
        return pLower.contains(lowerName) || lowerName.contains(pLower);
      }).firstOrNull;

      // Word-level match: all words from scanned text appear in product name
      item.matchedProduct ??= _allProducts.where((p) {
        final pLower = p.name.toLowerCase();
        final words = lowerName.split(RegExp(r'\s+'));
        return words.length > 1 && words.every((w) => pLower.contains(w));
      }).firstOrNull;
    }
  }

  void _updateItemName(int index, String newName) {
    setState(() {
      _parsedItems[index].name = newName;
      _parsedItems[index].matchedProduct = null;
    });
    // Re-match in background
    _matchProducts(_parsedItems).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _updateItemQty(int index, String newQty) {
    final qty = int.tryParse(newQty) ?? 1;
    setState(() => _parsedItems[index].quantity = qty > 0 ? qty : 1);
  }

  void _removeItem(int index) {
    setState(() => _parsedItems.removeAt(index));
  }

  void _confirm() {
    final result = _parsedItems.map((item) => {
      'name': item.matchedProduct?.name ?? item.name,
      'qty': item.quantity.toString(),
    }).toList();
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaycelColors.surface,
      appBar: AppBar(
        title: Text('Scan Delivery List', style: BaycelTypography.titleLg.copyWith(color: Colors.white)),
        backgroundColor: BaycelColors.crimson,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_parsedItems.isNotEmpty)
            TextButton(
              onPressed: _confirm,
              child: Text('Done (${_parsedItems.length})', style: BaycelTypography.label.copyWith(color: Colors.white)),
            ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingState()
          : _parsedItems.isEmpty
              ? _buildCaptureState()
              : _buildReviewState(),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: BaycelColors.crimson),
          SizedBox(height: BaycelSpacing.lg),
          Text('Processing delivery list...', style: BaycelTypography.body.copyWith(color: BaycelColors.textSecondary)),
          SizedBox(height: BaycelSpacing.sm),
          Text('Extracting text from image', style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCaptureState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(BaycelSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: BaycelColors.crimson.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.document_scanner_outlined, size: 56, color: BaycelColors.crimson),
            ),
            SizedBox(height: BaycelSpacing.lg),
            Text('Scan Delivery List', style: BaycelTypography.headlineMd),
            SizedBox(height: BaycelSpacing.sm),
            Text(
              'Take a photo of the printed delivery list.\nProducts and quantities will be extracted automatically.',
              style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: BaycelSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _captureImage(ImageSource.camera),
                icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                label: Text('Open Camera', style: BaycelTypography.label.copyWith(color: Colors.white)),
                style: BaycelComponents.buttonPrimary.copyWith(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
                    horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical)),
                ),
              ),
            ),
            SizedBox(height: BaycelSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _captureImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library_outlined, size: 20, color: BaycelColors.crimson),
                label: Text('Choose from Gallery', style: BaycelTypography.label.copyWith(color: BaycelColors.crimson)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: BaycelColors.crimson.withValues(alpha: 0.3)),
                  padding: EdgeInsets.symmetric(
                    horizontal: BaycelSpacing.buttonHorizontal, vertical: BaycelSpacing.buttonVertical),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewState() {
    final matchedCount = _parsedItems.where((i) => i.matchedProduct != null).length;
    final unmatchedCount = _parsedItems.length - matchedCount;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          color: BaycelColors.card,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: BaycelColors.blue),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(
                child: Text(
                  '$matchedCount matched, $unmatchedCount unmatched. Tap to edit names or quantities.',
                  style: BaycelTypography.bodySm.copyWith(color: BaycelColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        if (_rawText != null)
          ExpansionTile(
            title: Text('Raw OCR Text', style: BaycelTypography.labelSm),
            tilePadding: EdgeInsets.symmetric(horizontal: BaycelSpacing.base),
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(BaycelSpacing.base),
                color: BaycelColors.surface,
                child: Text(_rawText!, style: BaycelTypography.dataMono.copyWith(fontSize: 11, color: BaycelColors.textMuted)),
              ),
            ],
          ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(BaycelSpacing.base),
            itemCount: _parsedItems.length,
            separatorBuilder: (_, __) => SizedBox(height: BaycelSpacing.xs),
            itemBuilder: (context, index) => _buildItemRow(index),
          ),
        ),
        Container(
          padding: EdgeInsets.all(BaycelSpacing.base),
          decoration: BoxDecoration(
            color: BaycelColors.card,
            border: Border(top: BorderSide(color: BaycelColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _captureImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt, size: 18, color: BaycelColors.crimson),
                  label: Text('Rescan', style: BaycelTypography.labelSm.copyWith(color: BaycelColors.crimson)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: BaycelColors.crimson.withValues(alpha: 0.3)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: BaycelSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _parsedItems.isEmpty ? null : _confirm,
                  style: BaycelComponents.buttonPrimary.copyWith(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
                  ),
                  child: Text('Add ${_parsedItems.length} Items to Delivery', style: BaycelTypography.label.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index) {
    final item = _parsedItems[index];
    final isMatched = item.matchedProduct != null;

    return Container(
      padding: EdgeInsets.all(BaycelSpacing.sm),
      decoration: BaycelComponents.card.copyWith(
        border: Border.all(
          color: isMatched ? BaycelColors.success.withValues(alpha: 0.3) : BaycelColors.marigoldDark.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isMatched ? BaycelColors.success.withValues(alpha: 0.1) : BaycelColors.marigoldDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMatched ? Icons.check : Icons.help_outline,
              size: 14,
              color: isMatched ? BaycelColors.success : BaycelColors.marigoldDark,
            ),
          ),
          SizedBox(width: BaycelSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: item.name,
                  onChanged: (v) => _updateItemName(index, v),
                  style: BaycelTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    suffixText: isMatched ? '✓ matched' : 'unmatched',
                    suffixStyle: BaycelTypography.labelSm.copyWith(
                      fontSize: 10,
                      color: isMatched ? BaycelColors.success : BaycelColors.marigoldDark,
                    ),
                  ),
                ),
                if (item.matchedProduct != null)
                  Text('SKU: ${item.matchedProduct!.sku}',
                    style: BaycelTypography.dataMono.copyWith(fontSize: 10, color: BaycelColors.textMuted)),
              ],
            ),
          ),
          SizedBox(width: BaycelSpacing.sm),
          SizedBox(
            width: 52,
            child: TextFormField(
              initialValue: item.quantity.toString(),
              onChanged: (v) => _updateItemQty(index, v),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: BaycelTypography.dataMono.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  borderSide: BorderSide(color: BaycelColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BaycelRadius.sm),
                  borderSide: BorderSide(color: BaycelColors.divider),
                ),
              ),
            ),
          ),
          SizedBox(width: BaycelSpacing.xs),
          GestureDetector(
            onTap: () => _removeItem(index),
            child: Icon(Icons.close, size: 16, color: BaycelColors.error),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final double price;
  final int stockQuantity;
  final int reorderLevel;
  final String unit;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode = '',
    required this.category,
    required this.price,
    required this.stockQuantity,
    required this.reorderLevel,
    required this.unit,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'price': price,
      'stockQuantity': stockQuantity,
      'reorderLevel': reorderLevel,
      'unit': unit,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      price: (map['price'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? map['quantity'] ?? 0,
      reorderLevel: map['reorderLevel'] ?? 0,
      unit: map['unit'] ?? 'box',
      isActive: map['isActive'] ?? true,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
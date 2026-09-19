import 'package:cloud_firestore/cloud_firestore.dart';

enum StockMovementType {
  stockIn,
  stockOut,
  adjustment,
  receiving;

  static StockMovementType fromValue(String value) {
    switch (value) {
      case 'out':
      case 'stock-out':
        return StockMovementType.stockOut;
      case 'adjustment':
        return StockMovementType.adjustment;
      case 'receiving':
        return StockMovementType.receiving;
      case 'in':
      default:
        return StockMovementType.stockIn;
    }
  }

  String get value {
    switch (this) {
      case StockMovementType.stockOut:
        return 'out';
      case StockMovementType.adjustment:
        return 'adjustment';
      case StockMovementType.receiving:
        return 'receiving';
      case StockMovementType.stockIn:
        return 'in';
    }
  }
}

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity;
  final int balanceAfter;
  final String performedBy;
  final String? referenceId;
  final String? note;
  final DateTime createdAt;
  final double? expectedCash;
  final double? actualCash;
  final String? receiptImageUrl;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.balanceAfter,
    required this.performedBy,
    this.referenceId,
    this.note,
    required this.createdAt,
    this.expectedCash,
    this.actualCash,
    this.receiptImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'type': type.value,
      'quantity': quantity,
      'balanceAfter': balanceAfter,
      'performedBy': performedBy,
      'referenceId': referenceId,
      'note': note,
      'createdAt': createdAt,
      if (expectedCash != null) 'expectedCash': expectedCash,
      if (actualCash != null) 'actualCash': actualCash,
      if (receiptImageUrl != null) 'receiptImageUrl': receiptImageUrl,
    };
  }

  factory StockMovement.fromMap(String id, Map<String, dynamic> map) {
    return StockMovement(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      type: StockMovementType.fromValue(map['type'] ?? 'in'),
      quantity: (map['quantity'] ?? 0).toInt(),
      balanceAfter: (map['balanceAfter'] ?? 0).toInt(),
      performedBy: map['performedBy'] ?? '',
      referenceId: map['referenceId'],
      note: map['note'],
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      expectedCash: (map['expectedCash'] as num?)?.toDouble(),
      actualCash: (map['actualCash'] as num?)?.toDouble(),
      receiptImageUrl: map['receiptImageUrl'],
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
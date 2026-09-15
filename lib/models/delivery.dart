import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus {
  pending,
  inTransit,
  delivered,
  cancelled,
  discrepancy;

  static DeliveryStatus fromValue(String value) {
    switch (value) {
      case 'in-transit':
        return DeliveryStatus.inTransit;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      case 'discrepancy':
        return DeliveryStatus.discrepancy;
      case 'pending':
      default:
        return DeliveryStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case DeliveryStatus.inTransit:
        return 'in-transit';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
      case DeliveryStatus.discrepancy:
        return 'discrepancy';
      case DeliveryStatus.pending:
        return 'pending';
    }
  }
}

class DeliveryItem {
  final String productId;
  final String productName;
  final int expectedQuantity;
  final int receivedQuantity;

  const DeliveryItem({
    required this.productId,
    required this.productName,
    required this.expectedQuantity,
    required this.receivedQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'expectedQuantity': expectedQuantity,
      'receivedQuantity': receivedQuantity,
    };
  }

  factory DeliveryItem.fromMap(Map<String, dynamic> map) {
    return DeliveryItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      expectedQuantity: map['expectedQuantity'] ?? 0,
      receivedQuantity: map['receivedQuantity'] ?? 0,
    );
  }
}

class Delivery {
  final String id;
  final String supplierName;
  final String? referenceNumber;
  final List<DeliveryItem> items;
  final DeliveryStatus status;
  final String? receivedBy;
  final String? checkedBy;
  final String? note;
  final DateTime? scheduledAt;
  final DateTime? receivedAt;
  final DateTime createdAt;

  const Delivery({
    required this.id,
    required this.supplierName,
    this.referenceNumber,
    required this.items,
    this.status = DeliveryStatus.pending,
    this.receivedBy,
    this.checkedBy,
    this.note,
    this.scheduledAt,
    this.receivedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'supplierName': supplierName,
      'referenceNumber': referenceNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.value,
      'receivedBy': receivedBy,
      'checkedBy': checkedBy,
      'note': note,
      'scheduledAt': scheduledAt,
      'receivedAt': receivedAt,
      'createdAt': createdAt,
    };
  }

  factory Delivery.fromMap(String id, Map<String, dynamic> map) {
    return Delivery(
      id: id,
      supplierName: map['supplierName'] ?? '',
      referenceNumber: map['referenceNumber'],
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => DeliveryItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      status: DeliveryStatus.fromValue(map['status'] ?? 'pending'),
      receivedBy: map['receivedBy'],
      checkedBy: map['checkedBy'],
      note: map['note'],
      scheduledAt: _toDate(map['scheduledAt']),
      receivedAt: _toDate(map['receivedAt']),
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreSettings {
  final String id;
  final String storeName;
  final String storeCode;
  final String currency;
  final String timezone;
  final Map<String, dynamic> values;
  final DateTime? updatedAt;

  const StoreSettings({
    required this.id,
    required this.storeName,
    required this.storeCode,
    this.currency = 'PHP',
    this.timezone = 'Asia/Manila',
    required this.values,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storeCode': storeCode,
      'currency': currency,
      'timezone': timezone,
      'values': values,
      'updatedAt': updatedAt,
    };
  }

  factory StoreSettings.fromMap(String id, Map<String, dynamic> map) {
    return StoreSettings(
      id: id,
      storeName: map['storeName'] ?? 'Baycel Growcery',
      storeCode: map['storeCode'] ?? '',
      currency: map['currency'] ?? 'PHP',
      timezone: map['timezone'] ?? 'Asia/Manila',
      values: Map<String, dynamic>.from(map['values'] ?? {}),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
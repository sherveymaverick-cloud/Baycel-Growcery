import 'package:cloud_firestore/cloud_firestore.dart';

class DeductibleTemplate {
  final String id;
  final String name;
  final String type; // 'percentage' | 'fixed'
  final double value;
  final DateTime? createdAt;

  const DeductibleTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'value': value,
      'createdAt': createdAt,
    };
  }

  factory DeductibleTemplate.fromMap(String id, Map<String, dynamic> map) {
    return DeductibleTemplate(
      id: id,
      name: map['name'] as String? ?? '',
      type: map['type'] == 'percentage' ? 'percentage' : 'fixed',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      createdAt: _toDate(map['createdAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

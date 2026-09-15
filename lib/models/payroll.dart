import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String role;
  final String periodStart;
  final String periodEnd;
  final double basicPay;
  final double overtimePay;
  final double deductions;
  final double netPay;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.role = '',
    required this.periodStart,
    required this.periodEnd,
    required this.basicPay,
    required this.overtimePay,
    required this.deductions,
    required this.netPay,
    this.status = 'pending',
    this.paidAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'role': role,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'basicPay': basicPay,
      'overtimePay': overtimePay,
      'deductions': deductions,
      'netPay': netPay,
      'status': status,
      'paidAt': paidAt,
      'createdAt': createdAt,
    };
  }

  factory PayrollRecord.fromMap(String id, Map<String, dynamic> map) {
    return PayrollRecord(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      role: map['role'] ?? '',
      periodStart: map['periodStart'] ?? '',
      periodEnd: map['periodEnd'] ?? '',
      basicPay: (map['basicPay'] ?? 0).toDouble(),
      overtimePay: (map['overtimePay'] ?? 0).toDouble(),
      deductions: (map['deductions'] ?? 0).toDouble(),
      netPay: (map['netPay'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      paidAt: _toDate(map['paidAt']),
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
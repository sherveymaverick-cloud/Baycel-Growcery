import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollDeduction {
  final String description;
  final double amount;

  const PayrollDeduction({
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
    'description': description,
    'amount': amount,
  };

  factory PayrollDeduction.fromMap(Map<String, dynamic> map) {
    return PayrollDeduction(
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}

class PayrollRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String role;
  final String periodStart;
  final String periodEnd;
  final double hourlyRate;
  final int totalHours;
  final int overtimeHours;
  final double basicPay;
  final double overtimePay;
  final double totalGross;
  final List<PayrollDeduction> deductions;
  final double totalDeductions;
  final double netPay;
  final int paidLeaveDays;
  final int unpaidLeaveDays;
  final String status;
  final String? ownerNotes;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.role = '',
    required this.periodStart,
    required this.periodEnd,
    required this.hourlyRate,
    required this.totalHours,
    required this.overtimeHours,
    required this.basicPay,
    required this.overtimePay,
    required this.totalGross,
    required this.deductions,
    required this.totalDeductions,
    required this.netPay,
    this.paidLeaveDays = 0,
    this.unpaidLeaveDays = 0,
    this.status = 'pending',
    this.ownerNotes,
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
      'hourlyRate': hourlyRate,
      'totalHours': totalHours,
      'overtimeHours': overtimeHours,
      'basicPay': basicPay,
      'overtimePay': overtimePay,
      'totalGross': totalGross,
      'deductions': deductions.map((d) => d.toMap()).toList(),
      'totalDeductions': totalDeductions,
      'netPay': netPay,
      'paidLeaveDays': paidLeaveDays,
      'unpaidLeaveDays': unpaidLeaveDays,
      'status': status,
      'ownerNotes': ownerNotes,
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
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      totalHours: (map['totalHours'] ?? 0).toInt(),
      overtimeHours: (map['overtimeHours'] ?? 0).toInt(),
      basicPay: (map['basicPay'] ?? 0).toDouble(),
      overtimePay: (map['overtimePay'] ?? 0).toDouble(),
      totalGross: (map['totalGross'] ?? 0).toDouble(),
      deductions: (map['deductions'] as List<dynamic>?)
          ?.map((d) => PayrollDeduction.fromMap(d as Map<String, dynamic>))
          .toList() ?? [],
      totalDeductions: (map['totalDeductions'] ?? 0).toDouble(),
      netPay: (map['netPay'] ?? 0).toDouble(),
      paidLeaveDays: (map['paidLeaveDays'] ?? 0).toInt(),
      unpaidLeaveDays: (map['unpaidLeaveDays'] ?? 0).toInt(),
      status: map['status'] ?? 'pending',
      ownerNotes: map['ownerNotes'],
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
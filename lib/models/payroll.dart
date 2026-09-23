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
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
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
    final rawDeductions = map['deductions'];
    return PayrollRecord(
      id: id,
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      role: map['role'] as String? ?? '',
      periodStart: map['periodStart'] as String? ?? '',
      periodEnd: map['periodEnd'] as String? ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0,
      totalHours: (map['totalHours'] as num?)?.toInt() ?? 0,
      overtimeHours: (map['overtimeHours'] as num?)?.toInt() ?? 0,
      basicPay: (map['basicPay'] as num?)?.toDouble() ?? 0,
      overtimePay: (map['overtimePay'] as num?)?.toDouble() ?? 0,
      totalGross: (map['totalGross'] as num?)?.toDouble() ?? 0,
      deductions: rawDeductions is List
          ? rawDeductions
              .whereType<Map>()
              .map((d) => PayrollDeduction.fromMap(Map<String, dynamic>.from(d)))
              .toList()
          : <PayrollDeduction>[],
      totalDeductions: (map['totalDeductions'] as num?)?.toDouble() ?? 0,
      netPay: (map['netPay'] as num?)?.toDouble() ?? 0,
      paidLeaveDays: (map['paidLeaveDays'] as num?)?.toInt() ?? 0,
      unpaidLeaveDays: (map['unpaidLeaveDays'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      ownerNotes: map['ownerNotes'] as String?,
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
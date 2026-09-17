import 'package:cloud_firestore/cloud_firestore.dart';

enum CashAdvanceStatus {
  pending,
  approved,
  rejected;

  static CashAdvanceStatus fromValue(String value) {
    switch (value) {
      case 'approved':
        return CashAdvanceStatus.approved;
      case 'rejected':
        return CashAdvanceStatus.rejected;
      case 'pending':
      default:
        return CashAdvanceStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case CashAdvanceStatus.approved:
        return 'approved';
      case CashAdvanceStatus.rejected:
        return 'rejected';
      case CashAdvanceStatus.pending:
        return 'pending';
    }
  }
}

class CashAdvance {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String reason;
  final CashAdvanceStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;

  const CashAdvance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.reason,
    this.status = CashAdvanceStatus.pending,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'reason': reason,
      'status': status.value,
      'requestedAt': requestedAt,
      'reviewedAt': reviewedAt,
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
    };
  }

  factory CashAdvance.fromMap(String id, Map<String, dynamic> map) {
    return CashAdvance(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      status: CashAdvanceStatus.fromValue(map['status'] ?? 'pending'),
      requestedAt: _toDate(map['requestedAt']) ?? DateTime.now(),
      reviewedAt: _toDate(map['reviewedAt']),
      reviewedBy: map['reviewedBy'],
      reviewNote: map['reviewNote'],
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

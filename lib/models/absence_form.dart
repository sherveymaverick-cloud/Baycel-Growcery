import 'package:cloud_firestore/cloud_firestore.dart';

enum AbsenceStatus {
  pending,
  approved,
  rejected;

  static AbsenceStatus fromValue(String value) {
    switch (value) {
      case 'approved':
        return AbsenceStatus.approved;
      case 'rejected':
        return AbsenceStatus.rejected;
      case 'pending':
      default:
        return AbsenceStatus.pending;
    }
  }

  String get value => name;
}

class AbsenceForm {
  final String id;
  final String employeeId;
  final String employeeName;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final AbsenceStatus status;
  final String? managerNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const AbsenceForm({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    this.status = AbsenceStatus.pending,
    this.managerNote,
    this.submittedAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'reason': reason,
      'startDate': startDate,
      'endDate': endDate,
      'status': status.value,
      'managerNote': managerNote,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
    };
  }

  factory AbsenceForm.fromMap(String id, Map<String, dynamic> map) {
    return AbsenceForm(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      reason: map['reason'] ?? '',
      startDate: _toDate(map['startDate']) ?? DateTime.now(),
      endDate: _toDate(map['endDate']) ?? DateTime.now(),
      status: AbsenceStatus.fromValue(map['status'] ?? 'pending'),
      managerNote: map['managerNote'],
      submittedAt: _toDate(map['submittedAt']),
      reviewedAt: _toDate(map['reviewedAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

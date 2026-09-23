enum AttendanceStatus {
  complete,
  inProgress,
  absent,
  discrepancy,
  onLeave,
  verified,
  pending,
  late,
  present;

  static AttendanceStatus fromValue(String value) {
    switch (value) {
      case 'complete':
        return AttendanceStatus.complete;
      case 'in-progress':
        return AttendanceStatus.inProgress;
      case 'absent':
        return AttendanceStatus.absent;
      case 'discrepancy':
        return AttendanceStatus.discrepancy;
      case 'on-leave':
        return AttendanceStatus.onLeave;
      case 'verified':
        return AttendanceStatus.verified;
      case 'pending':
        return AttendanceStatus.pending;
      case 'late':
        return AttendanceStatus.late;
      case 'present':
        return AttendanceStatus.present;
      default:
        return AttendanceStatus.complete;
    }
  }

  String get value {
    switch (this) {
      case AttendanceStatus.complete:
        return 'complete';
      case AttendanceStatus.inProgress:
        return 'in-progress';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.discrepancy:
        return 'discrepancy';
      case AttendanceStatus.onLeave:
        return 'on-leave';
      case AttendanceStatus.verified:
        return 'verified';
      case AttendanceStatus.pending:
        return 'pending';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.present:
        return 'present';
    }
  }
}

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date;
  final String timeIn;
  final String? timeOut;
  final String? timeIn2;
  final String? timeOut2;
  final double totalHours;
  final int lateMinutes;
  final int undertimeMinutes;
  final double overtimeHours;
  final AttendanceStatus? status;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.timeIn,
    this.timeOut,
    this.timeIn2,
    this.timeOut2,
    this.totalHours = 0,
    this.lateMinutes = 0,
    this.undertimeMinutes = 0,
    this.overtimeHours = 0,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'date': date,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'timeIn2': timeIn2,
      'timeOut2': timeOut2,
      'totalHours': totalHours,
      'lateMinutes': lateMinutes,
      'undertimeMinutes': undertimeMinutes,
      'overtimeHours': overtimeHours,
      'status': status?.value,
    };
  }

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    final statusRaw = map['status'];
    return AttendanceRecord(
      id: id,
      employeeId: map['employeeId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      timeIn: map['timeIn'] as String? ?? '',
      timeOut: map['timeOut'] as String?,
      timeIn2: map['timeIn2'] as String?,
      timeOut2: map['timeOut2'] as String?,
      totalHours: (map['totalHours'] as num?)?.toDouble() ?? 0,
      lateMinutes: (map['lateMinutes'] as num?)?.toInt() ?? 0,
      undertimeMinutes: (map['undertimeMinutes'] as num?)?.toInt() ?? 0,
      overtimeHours: (map['overtimeHours'] as num?)?.toDouble() ?? 0,
      status: statusRaw is String ? AttendanceStatus.fromValue(statusRaw) : null,
    );
  }
}
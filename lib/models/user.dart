import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  owner,
  manager,
  cashier,
  bagger,
  bodegero,
  deliveryChecker,
  merchandiser,
}

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager:
        return 'manager';
      case UserRole.cashier:
        return 'cashier';
      case UserRole.bagger:
        return 'bagger';
      case UserRole.bodegero:
        return 'bodegero';
      case UserRole.deliveryChecker:
        return 'delivery_checker';
      case UserRole.merchandiser:
        return 'merchandiser';
    }
  }

  static UserRole fromValue(String value) {
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'cashier':
        return UserRole.cashier;
      case 'bagger':
        return UserRole.bagger;
      case 'bodegero':
        return UserRole.bodegero;
      case 'delivery_checker':
        return UserRole.deliveryChecker;
      case 'merchandiser':
        return UserRole.merchandiser;
      default:
        return UserRole.cashier;
    }
  }
}

class WorkSchedule {
  final String start;
  final String end;

  const WorkSchedule({required this.start, required this.end});

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  factory WorkSchedule.fromMap(Map<String, dynamic> map) {
    return WorkSchedule(
      start: map['start'] ?? '08:00',
      end: map['end'] ?? '17:00',
    );
  }
}

class StoreUser {
  static const dayOffChoices = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final double rate;
  final int payday;
  final String dayOff;
  final WorkSchedule schedule;
  final String rfidCardUID;
  final List<String> assignedProducts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoreUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.rate,
    this.payday = 7,
    this.dayOff = '',
    required this.schedule,
    required this.rfidCardUID,
    required this.assignedProducts,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'rate': rate,
      'payday': payday,
      'dayOff': dayOff,
      'schedule': schedule.toMap(),
      'rfidCardUID': rfidCardUID,
      'assignedProducts': assignedProducts,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory StoreUser.fromMap(String uid, Map<String, dynamic> map) {
    final rawAssigned = map['assignedProducts'];
    return StoreUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRoleX.fromValue(map['role'] as String? ?? ''),
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      payday: (map['payday'] as num?)?.toInt() ?? 15,
      dayOff: map['dayOff'] as String? ?? '',
      schedule: WorkSchedule.fromMap(
        map['schedule'] is Map ? Map<String, dynamic>.from(map['schedule'] as Map) : const {},
      ),
      rfidCardUID: map['rfidCardUID'] as String? ?? '',
      assignedProducts: rawAssigned is List
          ? List<String>.from(rawAssigned.whereType<Object>().map((e) => e.toString()))
          : <String>[],
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

import 'package:intl/intl.dart';

class AttendanceEmployeeSummary {
  const AttendanceEmployeeSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
  });

  final int id;
  final String name;
  final String email;
  final String department;

  factory AttendanceEmployeeSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceEmployeeSummary(id: 0, name: '', email: '', department: '');
    return AttendanceEmployeeSummary(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      department: (json['department'] as String?) ?? '',
    );
  }
}

class AttendanceMarkedBySummary {
  const AttendanceMarkedBySummary({required this.id, required this.name});

  final int id;
  final String name;

  factory AttendanceMarkedBySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceMarkedBySummary(id: 0, name: '');
    return AttendanceMarkedBySummary(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class RemoteAttendanceRecord {
  const RemoteAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.status,
    required this.isLate,
    this.checkIn,
    this.checkOut,
    this.leaveReason,
    this.notes,
    this.employee,
    this.markedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int employeeId;
  final String attendanceDate;
  final String status;
  final bool isLate;
  final String? checkIn;
  final String? checkOut;
  final String? leaveReason;
  final String? notes;
  final AttendanceEmployeeSummary? employee;
  final AttendanceMarkedBySummary? markedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get employeeDisplayName => employee?.name.trim().isNotEmpty == true ? employee!.name : 'Employee #$employeeId';

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory RemoteAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    final marked = json['marked_by'];
    return RemoteAttendanceRecord(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      employeeId: int.tryParse((json['employee_id'] ?? '').toString()) ?? 0,
      attendanceDate: (json['attendance_date'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      isLate: json['is_late'] == true || json['is_late']?.toString() == '1',
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      leaveReason: json['leave_reason'] as String?,
      notes: json['notes'] as String?,
      employee: emp is Map<String, dynamic>
          ? AttendanceEmployeeSummary.fromJson(emp)
          : emp is Map
          ? AttendanceEmployeeSummary.fromJson(emp.cast<String, dynamic>())
          : null,
      markedBy: marked is Map<String, dynamic>
          ? AttendanceMarkedBySummary.fromJson(marked)
          : marked is Map
          ? AttendanceMarkedBySummary.fromJson(marked.cast<String, dynamic>())
          : null,
      createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
      updatedAt: parseApiDateTime((json['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'attendance_date': attendanceDate,
    'status': status,
    'is_late': isLate,
    'check_in': checkIn,
    'check_out': checkOut,
    'leave_reason': leaveReason,
    'notes': notes,
    'employee': employee == null
        ? null
        : {'id': employee!.id, 'name': employee!.name, 'email': employee!.email, 'department': employee!.department},
    'marked_by': markedBy == null ? null : {'id': markedBy!.id, 'name': markedBy!.name},
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

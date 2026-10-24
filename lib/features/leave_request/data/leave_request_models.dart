import 'package:intl/intl.dart';

import 'package:attendance/core/utils/app_date_format.dart';

class LeaveRequestEmployeeSummary {
  const LeaveRequestEmployeeSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
  });

  final int id;
  final String name;
  final String email;
  final String department;

  factory LeaveRequestEmployeeSummary.fromJson(Map<String, dynamic> json) => LeaveRequestEmployeeSummary(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    department: (json['department'] as String?) ?? '',
  );
}

class LeaveRequestReviewerSummary {
  const LeaveRequestReviewerSummary({required this.id, required this.name, this.email});

  final int id;
  final String name;
  final String? email;

  factory LeaveRequestReviewerSummary.fromJson(Map<String, dynamic> json) => LeaveRequestReviewerSummary(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    email: json['email'] as String?,
  );
}

class LeaveRequestItem {
  LeaveRequestItem({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewNote,
    this.reviewedAt,
    this.employee,
    this.reviewer,
    this.days,
    this.paidDays,
    this.unpaidDays,
    this.leaveType,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int employeeId;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final LeaveRequestEmployeeSummary? employee;
  final LeaveRequestReviewerSummary? reviewer;
  final int? days;
  final int? paidDays;
  final int? unpaidDays;
  final String? leaveType;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get employeeDisplayName => employee?.name.trim().isNotEmpty == true ? employee!.name : 'Employee #$employeeId';

  String get dateRangeLabel {
    if (startDate.isEmpty && endDate.isEmpty) return '';
    return AppDateFormat.rangeFromRaw(startDate, endDate);
  }

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    final rev = json['reviewer'];
    final reviewedRaw = json['reviewed_at'] as String?;

    final cancelledRaw = json['cancelled_at'] as String?;
    int? asInt(Object? v) {
      if (v == null) return null;
      return int.tryParse(v.toString());
    }

    return LeaveRequestItem(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      employeeId: int.tryParse((json['employee_id'] ?? '').toString()) ?? 0,
      startDate: (json['start_date'] as String?) ?? '',
      endDate: (json['end_date'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      reviewNote: json['review_note'] as String?,
      reviewedAt: reviewedRaw != null && reviewedRaw.isNotEmpty ? parseApiDateTime(reviewedRaw) : null,
      employee: emp is Map<String, dynamic> ? LeaveRequestEmployeeSummary.fromJson(emp) : null,
      reviewer: rev is Map<String, dynamic> ? LeaveRequestReviewerSummary.fromJson(rev) : null,
      days: asInt(json['days']),
      paidDays: asInt(json['paid_days']),
      unpaidDays: asInt(json['unpaid_days']),
      leaveType: json['leave_type'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      cancelledAt: cancelledRaw != null && cancelledRaw.isNotEmpty ? parseApiDateTime(cancelledRaw) : null,
      createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
      updatedAt: parseApiDateTime((json['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'start_date': startDate,
    'end_date': endDate,
    'reason': reason,
    'status': status,
    'review_note': reviewNote,
    'reviewed_at': reviewedAt?.toIso8601String(),
    'employee': employee == null
        ? null
        : {'id': employee!.id, 'name': employee!.name, 'email': employee!.email, 'department': employee!.department},
    'reviewer': reviewer == null ? null : {'id': reviewer!.id, 'name': reviewer!.name, 'email': reviewer!.email},
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

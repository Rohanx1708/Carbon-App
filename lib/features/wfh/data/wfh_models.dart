import 'package:intl/intl.dart';

class WfhEmployeeSummary {
  const WfhEmployeeSummary({required this.id, required this.name, required this.email, required this.department});

  final int id;
  final String name;
  final String email;
  final String department;

  factory WfhEmployeeSummary.fromJson(Map<String, dynamic> json) => WfhEmployeeSummary(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    department: (json['department'] as String?) ?? '',
  );
}

class WfhReviewerSummary {
  const WfhReviewerSummary({required this.id, required this.name, this.email});

  final int id;
  final String name;
  final String? email;

  factory WfhReviewerSummary.fromJson(Map<String, dynamic> json) => WfhReviewerSummary(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    email: json['email'] as String?,
  );
}

class WfhRequest {
  WfhRequest({
    required this.id,
    required this.employeeId,
    required this.wfhDate,
    required this.reason,
    required this.status,
    this.reviewNote,
    this.reviewedAt,
    this.employee,
    this.reviewer,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int employeeId;
  final String wfhDate;
  final String reason;
  final String status;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final WfhEmployeeSummary? employee;
  final WfhReviewerSummary? reviewer;
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

  factory WfhRequest.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    final rev = json['reviewer'];
    final reviewedRaw = json['reviewed_at'] as String?;

    return WfhRequest(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      employeeId: int.tryParse((json['employee_id'] ?? '').toString()) ?? 0,
      wfhDate: (json['wfh_date'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      reviewNote: json['review_note'] as String?,
      reviewedAt: reviewedRaw != null && reviewedRaw.isNotEmpty ? parseApiDateTime(reviewedRaw) : null,
      employee: emp is Map<String, dynamic> ? WfhEmployeeSummary.fromJson(emp) : null,
      reviewer: rev is Map<String, dynamic> ? WfhReviewerSummary.fromJson(rev) : null,
      createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
      updatedAt: parseApiDateTime((json['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'wfh_date': wfhDate,
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

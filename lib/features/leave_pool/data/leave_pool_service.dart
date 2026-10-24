import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/services/api_client.dart';

int _int(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;
Map<String, dynamic> _map(Object? v) => v is Map<String, dynamic> ? v : const {};
List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map<String, dynamic>) e,
];

class LeavePoolEmployee {
  const LeavePoolEmployee({
    required this.employee,
    required this.balance,
    required this.creditedThisYear,
    required this.paidUsed,
    required this.unpaidUsed,
    required this.pendingDays,
  });

  final ReportEmployee employee;
  final int balance;
  final int creditedThisYear;
  final int paidUsed;
  final int unpaidUsed;
  final int pendingDays;

  factory LeavePoolEmployee.fromJson(Map<String, dynamic> j) => LeavePoolEmployee(
    employee: ReportEmployee.fromJson(_map(j['employee'])),
    balance: _int(j['balance']),
    creditedThisYear: _int(j['credited_this_year']),
    paidUsed: _int(j['paid_used']),
    unpaidUsed: _int(j['unpaid_used']),
    pendingDays: _int(j['pending_days']),
  );
}

class LeavePoolTotals {
  const LeavePoolTotals({
    required this.employees,
    required this.balance,
    required this.creditedThisYear,
    required this.paidUsed,
    required this.unpaidUsed,
    required this.pendingDays,
    required this.pendingRequests,
  });

  final int employees;
  final int balance;
  final int creditedThisYear;
  final int paidUsed;
  final int unpaidUsed;
  final int pendingDays;
  final int pendingRequests;

  factory LeavePoolTotals.fromJson(Map<String, dynamic> j) => LeavePoolTotals(
    employees: _int(j['employees']),
    balance: _int(j['balance']),
    creditedThisYear: _int(j['credited_this_year']),
    paidUsed: _int(j['paid_used']),
    unpaidUsed: _int(j['unpaid_used']),
    pendingDays: _int(j['pending_days']),
    pendingRequests: _int(j['pending_requests']),
  );
}

class LeavePoolOverview {
  const LeavePoolOverview({
    required this.year,
    required this.annualLeaveQuota,
    required this.totals,
    required this.employees,
  });

  final int year;
  final int annualLeaveQuota;
  final LeavePoolTotals totals;
  final List<LeavePoolEmployee> employees;

  factory LeavePoolOverview.fromJson(Map<String, dynamic> j) => LeavePoolOverview(
    year: _int(j['year']),
    annualLeaveQuota: _int(j['annual_leave_quota']),
    totals: LeavePoolTotals.fromJson(_map(j['totals'])),
    employees: [for (final e in _list(j['employees'])) LeavePoolEmployee.fromJson(e)],
  );
}

class LeavePoolService {
  LeavePoolService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _object(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return data;
  }

  Future<LeavePoolOverview> fetchOverview(int year) async {
    final decoded = await _api.getJson('/api/v1/leave-pool', queryParameters: {'year': '$year'});
    return LeavePoolOverview.fromJson(_object(decoded));
  }

  Future<void> setAnnualQuota(int days) async {
    await _api.postJson('/api/v1/leave-pool/settings', body: {'annual_leave_quota': days});
  }

  Future<void> allocateAll({required int days, required String note}) async {
    await _api.postJson('/api/v1/leave-pool/allocate', body: {'days': days, 'note': note});
  }
}

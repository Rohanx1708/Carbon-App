import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/leave_request/data/leave_request_models.dart';

String teamStr(Object? v) => v == null ? '' : v.toString();
String? teamStrOrNull(Object? v) => v == null || v.toString().trim().isEmpty ? null : v.toString();
int teamInt(Object? v) => int.tryParse(teamStr(v)) ?? 0;
bool teamBool(Object? v) => v == true || v == 1 || v == '1' || teamStr(v).toLowerCase() == 'true';
Map<String, dynamic> teamMap(Object? v) => v is Map<String, dynamic> ? v : const {};
List<Map<String, dynamic>> teamList(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map<String, dynamic>) e,
];

class TeamTodayStatus {
  const TeamTodayStatus({required this.status, required this.isLate, this.checkIn, this.checkOut});

  final String status;
  final bool isLate;
  final String? checkIn;
  final String? checkOut;

  factory TeamTodayStatus.fromJson(Map<String, dynamic> j) => TeamTodayStatus(
    status: teamStr(j['status']).isEmpty ? 'not_marked' : teamStr(j['status']),
    isLate: teamBool(j['is_late']),
    checkIn: teamStrOrNull(j['check_in']),
    checkOut: teamStrOrNull(j['check_out']),
  );
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.designation,
    required this.today,
    required this.leaveBalance,
    this.reportingManagerId,
    this.todayKnown = true,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final int? reportingManagerId;
  final TeamTodayStatus today;
  final int leaveBalance;
  final bool todayKnown;

  ReportEmployee get asReportEmployee =>
      ReportEmployee(id: id, name: name, email: email, department: department, designation: designation);

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id: teamInt(j['id']),
    name: teamStr(j['name']),
    email: teamStr(j['email']),
    phone: teamStr(j['phone']),
    department: teamStr(j['department']),
    designation: teamStr(j['designation']),
    reportingManagerId: j['reporting_manager_id'] == null ? null : teamInt(j['reporting_manager_id']),
    today: TeamTodayStatus.fromJson(teamMap(j['today'])),
    leaveBalance: teamInt(j['leave_balance']),
  );

  factory TeamMember.fromEmployee({
    required ReportEmployee employee,
    TeamTodayStatus? today,
    int leaveBalance = 0,
    String phone = '',
  }) => TeamMember(
    id: employee.id,
    name: employee.name,
    email: employee.email ?? '',
    phone: phone,
    department: employee.department ?? '',
    designation: employee.designation ?? '',
    today: today ?? const TeamTodayStatus(status: 'not_marked', isLate: false),
    leaveBalance: leaveBalance,
    todayKnown: today != null,
  );
}

class TeamLeaveRequest {
  const TeamLeaveRequest({
    required this.request,
    required this.days,
    required this.paidDays,
    required this.unpaidDays,
    this.leaveType,
  });

  final LeaveRequestItem request;
  final int days;
  final int paidDays;
  final int unpaidDays;
  final String? leaveType;

  factory TeamLeaveRequest.fromJson(Map<String, dynamic> j) => TeamLeaveRequest(
    request: LeaveRequestItem.fromJson(j),
    days: teamInt(j['days']),
    paidDays: teamInt(j['paid_days']),
    unpaidDays: teamInt(j['unpaid_days']),
    leaveType: teamStrOrNull(j['leave_type']),
  );
}

class TeamOnLeaveDay {
  const TeamOnLeaveDay({required this.date, required this.leaves});

  final String date;
  final List<TeamLeaveRequest> leaves;

  factory TeamOnLeaveDay.fromJson(Map<String, dynamic> j) => TeamOnLeaveDay(
    date: teamStr(j['date']),
    leaves: [for (final e in teamList(j['leaves'])) TeamLeaveRequest.fromJson(e)],
  );
}

class TeamLeaveBalance {
  const TeamLeaveBalance({
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

  factory TeamLeaveBalance.fromJson(Map<String, dynamic> j) => TeamLeaveBalance(
    employee: ReportEmployee.fromJson(teamMap(j['employee'])),
    balance: teamInt(j['balance']),
    creditedThisYear: teamInt(j['credited_this_year']),
    paidUsed: teamInt(j['paid_used']),
    unpaidUsed: teamInt(j['unpaid_used']),
    pendingDays: teamInt(j['pending_days']),
  );
}

class TeamLeaveLog {
  const TeamLeaveLog({this.id, this.type, this.days, this.note, this.createdAt, this.actor});

  final int? id;
  final String? type;
  final int? days;
  final String? note;
  final String? createdAt;
  final String? actor;

  factory TeamLeaveLog.fromJson(Map<String, dynamic> j) {
    final actorMap = teamMap(j['created_by']).isNotEmpty
        ? teamMap(j['created_by'])
        : teamMap(j['user']).isNotEmpty
        ? teamMap(j['user'])
        : teamMap(j['marked_by']);
    final daysRaw = j['days'] ?? j['change'] ?? j['amount'] ?? j['value'];
    return TeamLeaveLog(
      id: j['id'] == null ? null : teamInt(j['id']),
      type: teamStrOrNull(j['type']) ?? teamStrOrNull(j['action']) ?? teamStrOrNull(j['kind']),
      days: daysRaw == null ? null : teamInt(daysRaw),
      note:
          teamStrOrNull(j['note']) ??
          teamStrOrNull(j['reason']) ??
          teamStrOrNull(j['remarks']) ??
          teamStrOrNull(j['description']),
      createdAt: teamStrOrNull(j['created_at']),
      actor: teamStrOrNull(actorMap['name']),
    );
  }
}

class TeamLeaveBalanceDetail {
  const TeamLeaveBalanceDetail({required this.employeeId, required this.balance, required this.logs});

  final int employeeId;
  final int balance;
  final List<TeamLeaveLog> logs;

  factory TeamLeaveBalanceDetail.fromJson(Map<String, dynamic> j) => TeamLeaveBalanceDetail(
    employeeId: teamInt(j['employee_id']),
    balance: teamInt(j['balance']),
    logs: [for (final e in teamList(j['logs'])) TeamLeaveLog.fromJson(e)],
  );
}

class TeamHubSnapshot {
  const TeamHubSnapshot({required this.members, required this.pendingRequests, required this.onLeaveToday});

  final List<TeamMember> members;
  final List<TeamLeaveRequest> pendingRequests;
  final List<TeamLeaveRequest> onLeaveToday;

  int get teamSize => members.length;
  int get pendingLeave => pendingRequests.length;

  int countStatus(String status) => members.where((m) => m.today.status.toLowerCase() == status).length;

  /// People a manager should look at first: unmarked, late, leave or absent.
  List<TeamMember> get needsAttention => [
    for (final m in members)
      if (m.today.isLate ||
          const {'not_marked', 'leave', 'on_leave', 'absent', 'unpaid_leave'}.contains(m.today.status.toLowerCase()))
        m,
  ];
}

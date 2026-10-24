import 'package:attendance/services/api_client.dart';

int _int(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;
String _str(Object? v) => v == null ? '' : v.toString();
String? _strOrNull(Object? v) => v == null || v.toString().trim().isEmpty ? null : v.toString();
List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map<String, dynamic>) e,
];

class LeaveBalanceChangedBy {
  const LeaveBalanceChangedBy({required this.id, required this.name});

  final int id;
  final String name;

  factory LeaveBalanceChangedBy.fromJson(Map<String, dynamic> j) =>
      LeaveBalanceChangedBy(id: _int(j['id']), name: _str(j['name']));
}

class LeaveBalanceLog {
  const LeaveBalanceLog({
    required this.id,
    required this.type,
    required this.change,
    required this.balanceBefore,
    required this.balanceAfter,
    this.leaveRequestId,
    this.note,
    this.changedBy,
    this.createdAt,
  });

  final int id;
  final String type;
  final int change;
  final int balanceBefore;
  final int balanceAfter;
  final int? leaveRequestId;
  final String? note;
  final LeaveBalanceChangedBy? changedBy;
  final String? createdAt;

  bool get isCredit => type.toLowerCase() == 'credit' || change > 0;

  factory LeaveBalanceLog.fromJson(Map<String, dynamic> j) {
    final by = j['changed_by'];
    return LeaveBalanceLog(
      id: _int(j['id']),
      type: _str(j['type']).isEmpty ? 'credit' : _str(j['type']),
      change: _int(j['change'] ?? j['days']),
      balanceBefore: _int(j['balance_before']),
      balanceAfter: _int(j['balance_after']),
      leaveRequestId: j['leave_request_id'] == null ? null : _int(j['leave_request_id']),
      note: _strOrNull(j['note']),
      changedBy: by is Map<String, dynamic> ? LeaveBalanceChangedBy.fromJson(by) : null,
      createdAt: _strOrNull(j['created_at']),
    );
  }
}

class MyLeaveBalance {
  const MyLeaveBalance({required this.employeeId, required this.name, required this.balance, required this.logs});

  final int employeeId;
  final String name;
  final int balance;
  final List<LeaveBalanceLog> logs;

  factory MyLeaveBalance.fromJson(Map<String, dynamic> j) => MyLeaveBalance(
    employeeId: _int(j['employee_id']),
    name: _str(j['name']),
    balance: _int(j['balance']),
    logs: [for (final e in _list(j['logs'])) LeaveBalanceLog.fromJson(e)],
  );
}

class LeaveBalancePerson {
  const LeaveBalancePerson({
    required this.employeeId,
    required this.name,
    required this.balance,
    this.email,
    this.department,
  });

  final int employeeId;
  final String name;
  final int balance;
  final String? email;
  final String? department;

  factory LeaveBalancePerson.fromJson(Map<String, dynamic> j) => LeaveBalancePerson(
    employeeId: _int(j['employee_id'] ?? j['id']),
    name: _str(j['name']),
    balance: _int(j['balance']),
    email: _strOrNull(j['email']),
    department: _strOrNull(j['department']),
  );
}

class LeaveBalanceHome {
  const LeaveBalanceHome({this.mine, this.people});

  final MyLeaveBalance? mine;
  final List<LeaveBalancePerson>? people;
}

class LeaveBalanceService {
  LeaveBalanceService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _object(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return data;
  }

  Future<MyLeaveBalance> fetchMine() async {
    final decoded = await _api.getJson('/api/v1/leave-balance');
    return MyLeaveBalance.fromJson(_object(decoded));
  }

  Future<List<LeaveBalancePerson>> fetchPeople() async {
    final decoded = await _api.getJson('/api/v1/leave-balances');
    return [for (final e in _list(decoded['data'])) LeaveBalancePerson.fromJson(e)];
  }

  Future<void> adjust({required int employeeId, required String type, required int days, required String note}) async {
    await _api.postJson('/api/v1/leave-balances/$employeeId/adjust', body: {'type': type, 'days': days, 'note': note});
  }

  Future<LeaveBalanceHome> fetchHome({required bool includeMine, required bool includePeople}) async {
    MyLeaveBalance? mine;
    List<LeaveBalancePerson>? people;
    if (includeMine) mine = await fetchMine();
    if (includePeople) people = await fetchPeople();
    return LeaveBalanceHome(mine: mine, people: people);
  }
}

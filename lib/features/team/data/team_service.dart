import 'package:intl/intl.dart';

import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/team/data/team_models.dart';
import 'package:attendance/services/api_client.dart';

class TeamService {
  TeamService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  static final _ymd = DateFormat('yyyy-MM-dd');

  Map<String, dynamic> _object(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return data;
  }

  Future<List<TeamMember>> fetchMembers() async {
    final decoded = await _api.getJson('/api/v1/team/members');
    return [for (final e in teamList(decoded['data'])) TeamMember.fromJson(e)];
  }

  Future<DailyReport> fetchAttendance(DateTime date) async {
    final decoded = await _api.getJson('/api/v1/team/attendance', queryParameters: {'date': _ymd.format(date)});
    return DailyReport.fromJson(_object(decoded));
  }

  Future<MonthlySummaryReport> fetchSummary({required int month, required int year}) async {
    final decoded = await _api.getJson(
      '/api/v1/team/attendance/summary',
      queryParameters: {'month': '$month', 'year': '$year'},
    );
    return MonthlySummaryReport.fromJson(_object(decoded));
  }

  Future<List<AttendanceRecordRow>> fetchRecords({required int month, required int year}) async {
    final decoded = await _api.getJson(
      '/api/v1/team/attendance/records',
      queryParameters: {'month': '$month', 'year': '$year'},
    );
    return [for (final e in teamList(decoded['data'])) AttendanceRecordRow.fromJson(e)];
  }

  Future<List<TeamLeaveRequest>> fetchLeaveRequests({String? status}) async {
    final decoded = await _api.getJson(
      '/api/v1/team/leave-requests',
      queryParameters: status == null || status.isEmpty ? null : {'status': status},
    );
    return [for (final e in teamList(decoded['data'])) TeamLeaveRequest.fromJson(e)];
  }

  Future<TeamOnLeaveDay> fetchOnLeave(DateTime date) async {
    final decoded = await _api.getJson('/api/v1/team/on-leave', queryParameters: {'date': _ymd.format(date)});
    return TeamOnLeaveDay.fromJson(_object(decoded));
  }

  Future<List<TeamLeaveBalance>> fetchLeaveBalances() async {
    final decoded = await _api.getJson('/api/v1/team/leave-balances');
    return [for (final e in teamList(decoded['data'])) TeamLeaveBalance.fromJson(e)];
  }

  Future<TeamLeaveBalanceDetail> fetchLeaveBalanceLogs(int employeeId) async {
    final decoded = await _api.getJson('/api/v1/team/leave-balances/$employeeId');
    return TeamLeaveBalanceDetail.fromJson(_object(decoded));
  }

  Future<TeamHubSnapshot> fetchHub() async {
    final members = await fetchMembers();
    var pending = const <TeamLeaveRequest>[];
    var onLeave = const <TeamLeaveRequest>[];
    try {
      pending = await fetchLeaveRequests(status: 'pending');
    } catch (_) {}
    try {
      onLeave = (await fetchOnLeave(DateTime.now())).leaves;
    } catch (_) {}
    return TeamHubSnapshot(members: members, pendingRequests: pending, onLeaveToday: onLeave);
  }
}

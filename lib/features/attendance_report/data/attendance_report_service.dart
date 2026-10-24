import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_status_calendar.dart';
import 'package:attendance/services/api_client.dart';

String _str(Object? v) => v == null ? '' : v.toString();
String? _strOrNull(Object? v) => v == null || v.toString().trim().isEmpty ? null : v.toString();
int _int(Object? v) => int.tryParse(_str(v)) ?? 0;
bool _bool(Object? v) => v == true || v == 1 || v == '1' || _str(v).toLowerCase() == 'true';
Map<String, dynamic> _map(Object? v) => v is Map<String, dynamic> ? v : const {};
List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map<String, dynamic>) e,
];

class ReportEmployee {
  const ReportEmployee({required this.id, required this.name, this.email, this.department, this.designation});

  final int id;
  final String name;
  final String? email;
  final String? department;
  final String? designation;

  factory ReportEmployee.fromJson(Map<String, dynamic> j) => ReportEmployee(
    id: _int(j['id']),
    name: _str(j['name']),
    email: _strOrNull(j['email']),
    department: _strOrNull(j['department']),
    designation: _strOrNull(j['designation']),
  );
}

/// Visual treatment shared by every attendance status in the reports.
class AttendanceStatusStyle {
  const AttendanceStatusStyle(this.label, this.color, this.tone);

  final String label;
  final Color color;
  final AppCalendarTone tone;

  Color get soft => color.withValues(alpha: 0.12);

  static AttendanceStatusStyle of(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const AttendanceStatusStyle('Present', AppColors.calendarPresent, AppCalendarTone.success);
      case 'wfh':
        return const AttendanceStatusStyle('WFH', AppColors.calendarWfh, AppCalendarTone.accent);
      case 'leave':
      case 'on_leave':
      case 'paid_leave':
        return const AttendanceStatusStyle('Leave', AppColors.calendarLeave, AppCalendarTone.warning);
      case 'unpaid_leave':
        return const AttendanceStatusStyle('Unpaid leave', AppColors.calendarLeave, AppCalendarTone.warning);
      case 'absent':
        return const AttendanceStatusStyle('Absent', AppColors.calendarAbsent, AppCalendarTone.error);
      case 'holiday':
        return const AttendanceStatusStyle('Holiday', AppColors.calendarHoliday, AppCalendarTone.info);
      case 'week_off':
        return const AttendanceStatusStyle('Week off', AppColors.calendarWeekOff, AppCalendarTone.weekOff);
      case 'upcoming':
        return const AttendanceStatusStyle('Upcoming', AppColors.textSecondary, AppCalendarTone.neutral);
      case 'not_marked':
      default:
        return const AttendanceStatusStyle('Not marked', AppColors.textSecondary, AppCalendarTone.neutral);
    }
  }
}

/// `07:07:18` → `7:07 AM`
String formatReportTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final parts = raw.split(':');
  final h = int.tryParse(parts.first);
  final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (h == null || m == null) return raw;
  return DateFormat.jm().format(DateTime(2000, 1, 1, h, m));
}

class AttendanceRecordRow {
  const AttendanceRecordRow({
    required this.id,
    required this.employee,
    required this.date,
    required this.status,
    required this.isLate,
    this.checkIn,
    this.checkOut,
    this.leaveReason,
    this.notes,
    this.markedBy,
  });

  final int id;
  final ReportEmployee employee;
  final String date;
  final String status;
  final bool isLate;
  final String? checkIn;
  final String? checkOut;
  final String? leaveReason;
  final String? notes;
  final String? markedBy;

  factory AttendanceRecordRow.fromJson(Map<String, dynamic> j) => AttendanceRecordRow(
    id: _int(j['id']),
    employee: ReportEmployee.fromJson(_map(j['employee'])),
    date: _str(j['attendance_date']),
    status: _str(j['status']),
    isLate: _bool(j['is_late']),
    checkIn: _strOrNull(j['check_in']),
    checkOut: _strOrNull(j['check_out']),
    leaveReason: _strOrNull(j['leave_reason']),
    notes: _strOrNull(j['notes']),
    markedBy: _strOrNull(_map(j['marked_by'])['name']),
  );
}

class AttendanceSummaryCounts {
  const AttendanceSummaryCounts({
    required this.workingDays,
    required this.present,
    required this.wfh,
    required this.leave,
    required this.paidLeave,
    required this.unpaidLeave,
    required this.absent,
    required this.holiday,
    required this.weekOff,
    required this.late,
    required this.notMarked,
    required this.paidDays,
  });

  final int workingDays;
  final int present;
  final int wfh;
  final int leave;
  final int paidLeave;
  final int unpaidLeave;
  final int absent;
  final int holiday;
  final int weekOff;
  final int late;
  final int notMarked;
  final int paidDays;

  factory AttendanceSummaryCounts.fromJson(Map<String, dynamic> j) => AttendanceSummaryCounts(
    workingDays: _int(j['working_days']),
    present: _int(j['present']),
    wfh: _int(j['wfh']),
    leave: _int(j['leave']),
    paidLeave: _int(j['paid_leave']),
    unpaidLeave: _int(j['unpaid_leave']),
    absent: _int(j['absent']),
    holiday: _int(j['holiday']),
    weekOff: _int(j['week_off']),
    late: _int(j['late']),
    notMarked: _int(j['not_marked']),
    paidDays: _int(j['paid_days']),
  );
}

class EmployeeMonthSummary {
  const EmployeeMonthSummary({required this.employee, required this.counts});

  final ReportEmployee employee;
  final AttendanceSummaryCounts counts;
}

class MonthlySummaryReport {
  const MonthlySummaryReport({
    required this.from,
    required this.to,
    required this.weekOffs,
    required this.holidays,
    required this.workingDays,
    required this.employees,
  });

  final String from;
  final String to;
  final List<String> weekOffs;
  final List<String> holidays;
  final int workingDays;
  final List<EmployeeMonthSummary> employees;

  factory MonthlySummaryReport.fromJson(Map<String, dynamic> j) => MonthlySummaryReport(
    from: _str(j['from']),
    to: _str(j['to']),
    weekOffs: [for (final v in (j['week_offs'] as List? ?? const [])) v.toString()],
    holidays: [for (final v in (j['holidays'] as List? ?? const [])) v.toString()],
    workingDays: _int(j['working_days']),
    employees: [
      for (final e in _list(j['employees']))
        EmployeeMonthSummary(
          employee: ReportEmployee.fromJson(_map(e['employee'])),
          counts: AttendanceSummaryCounts.fromJson(e),
        ),
    ],
  );
}

class DailyEmployeeRow {
  const DailyEmployeeRow({
    required this.employee,
    required this.status,
    required this.isLate,
    this.attendanceId,
    this.checkIn,
    this.checkOut,
    this.leaveReason,
    this.notes,
    this.markedBy,
  });

  final ReportEmployee employee;
  final String status;
  final bool isLate;
  final int? attendanceId;
  final String? checkIn;
  final String? checkOut;
  final String? leaveReason;
  final String? notes;
  final String? markedBy;

  factory DailyEmployeeRow.fromJson(Map<String, dynamic> j) => DailyEmployeeRow(
    employee: ReportEmployee.fromJson(_map(j['employee'])),
    status: _str(j['status']),
    isLate: _bool(j['is_late']),
    attendanceId: j['attendance_id'] == null ? null : _int(j['attendance_id']),
    checkIn: _strOrNull(j['check_in']),
    checkOut: _strOrNull(j['check_out']),
    leaveReason: _strOrNull(j['leave_reason']),
    notes: _strOrNull(j['notes']),
    markedBy: _strOrNull(_map(j['marked_by'])['name']),
  );
}

class DailyReport {
  const DailyReport({
    required this.date,
    required this.day,
    required this.isWeekOff,
    required this.holiday,
    required this.totals,
    required this.employees,
  });

  final String date;
  final String day;
  final bool isWeekOff;
  final String? holiday;

  /// e.g. `{present: 2, not_marked: 2, late: 0, employees: 4}`
  final Map<String, int> totals;
  final List<DailyEmployeeRow> employees;

  factory DailyReport.fromJson(Map<String, dynamic> j) => DailyReport(
    date: _str(j['date']),
    day: _str(j['day']),
    isWeekOff: _bool(j['is_week_off']),
    holiday: _strOrNull(j['holiday']),
    totals: {for (final e in _map(j['totals']).entries) e.key: _int(e.value)},
    employees: [for (final e in _list(j['employees'])) DailyEmployeeRow.fromJson(e)],
  );
}

class CalendarDayRow {
  const CalendarDayRow({
    required this.date,
    required this.day,
    required this.status,
    required this.isWeekOff,
    required this.isLate,
    this.holiday,
    this.checkIn,
    this.checkOut,
    this.leaveReason,
    this.notes,
    this.markedBy,
  });

  final String date;
  final String day;
  final String status;
  final bool isWeekOff;
  final bool isLate;
  final String? holiday;
  final String? checkIn;
  final String? checkOut;
  final String? leaveReason;
  final String? notes;
  final String? markedBy;

  factory CalendarDayRow.fromJson(Map<String, dynamic> j) => CalendarDayRow(
    date: _str(j['date']),
    day: _str(j['day']),
    status: _str(j['status']),
    isWeekOff: _bool(j['is_week_off']),
    isLate: _bool(j['is_late']),
    holiday: _strOrNull(j['holiday']),
    checkIn: _strOrNull(j['check_in']),
    checkOut: _strOrNull(j['check_out']),
    leaveReason: _strOrNull(j['leave_reason']),
    notes: _strOrNull(j['notes']),
    markedBy: _strOrNull(_map(j['marked_by'])['name']),
  );
}

class EmployeeCalendarReport {
  const EmployeeCalendarReport({required this.employee, required this.summary, required this.days});

  final ReportEmployee employee;
  final AttendanceSummaryCounts summary;
  final List<CalendarDayRow> days;

  factory EmployeeCalendarReport.fromJson(Map<String, dynamic> j) => EmployeeCalendarReport(
    employee: ReportEmployee.fromJson(_map(j['employee'])),
    summary: AttendanceSummaryCounts.fromJson(_map(j['summary'])),
    days: [for (final e in _list(j['days'])) CalendarDayRow.fromJson(e)],
  );
}

class AttendanceReportService {
  AttendanceReportService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  static final _ymd = DateFormat('yyyy-MM-dd');

  Map<String, dynamic> _data(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return data;
  }

  Future<List<AttendanceRecordRow>> fetchRecords({required DateTime from, required DateTime to}) async {
    final decoded = await _api.getJson(
      '/api/v1/attendance',
      queryParameters: {'from': _ymd.format(from), 'to': _ymd.format(to)},
    );
    return [for (final e in _list(decoded['data'])) AttendanceRecordRow.fromJson(e)];
  }

  Future<DailyReport> fetchDaily(DateTime date) async {
    final decoded = await _api.getJson('/api/v1/attendance/daily', queryParameters: {'date': _ymd.format(date)});
    return DailyReport.fromJson(_data(decoded));
  }

  Future<MonthlySummaryReport> fetchSummary({required int month, required int year}) async {
    final decoded = await _api.getJson(
      '/api/v1/attendance/summary',
      queryParameters: {'month': '$month', 'year': '$year'},
    );
    return MonthlySummaryReport.fromJson(_data(decoded));
  }

  Future<EmployeeCalendarReport> fetchEmployeeCalendar({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final decoded = await _api.getJson(
      '/api/v1/attendance/calendar',
      queryParameters: {'employee_id': '$employeeId', 'month': '$month', 'year': '$year'},
    );
    return EmployeeCalendarReport.fromJson(_data(decoded));
  }
}

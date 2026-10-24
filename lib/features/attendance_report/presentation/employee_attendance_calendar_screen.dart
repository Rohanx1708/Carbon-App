import 'package:flutter/material.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_calendar.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';

/// One employee's month: summary counts plus a colour-coded calendar of every day.
class EmployeeAttendanceCalendarScreen extends StatefulWidget {
  const EmployeeAttendanceCalendarScreen({super.key, required this.employee, required this.month});

  final ReportEmployee employee;

  /// Any day in the month to open on.
  final DateTime month;

  @override
  State<EmployeeAttendanceCalendarScreen> createState() => _EmployeeAttendanceCalendarScreenState();
}

class _EmployeeAttendanceCalendarScreenState extends State<EmployeeAttendanceCalendarScreen>
    with ReportLoader<EmployeeAttendanceCalendarScreen, EmployeeCalendarReport> {
  final _service = AttendanceReportService();
  late DateTime _month = DateTime(widget.month.year, widget.month.month);

  static const _legend = [
    AppCalendarLegend('Present', AppCalendarTone.success),
    AppCalendarLegend('WFH', AppCalendarTone.accent),
    AppCalendarLegend('Leave', AppCalendarTone.warning),
    AppCalendarLegend('Holiday', AppCalendarTone.info),
    AppCalendarLegend('Absent', AppCalendarTone.error),
    AppCalendarLegend('Week off', AppCalendarTone.weekOff),
    AppCalendarLegend('Today', AppCalendarTone.today, outlined: true),
  ];

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<EmployeeCalendarReport> fetch() =>
      _service.fetchEmployeeCalendar(employeeId: widget.employee.id, month: _month.month, year: _month.year);

  void _onMonthChanged(DateTime month) {
    if (month.year == _month.year && month.month == _month.month) return;
    _month = month;
    reload();
  }

  Widget _summary(AttendanceSummaryCounts s) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Month summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
              ),
              Text(
                '${s.paidDays} paid / ${s.workingDays} working days',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReportStatGrid(
            stats: [
              ReportStat(label: 'Present', value: s.present, color: AppColors.calendarPresent),
              ReportStat(label: 'WFH', value: s.wfh, color: AppColors.calendarWfh),
              ReportStat(label: 'Leave', value: s.leave, color: AppColors.calendarLeave),
              ReportStat(label: 'Absent', value: s.absent, color: AppColors.calendarAbsent),
              ReportStat(label: 'Late', value: s.late, color: const Color(0xFFEA580C)),
              ReportStat(label: 'Holiday', value: s.holiday, color: AppColors.calendarHoliday),
              ReportStat(label: 'Week off', value: s.weekOff, color: AppColors.calendarWeekOff),
              ReportStat(label: 'Not marked', value: s.notMarked, color: AppColors.textSecondary),
            ],
          ),
          if (s.paidLeave > 0 || s.unpaidLeave > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Leave: ${s.paidLeave} paid · ${s.unpaidLeave} unpaid',
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayTile(CalendarDayRow d) {
    final style = AttendanceStatusStyle.of(d.status);
    final times = [
      if (d.checkIn != null) 'In ${formatReportTime(d.checkIn)}',
      if (d.checkOut != null) 'Out ${formatReportTime(d.checkOut)}',
    ];
    return AppListTile(
      leading: AppListTileLeading.icon(Icons.event_available_outlined, accent: style.color),
      title: '${AppDateFormat.fromRaw(d.date)} · ${d.day}',
      subtitleLines: [
        if (d.holiday != null) d.holiday!,
        if (times.isNotEmpty) times.join(' · '),
        if (d.isLate) 'Late arrival',
        if (d.leaveReason != null) 'Reason: ${d.leaveReason}',
        if (d.notes != null && d.notes != d.holiday) d.notes!,
        if (d.markedBy != null) 'Marked by ${d.markedBy}',
      ],
      trailing: ReportStatusBadge(d.status),
      showChevron: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = data;
    final e = widget.employee;
    return Scaffold(
      appBar: GradientAppBar(title: e.name, showBack: true, showProfileAction: false),
      body: AppContentContainer(
        padding: const EdgeInsets.all(16),
        child: AppLoadingState(
          isLoading: loading,
          hasLoaded: hasLoaded,
          hasData: report != null,
          refreshing: refreshing,
          error: error,
          onRetry: reload,
          onRefresh: reload,
          loading: const AppSkeletonList(header: AppSkeletonBlock(height: 520)),
          child: report == null
              ? const SizedBox.shrink()
              : AppStatusCalendarView<CalendarDayRow>(
                  initialMonth: _month,
                  onMonthChanged: _onMonthChanged,
                  onRefresh: reload,
                  items: report.days.where((d) => d.status != 'upcoming').toList(),
                  daysOf: (d) => appCalendarDaysBetween(d.date, d.date),
                  toneOf: (d) => AttendanceStatusStyle.of(d.status).tone,
                  legend: _legend,
                  emptyMessage: 'No attendance for these dates yet',
                  header: _summary(report.summary),
                  itemBuilder: (context, d) => _dayTile(d),
                ),
        ),
      ),
    );
  }
}

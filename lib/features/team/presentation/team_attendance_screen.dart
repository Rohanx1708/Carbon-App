import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/team/data/team_models.dart';
import 'package:attendance/features/team/data/team_service.dart';
import 'package:attendance/features/team/presentation/team_member_detail_screen.dart';

class TeamAttendanceScreen extends StatelessWidget {
  const TeamAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const GradientAppBar(title: 'Team attendance', showBack: true, showProfileAction: false),
        body: Column(
          children: [
            Material(
              color: scheme.surface,
              child: const TabBar(
                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(icon: Icon(Icons.today_outlined, size: 20), text: 'Daily'),
                  Tab(icon: Icon(Icons.calendar_month_outlined, size: 20), text: 'Monthly'),
                  Tab(icon: Icon(Icons.list_alt_outlined, size: 20), text: 'Records'),
                ],
              ),
            ),
            const Expanded(child: TabBarView(children: [_DailyTab(), _MonthlyTab(), _RecordsTab()])),
          ],
        ),
      ),
    );
  }
}

void _openMember(BuildContext context, ReportEmployee employee, {TeamTodayStatus? today}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TeamMemberDetailScreen(
        member: TeamMember.fromEmployee(employee: employee, today: today),
      ),
    ),
  );
}

class _DailyTab extends StatefulWidget {
  const _DailyTab();

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab> with AutomaticKeepAliveClientMixin, ReportLoader<_DailyTab, DailyReport> {
  final _service = TeamService();
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  @override
  bool get wantKeepAlive => true;

  @override
  Duration get cacheTtl => CachePolicy.teamTtl;

  @override
  String get cacheKey => 'team-daily:${_date.toIso8601String()}';

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<DailyReport> fetch() => _service.fetchAttendance(_date);

  void _setDate(DateTime d) {
    setState(() => _date = DateUtils.dateOnly(d));
    loadIfNeeded();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) _setDate(picked);
  }

  Widget _header(DailyReport r) {
    final t = r.totals;
    const known = {'present', 'late', 'not_marked', 'employees'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.holiday != null || r.isWeekOff) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (r.holiday != null ? AppColors.info : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  r.holiday != null ? Icons.celebration_outlined : Icons.weekend_outlined,
                  color: r.holiday != null ? AppColors.info : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.holiday != null ? 'Holiday · ${r.holiday}' : 'Week off',
                    style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ReportStatGrid(
          stats: [
            ReportStat(label: 'People', value: t['employees'] ?? r.employees.length, color: AppColors.primary),
            ReportStat(label: 'Present', value: t['present'] ?? 0, color: AppColors.success),
            ReportStat(label: 'Late', value: t['late'] ?? 0, color: const Color(0xFFEA580C)),
            ReportStat(label: 'Not marked', value: t['not_marked'] ?? 0, color: AppColors.textSecondary),
            for (final e in t.entries)
              if (!known.contains(e.key) && e.value > 0)
                ReportStat(
                  label: AttendanceStatusStyle.of(e.key).label,
                  value: e.value,
                  color: AttendanceStatusStyle.of(e.key).color,
                ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = data;
    final today = DateUtils.dateOnly(DateTime.now());
    return AppContentContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ReportPeriodBar(
            icon: Icons.today_outlined,
            label: _date == today
                ? 'Today · ${AppDateFormat.date(_date)}'
                : DateFormat('EEE, d MMM yyyy').format(_date),
            onPrevious: () => _setDate(_date.subtract(const Duration(days: 1))),
            onNext: () => _setDate(_date.add(const Duration(days: 1))),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppLoadingState(
              isLoading: loading,
              hasLoaded: hasLoaded,
              hasData: r != null && r.employees.isNotEmpty,
              refreshing: refreshing,
              error: error,
              onRetry: reload,
              onRefresh: reload,
              empty: const AppEmptyState(
                icon: Icons.groups_outlined,
                title: 'No team attendance',
                message: 'There is no attendance to show for this day',
              ),
              child: r == null
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: r.employees.length + 1,
                      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : kAppListTileSpacing),
                      itemBuilder: (context, i) {
                        if (i == 0) return _header(r);
                        final row = r.employees[i - 1];
                        final times = [
                          if (row.checkIn != null) 'In ${formatReportTime(row.checkIn)}',
                          if (row.checkOut != null) 'Out ${formatReportTime(row.checkOut)}',
                        ];
                        return AppListTile(
                          leading: AppListTileLeading.initials(row.employee.name),
                          title: row.employee.name,
                          subtitleLines: [
                            [row.employee.designation, row.employee.department].whereType<String>().join(' · '),
                            if (times.isNotEmpty) times.join(' · '),
                            if (row.isLate) 'Late arrival',
                            if (row.leaveReason != null) 'Reason: ${row.leaveReason}',
                          ].where((s) => s.isNotEmpty).toList(),
                          trailing: ReportStatusBadge(row.status),
                          onTap: () => _openMember(
                            context,
                            row.employee,
                            today: TeamTodayStatus(
                              status: row.status,
                              isLate: row.isLate,
                              checkIn: row.checkIn,
                              checkOut: row.checkOut,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTab extends StatefulWidget {
  const _MonthlyTab();

  @override
  State<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<_MonthlyTab>
    with AutomaticKeepAliveClientMixin, ReportLoader<_MonthlyTab, MonthlySummaryReport> {
  final _service = TeamService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  bool get wantKeepAlive => true;

  @override
  Duration get cacheTtl => CachePolicy.reportTtl;

  @override
  String get cacheKey => 'team-monthly:${_month.year}-${_month.month}';

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<MonthlySummaryReport> fetch() => _service.fetchSummary(month: _month.month, year: _month.year);

  void _shift(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
    loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = data;
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return AppContentContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ReportPeriodBar(
            label: DateFormat('MMMM yyyy').format(_month),
            onPrevious: () => _shift(-1),
            onNext: isCurrent ? null : () => _shift(1),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppLoadingState(
              isLoading: loading,
              hasLoaded: hasLoaded,
              hasData: r != null && r.employees.isNotEmpty,
              refreshing: refreshing,
              error: error,
              onRetry: reload,
              onRefresh: reload,
              loading: const AppSkeletonList(itemCount: 4),
              empty: const AppEmptyState(
                icon: Icons.insert_chart_outlined,
                title: 'No summary yet',
                message: 'Team attendance for this month will appear here',
              ),
              child: r == null
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: r.employees.length + 1,
                      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : kAppListTileSpacing),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ReportCard(
                              child: Row(
                                children: [
                                  _Fact(icon: Icons.work_outline, label: 'Working days', value: '${r.workingDays}'),
                                  _Fact(
                                    icon: Icons.celebration_outlined,
                                    label: 'Holidays',
                                    value: '${r.holidays.length}',
                                  ),
                                  _Fact(
                                    icon: Icons.weekend_outlined,
                                    label: 'Week off',
                                    value: r.weekOffs.isEmpty
                                        ? '—'
                                        : r.weekOffs.map((d) => d.length > 3 ? d.substring(0, 3) : d).join(', '),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final s = r.employees[i - 1];
                        final c = s.counts;
                        return AppListTile(
                          leading: AppListTileLeading.initials(s.employee.name),
                          title: s.employee.name,
                          subtitle: s.employee.department,
                          trailing: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${c.paidDays}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
                                ),
                                TextSpan(
                                  text: ' paid days',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => _openMember(context, s.employee),
                          footer: ReportStatGrid(
                            stats: [
                              ReportStat(label: 'Present', value: c.present, color: AppColors.calendarPresent),
                              ReportStat(label: 'WFH', value: c.wfh, color: AppColors.calendarWfh),
                              ReportStat(label: 'Leave', value: c.leave, color: AppColors.calendarLeave),
                              ReportStat(label: 'Absent', value: c.absent, color: AppColors.calendarAbsent),
                              ReportStat(label: 'Late', value: c.late, color: const Color(0xFFEA580C)),
                              ReportStat(label: 'Holiday', value: c.holiday, color: AppColors.calendarHoliday),
                              ReportStat(label: 'Week off', value: c.weekOff, color: AppColors.calendarWeekOff),
                              ReportStat(label: 'Not marked', value: c.notMarked, color: AppColors.textSecondary),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary),
          ),
          Text(label, style: TextStyle(fontSize: 11.5, color: context.textSecondary)),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatefulWidget {
  const _RecordsTab();

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab>
    with AutomaticKeepAliveClientMixin, ReportLoader<_RecordsTab, List<AttendanceRecordRow>> {
  final _service = TeamService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  bool get wantKeepAlive => true;

  @override
  Duration get cacheTtl => CachePolicy.reportTtl;

  @override
  String get cacheKey => 'team-records:${_month.year}-${_month.month}';

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<List<AttendanceRecordRow>> fetch() => _service.fetchRecords(month: _month.month, year: _month.year);

  void _shift(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
    loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rows = data ?? const <AttendanceRecordRow>[];
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return AppContentContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ReportPeriodBar(
            icon: Icons.date_range_outlined,
            label: DateFormat('MMMM yyyy').format(_month),
            onPrevious: () => _shift(-1),
            onNext: isCurrent ? null : () => _shift(1),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppLoadingState(
              isLoading: loading,
              hasLoaded: hasLoaded,
              hasData: rows.isNotEmpty,
              refreshing: refreshing,
              error: error,
              onRetry: reload,
              onRefresh: reload,
              empty: const AppEmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No records',
                message: 'No team attendance was recorded in this month',
              ),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: kAppListTileSpacing),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final times = [
                    if (r.checkIn != null) 'In ${formatReportTime(r.checkIn)}',
                    if (r.checkOut != null) 'Out ${formatReportTime(r.checkOut)}',
                  ];
                  return AppListTile(
                    leading: AppListTileLeading.initials(r.employee.name),
                    title: r.employee.name,
                    subtitleLines: [
                      [
                        AppDateFormat.fromRaw(r.date),
                        if (r.employee.department != null) r.employee.department!,
                      ].join(' · '),
                      if (times.isNotEmpty) times.join(' · '),
                      if (r.isLate) 'Late arrival',
                      if (r.leaveReason != null) 'Reason: ${r.leaveReason}',
                      if (r.notes != null) r.notes!,
                    ],
                    trailing: ReportStatusBadge(r.status),
                    onTap: () => _openMember(context, r.employee),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

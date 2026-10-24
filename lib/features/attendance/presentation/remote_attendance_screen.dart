import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_status_calendar.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/data/remote_attendance_models.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/attendance/presentation/attendance_action_dialogs.dart';
import 'package:attendance/features/attendance/presentation/remote_attendance_detail_screen.dart';
import 'package:attendance/features/settings/presentation/office_week_offs_builder.dart';
import 'package:attendance/state/employee_provider.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/remote_attendance_provider.dart';

class RemoteAttendanceScreen extends StatefulWidget {
  const RemoteAttendanceScreen({super.key});

  @override
  State<RemoteAttendanceScreen> createState() => _RemoteAttendanceScreenState();
}

class _RemoteAttendanceScreenState extends State<RemoteAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemoteAttendanceProvider>().loadIfNeeded();
      context.read<ProfileProvider>().loadIfNeeded();
    });
  }

  String _labelize(String raw) {
    if (raw.isEmpty) return 'Pending';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  (Color fg, Color bg) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return (AppColors.calendarPresent, AppColors.calendarPresent.withValues(alpha: 0.12));
      case 'absent':
        return (AppColors.calendarAbsent, AppColors.calendarAbsent.withValues(alpha: 0.12));
      case 'holiday':
        return (AppColors.calendarHoliday, AppColors.calendarHoliday.withValues(alpha: 0.12));
      case 'leave':
      case 'on_leave':
        return (AppColors.calendarLeave, AppColors.calendarLeave.withValues(alpha: 0.12));
      case 'wfh':
        return (AppColors.calendarWfh, AppColors.calendarWfh.withValues(alpha: 0.12));
      case 'week_off':
        return (AppColors.calendarWeekOff, AppColors.calendarWeekOff.withValues(alpha: 0.12));
      default:
        return (AppColors.textSecondary, AppColors.background);
    }
  }

  AppCalendarTone _calendarTone(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppCalendarTone.success;
      case 'absent':
        return AppCalendarTone.error;
      case 'leave':
      case 'on_leave':
        return AppCalendarTone.warning;
      case 'holiday':
        return AppCalendarTone.info;
      case 'wfh':
        return AppCalendarTone.accent;
      case 'week_off':
        return AppCalendarTone.weekOff;
      default:
        return AppCalendarTone.neutral;
    }
  }

  Future<void> _checkIn() async {
    final ok = await context.read<RemoteAttendanceProvider>().checkIn();
    if (!mounted) return;
    if (!ok) {
      AppFeedback.error(context, context.read<RemoteAttendanceProvider>().error ?? Exception('Check-in failed'));
      return;
    }
    AppFeedback.success(context, 'Checked in');
  }

  Future<void> _checkOut() async {
    final ok = await context.read<RemoteAttendanceProvider>().checkOut();
    if (!mounted) return;
    if (!ok) {
      AppFeedback.error(context, context.read<RemoteAttendanceProvider>().error ?? Exception('Check-out failed'));
      return;
    }
    AppFeedback.success(context, 'Checked out');
  }

  Future<void> _markHoliday() async {
    final result = await showMarkHolidayDialog(context);
    if (result == null || !mounted) return;

    final success = await context.read<RemoteAttendanceProvider>().markHoliday(date: result.date, notes: result.notes);
    if (!mounted) return;
    if (!success) {
      AppFeedback.error(context, context.read<RemoteAttendanceProvider>().error ?? Exception('Failed'));
      return;
    }
    AppFeedback.success(context, 'Holiday marked for everyone');
  }

  Future<void> _markAttendance() async {
    await context.read<EmployeeProvider>().loadIfNeeded();
    if (!mounted) return;
    final employees = context.read<EmployeeProvider>().employees;
    if (employees.isEmpty) {
      AppFeedback.info(context, 'No employees loaded');
      return;
    }

    final result = await showMarkAttendanceDialog(context, employees: employees);
    if (result == null || !mounted) return;

    final success = await context.read<RemoteAttendanceProvider>().markAttendance(
      employeeId: result.employeeId,
      attendanceDate: result.attendanceDate,
      status: result.status,
      checkIn: result.checkIn,
      checkOut: result.checkOut,
    );
    if (!mounted) return;
    if (!success) {
      AppFeedback.error(context, context.read<RemoteAttendanceProvider>().error ?? Exception('Failed'));
      return;
    }
    AppFeedback.success(context, 'Attendance saved');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RemoteAttendanceProvider>();
    final profile = context.watch<ProfileProvider>();
    final canSelfPunch = profile.canSelfPunchAttendance;
    final canMarkTeam = profile.canMarkTeamAttendance;
    final showMenu = (canSelfPunch || canMarkTeam) && !provider.acting;

    return Stack(
      children: [
        Scaffold(
          drawer: const AppDrawer(),
          appBar: GradientAppBar(
            title: 'Attendance',
            actions: [
              if (showMenu)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    switch (value) {
                      case 'check_in':
                        await _checkIn();
                      case 'check_out':
                        await _checkOut();
                      case 'holiday':
                        await _markHoliday();
                      case 'mark':
                        await _markAttendance();
                    }
                  },
                  itemBuilder: (context) => [
                    if (canSelfPunch) ...[
                      const PopupMenuItem(value: 'check_in', child: Text('Check in')),
                      const PopupMenuItem(value: 'check_out', child: Text('Check out')),
                    ],
                    if (canMarkTeam) ...[
                      if (canSelfPunch) const PopupMenuDivider(),
                      const PopupMenuItem(value: 'holiday', child: Text('Mark holiday')),
                      const PopupMenuItem(value: 'mark', child: Text('Mark attendance')),
                    ],
                  ],
                ),
            ],
          ),
          body: AppContentContainer(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            child: AppLoadingState(
              isLoading: provider.loading,
              hasLoaded: provider.hasLoaded,
              hasData: provider.records.isNotEmpty,
              refreshing: provider.refreshing,
              error: provider.error,
              onRetry: provider.refresh,
              onRefresh: provider.refresh,
              loading: const AppSkeletonList(header: AppSkeletonBlock(height: 400)),
              empty: AppEmptyState(
                icon: Icons.access_time_outlined,
                title: 'No attendance records',
                message: canMarkTeam
                    ? 'Mark attendance or a company holiday from the menu'
                    : 'Use Check in from the menu to start',
              ),
              child: OfficeWeekOffsBuilder(
                builder: (context, weekOffs) => AppStatusCalendarView<RemoteAttendanceRecord>(
                  weekOffs: weekOffs,
                  items: provider.records,
                  daysOf: (r) => appCalendarDaysBetween(r.attendanceDate, r.attendanceDate),
                  toneOf: (r) => _calendarTone(r.status),
                  emptyMessage: 'No attendance on these dates',
                  legend: const [
                    AppCalendarLegend('Present', AppCalendarTone.success),
                    AppCalendarLegend('WFH', AppCalendarTone.accent),
                    AppCalendarLegend('Leave', AppCalendarTone.warning),
                    AppCalendarLegend('Holiday', AppCalendarTone.info),
                    AppCalendarLegend('Absent', AppCalendarTone.error),
                    AppCalendarLegend('Week off', AppCalendarTone.weekOff),
                    AppCalendarLegend('Today', AppCalendarTone.today, outlined: true),
                  ],
                  itemBuilder: (context, r) {
                    final (fg, bg) = _statusColors(r.status);
                    final timeLine = <String>[
                      if (r.checkIn != null && r.checkIn!.isNotEmpty) 'In: ${r.checkIn}',
                      if (r.checkOut != null && r.checkOut!.isNotEmpty) 'Out: ${r.checkOut}',
                    ];
                    return AppListTile(
                      leading: AppListTileLeading.icon(Icons.access_time, accent: fg),
                      title: r.employeeDisplayName,
                      subtitleLines: [
                        if (r.attendanceDate.isNotEmpty) AppDateFormat.fromRaw(r.attendanceDate),
                        if (r.employee?.department.isNotEmpty == true) r.employee!.department,
                        if (timeLine.isNotEmpty) timeLine.join(' · '),
                        if (r.isLate) 'Late arrival',
                      ],
                      trailing: AppStatusBadge(label: _labelize(r.status), foregroundColor: fg, backgroundColor: bg),
                      showChevron: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RemoteAttendanceDetailScreen(attendanceId: r.id, initial: r),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (provider.acting) const Positioned.fill(child: AppBusyOverlay(busy: true, child: SizedBox.expand())),
      ],
    );
  }
}

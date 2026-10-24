import 'package:flutter/material.dart';
import 'package:attendance/features/settings/presentation/office_week_offs_builder.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_status_calendar.dart';
import 'package:attendance/features/leave_request/data/leave_request_models.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/leave_request/presentation/leave_request_detail_screen.dart';
import 'package:attendance/features/leave_request/presentation/leave_request_form_screen.dart';
import 'package:attendance/state/leave_request_provider.dart';
import 'package:attendance/state/profile_provider.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveRequestProvider>().loadIfNeeded();
    });
  }

  (Color fg, Color bg) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (AppColors.success, AppColors.successSoft);
      case 'rejected':
      case 'cancelled':
      case 'canceled':
        return (AppColors.error, AppColors.errorSoft);
      case 'pending':
      default:
        return (AppColors.warning, AppColors.warningSoft);
    }
  }

  String _label(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveRequestProvider>();
    final canSubmit = context.watch<ProfileProvider>().canSubmitLeaveRequest;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Leave'),
      floatingActionButton: canSubmit
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => const LeaveRequestFormScreen()));
                if (created == true && context.mounted) {
                  await provider.refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Request leave'),
            )
          : null,
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: AppLoadingState(
          isLoading: provider.loading,
          hasLoaded: provider.hasLoaded,
          hasData: provider.requests.isNotEmpty,
          refreshing: provider.refreshing,
          error: provider.error,
          onRetry: provider.refresh,
          onRefresh: provider.refresh,
          loading: const AppSkeletonList(header: AppSkeletonBlock(height: 400)),
          empty: AppEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No leave requests',
            message: canSubmit ? 'Tap Request leave to submit a new request' : 'Leave requests will appear here',
          ),
          child: OfficeWeekOffsBuilder(
            builder: (context, weekOffs) => AppStatusCalendarView<LeaveRequestItem>(
              weekOffs: weekOffs,
              items: provider.requests,
              daysOf: (r) => appCalendarDaysBetween(r.startDate, r.endDate),
              toneOf: (r) => appRequestCalendarTone(r.status),
              emptyMessage: 'No leave requests on these dates',
              legend: kAppRequestCalendarLegend,
              itemBuilder: (context, r) {
                final (fg, bg) = _statusColors(r.status);
                return AppListTile(
                  leading: AppListTileLeading.icon(Icons.event_busy_outlined, accent: fg),
                  title: r.employeeDisplayName,
                  subtitleLines: [
                    if (r.dateRangeLabel.isNotEmpty) 'Dates: ${r.dateRangeLabel}',
                    if (r.reason.trim().isNotEmpty) r.reason.trim(),
                    if (r.employee?.department.isNotEmpty == true) r.employee!.department,
                  ],
                  trailing: AppStatusBadge(label: _label(r.status), foregroundColor: fg, backgroundColor: bg),
                  onTap: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => LeaveRequestDetailScreen(requestId: r.id, initial: r),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      await provider.refresh();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

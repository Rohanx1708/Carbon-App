import 'package:flutter/material.dart';
import 'package:attendance/features/settings/presentation/office_week_offs_builder.dart';
import 'package:attendance/core/utils/app_date_format.dart';
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
import 'package:attendance/features/wfh/data/wfh_models.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/wfh/presentation/wfh_detail_screen.dart';
import 'package:attendance/features/wfh/presentation/wfh_form_screen.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/wfh_provider.dart';

class WfhScreen extends StatefulWidget {
  const WfhScreen({super.key});

  @override
  State<WfhScreen> createState() => _WfhScreenState();
}

class _WfhScreenState extends State<WfhScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WfhProvider>().loadIfNeeded();
    });
  }

  (Color fg, Color bg) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (AppColors.success, AppColors.successSoft);
      case 'rejected':
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
    final provider = context.watch<WfhProvider>();
    final canSubmit = context.watch<ProfileProvider>().canSubmitWfhRequest;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'WFH Requests'),
      floatingActionButton: canSubmit
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => const WfhFormScreen()));
                if (created == true && context.mounted) {
                  await provider.refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Request WFH'),
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
            icon: Icons.home_work_outlined,
            title: 'No WFH requests',
            message: canSubmit ? 'Tap Request WFH to submit a new request' : 'Work-from-home requests will appear here',
          ),
          child: OfficeWeekOffsBuilder(
            builder: (context, weekOffs) => AppStatusCalendarView<WfhRequest>(
              weekOffs: weekOffs,
              items: provider.requests,
              daysOf: (r) => appCalendarDaysBetween(r.wfhDate, r.wfhDate),
              toneOf: (r) => appRequestCalendarTone(r.status),
              emptyMessage: 'No WFH requests on these dates',
              legend: kAppRequestCalendarLegend,
              itemBuilder: (context, r) {
                final (fg, bg) = _statusColors(r.status);
                return AppListTile(
                  leading: AppListTileLeading.icon(Icons.home_work_outlined, accent: fg),
                  title: r.employeeDisplayName,
                  subtitleLines: [
                    if (r.wfhDate.isNotEmpty) 'Date: ${AppDateFormat.fromRaw(r.wfhDate)}',
                    if (r.reason.trim().isNotEmpty) r.reason.trim(),
                    if (r.employee?.department.isNotEmpty == true) r.employee!.department,
                  ],
                  trailing: AppStatusBadge(label: _label(r.status), foregroundColor: fg, backgroundColor: bg),
                  onTap: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => WfhDetailScreen(requestId: r.id, initial: r),
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

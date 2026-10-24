import 'package:flutter/material.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/leave_request/data/leave_request_models.dart';
import 'package:attendance/features/leave_request/presentation/leave_request_detail_screen.dart';
import 'package:attendance/features/team/data/team_models.dart';
import 'package:attendance/features/team/data/team_service.dart';
import 'package:attendance/features/team/presentation/team_member_detail_screen.dart';

class TeamLeaveScreen extends StatelessWidget {
  const TeamLeaveScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: const GradientAppBar(title: 'Team leave', showBack: true, showProfileAction: false),
        body: Column(
          children: [
            Material(
              color: scheme.surface,
              child: const TabBar(
                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(icon: Icon(Icons.mark_email_unread_outlined, size: 20), text: 'Requests'),
                  Tab(icon: Icon(Icons.luggage_outlined, size: 20), text: 'On leave'),
                  Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 20), text: 'Balances'),
                ],
              ),
            ),
            const Expanded(child: TabBarView(children: [_RequestsTab(), _OnLeaveTab(), _BalancesTab()])),
          ],
        ),
      ),
    );
  }
}

(Color, Color) _leaveColors(String status) {
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

String _leaveLabel(String status) {
  if (status.isEmpty) return 'Pending';
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}

Future<void> _openRequest(BuildContext context, LeaveRequestItem r, VoidCallback onChanged) async {
  final updated = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => LeaveRequestDetailScreen(requestId: r.id, initial: r),
    ),
  );
  if (updated == true) onChanged();
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab>
    with AutomaticKeepAliveClientMixin, ReportLoader<_RequestsTab, List<TeamLeaveRequest>> {
  final _service = TeamService();
  String _status = 'pending';

  @override
  bool get wantKeepAlive => true;

  @override
  Duration get cacheTtl => CachePolicy.teamTtl;

  @override
  String get cacheKey => 'team-leave-requests:$_status';

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<List<TeamLeaveRequest>> fetch() => _service.fetchLeaveRequests(status: _status == 'all' ? null : _status);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rows = data ?? const <TeamLeaveRequest>[];
    return AppContentContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          AppChoiceSegments<String>(
            value: _status,
            onChanged: (v) {
              setState(() => _status = v);
              loadIfNeeded();
            },
            options: const [
              AppSegmentOption(value: 'pending', label: 'Pending'),
              AppSegmentOption(value: 'approved', label: 'Approved'),
              AppSegmentOption(value: 'rejected', label: 'Rejected'),
              AppSegmentOption(value: 'all', label: 'All'),
            ],
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
              loading: const AppSkeletonList(itemCount: 5),
              empty: AppEmptyState(
                icon: Icons.event_available_outlined,
                title: _status == 'pending' ? 'No pending requests' : 'No leave requests',
                message: _status == 'pending'
                    ? 'New leave requests will show up here'
                    : 'Nothing matched this filter',
              ),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: kAppListTileSpacing),
                itemBuilder: (context, i) {
                  final item = rows[i];
                  final r = item.request;
                  final (fg, bg) = _leaveColors(r.status);
                  final extras = [
                    if (item.leaveType != null) appLabelize(item.leaveType!),
                    if (item.days > 0) '${item.days} day${item.days == 1 ? '' : 's'}',
                    if (item.paidDays > 0) '${item.paidDays} paid',
                    if (item.unpaidDays > 0) '${item.unpaidDays} unpaid',
                  ];
                  return AppListTile(
                    leading: AppListTileLeading.icon(Icons.event_busy_outlined, accent: fg),
                    title: r.employeeDisplayName,
                    subtitleLines: [
                      if (r.dateRangeLabel.isNotEmpty) r.dateRangeLabel,
                      if (extras.isNotEmpty) extras.join(' · '),
                      if (r.reason.trim().isNotEmpty) r.reason.trim(),
                      if (r.employee?.department.isNotEmpty == true) r.employee!.department,
                    ],
                    trailing: AppStatusBadge(label: _leaveLabel(r.status), foregroundColor: fg, backgroundColor: bg),
                    onTap: () => _openRequest(context, r, reload),
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

class _OnLeaveTab extends StatefulWidget {
  const _OnLeaveTab();

  @override
  State<_OnLeaveTab> createState() => _OnLeaveTabState();
}

class _OnLeaveTabState extends State<_OnLeaveTab>
    with AutomaticKeepAliveClientMixin, ReportLoader<_OnLeaveTab, TeamOnLeaveDay> {
  final _service = TeamService();
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  @override
  bool get wantKeepAlive => true;

  @override
  Duration get cacheTtl => CachePolicy.teamTtl;

  @override
  String get cacheKey => 'team-on-leave:${_date.toIso8601String()}';

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<TeamOnLeaveDay> fetch() => _service.fetchOnLeave(_date);

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final day = data;
    final today = DateUtils.dateOnly(DateTime.now());
    final leaves = day?.leaves ?? const <TeamLeaveRequest>[];
    return AppContentContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ReportPeriodBar(
            icon: Icons.luggage_outlined,
            label: _date == today ? 'Today · ${AppDateFormat.date(_date)}' : AppDateFormat.date(_date),
            onPrevious: () => _setDate(_date.subtract(const Duration(days: 1))),
            onNext: () => _setDate(_date.add(const Duration(days: 1))),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppLoadingState(
              isLoading: loading,
              hasLoaded: hasLoaded,
              hasData: leaves.isNotEmpty,
              refreshing: refreshing,
              error: error,
              onRetry: reload,
              onRefresh: reload,
              empty: const AppEmptyState(
                icon: Icons.event_available_outlined,
                title: 'Nobody is on leave',
                message: 'Your whole team is available on this day',
              ),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: leaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: kAppListTileSpacing),
                itemBuilder: (context, i) {
                  final item = leaves[i];
                  final r = item.request;
                  final (fg, bg) = _leaveColors(r.status);
                  return AppListTile(
                    leading: AppListTileLeading.icon(Icons.luggage_outlined, accent: AppColors.warning),
                    title: r.employeeDisplayName,
                    subtitleLines: [
                      if (r.dateRangeLabel.isNotEmpty) r.dateRangeLabel,
                      if (item.leaveType != null) '${appLabelize(item.leaveType!)} leave',
                      if (r.reason.trim().isNotEmpty) r.reason.trim(),
                    ],
                    trailing: AppStatusBadge(label: _leaveLabel(r.status), foregroundColor: fg, backgroundColor: bg),
                    onTap: () => _openRequest(context, r, reload),
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

class _BalancesTab extends StatefulWidget {
  const _BalancesTab();

  @override
  State<_BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends State<_BalancesTab>
    with AutomaticKeepAliveClientMixin, ReportLoader<_BalancesTab, List<TeamLeaveBalance>> {
  final _service = TeamService();

  @override
  bool get wantKeepAlive => true;

  @override
  Duration get cacheTtl => CachePolicy.leaveBalanceTtl;

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<List<TeamLeaveBalance>> fetch() => _service.fetchLeaveBalances();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rows = data ?? const <TeamLeaveBalance>[];
    return AppContentContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppLoadingState(
        isLoading: loading,
        hasLoaded: hasLoaded,
        hasData: rows.isNotEmpty,
        refreshing: refreshing,
        error: error,
        onRetry: reload,
        onRefresh: reload,
        loading: const AppSkeletonList(itemCount: 5),
        empty: const AppEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No balances',
          message: 'Leave balances will appear here',
        ),
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: kAppListTileSpacing),
          itemBuilder: (context, i) {
            final b = rows[i];
            return AppListTile(
              leading: AppListTileLeading.initials(b.employee.name),
              title: b.employee.name,
              subtitleLines: [
                [
                  if (b.employee.department != null) b.employee.department!,
                  if (b.pendingDays > 0) '${b.pendingDays} pending',
                  if (b.unpaidUsed > 0) '${b.unpaidUsed} unpaid used',
                ].join(' · '),
              ],
              trailing: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${b.balance}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                    TextSpan(
                      text: ' remaining',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeamMemberDetailScreen(
                      member: TeamMember.fromEmployee(employee: b.employee, leaveBalance: b.balance),
                      balance: b,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

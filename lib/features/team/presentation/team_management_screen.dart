import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/team/data/team_models.dart';
import 'package:attendance/features/team/data/team_service.dart';
import 'package:attendance/features/team/presentation/team_attendance_screen.dart';
import 'package:attendance/features/team/presentation/team_leave_screen.dart';
import 'package:attendance/features/team/presentation/team_member_detail_screen.dart';
import 'package:attendance/features/team/presentation/team_members_screen.dart';
import 'package:attendance/state/profile_provider.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with ReportLoader<TeamManagementScreen, TeamHubSnapshot> {
  final _service = TeamService();

  @override
  Duration get cacheTtl => CachePolicy.teamTtl;

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  Future<TeamHubSnapshot> fetch() => _service.fetchHub();

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) reload();
  }

  void _openMembers({String? status}) => _open(TeamMembersScreen(initialStatus: status));

  void _openMember(TeamMember member) => _open(TeamMemberDetailScreen(member: member));

  @override
  Widget build(BuildContext context) {
    final snap = data;
    final isAdmin = context.watch<ProfileProvider>().isAdmin;
    return Scaffold(
      appBar: const GradientAppBar(title: 'Team management', showBack: true, showProfileAction: false),
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: AppLoadingState(
          isLoading: loading,
          hasLoaded: hasLoaded,
          hasData: snap != null,
          refreshing: refreshing,
          error: error,
          onRetry: reload,
          onRefresh: reload,
          loading: const AppSkeletonList(itemCount: 6),
          child: snap == null
              ? const SizedBox.shrink()
              : ListView(
                  children: [
                    Text(
                      isAdmin ? 'Everyone today' : 'Your team today',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdmin
                          ? (snap.teamSize == 1
                                ? '1 person in the organisation'
                                : '${snap.teamSize} people in the organisation')
                          : (snap.teamSize == 1 ? '1 person reports to you' : '${snap.teamSize} people report to you'),
                      style: TextStyle(fontSize: 13.5, color: context.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ReportStatGrid(
                      columns: 3,
                      stats: [
                        ReportStat(
                          label: 'In team',
                          value: snap.teamSize,
                          color: AppColors.primary,
                          onTap: () => _openMembers(),
                        ),
                        ReportStat(
                          label: 'Present',
                          value: snap.countStatus('present'),
                          color: AppColors.success,
                          onTap: () => _openMembers(status: 'present'),
                        ),
                        ReportStat(
                          label: 'Not marked',
                          value: snap.countStatus('not_marked'),
                          color: AppColors.textSecondary,
                          onTap: () => _openMembers(status: 'not_marked'),
                        ),
                        ReportStat(
                          label: 'On leave',
                          value: snap.onLeaveToday.length,
                          color: AppColors.warning,
                          onTap: () => _open(const TeamLeaveScreen(initialTab: 1)),
                        ),
                        ReportStat(
                          label: 'Pending leave',
                          value: snap.pendingLeave,
                          color: const Color(0xFFEA580C),
                          onTap: () => _open(const TeamLeaveScreen(initialTab: 0)),
                        ),
                        ReportStat(
                          label: 'WFH',
                          value: snap.countStatus('wfh'),
                          color: const Color(0xFF7C3AED),
                          onTap: () => _openMembers(status: 'wfh'),
                        ),
                      ],
                    ),
                    if (snap.pendingRequests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ActionBanner(
                        icon: Icons.mark_email_unread_outlined,
                        accent: const Color(0xFFEA580C),
                        title: snap.pendingLeave == 1
                            ? '1 leave request waiting'
                            : '${snap.pendingLeave} leave requests waiting',
                        subtitle:
                            '${snap.pendingRequests.first.request.employeeDisplayName}'
                            '${snap.pendingLeave > 1 ? ' and others' : ''}'
                            '${snap.pendingRequests.first.request.dateRangeLabel.isEmpty ? '' : ' · ${snap.pendingRequests.first.request.dateRangeLabel}'}',
                        action: 'Review',
                        onTap: () => _open(const TeamLeaveScreen(initialTab: 0)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle(
                      title: snap.needsAttention.isEmpty ? 'Everyone is marked' : 'Needs attention',
                      trailing: snap.needsAttention.isEmpty ? 'All clear' : '${snap.needsAttention.length}',
                    ),
                    const SizedBox(height: kAppListTileSpacing),
                    if (snap.needsAttention.isEmpty)
                      ReportCard(
                        child: Text(
                          'No unmarked, late or leave statuses for today.',
                          style: TextStyle(fontSize: 13.5, color: context.textSecondary),
                        ),
                      )
                    else
                      for (var i = 0; i < snap.needsAttention.length; i++) ...[
                        if (i > 0) const SizedBox(height: kAppListTileSpacing),
                        _MemberRow(member: snap.needsAttention[i], onTap: () => _openMember(snap.needsAttention[i])),
                      ],
                    const SizedBox(height: 20),
                    _HubCard(
                      icon: Icons.groups_outlined,
                      accent: const Color(0xFF7C3AED),
                      title: 'Team members',
                      subtitle: 'Status, contact and leave balance for each person',
                      onTap: () => _openMembers(),
                    ),
                    const SizedBox(height: kAppListTileSpacing),
                    _HubCard(
                      icon: Icons.fact_check_outlined,
                      accent: AppColors.success,
                      title: 'Attendance',
                      subtitle: 'Daily view, monthly summary and punch records',
                      onTap: () => _open(const TeamAttendanceScreen()),
                    ),
                    const SizedBox(height: kAppListTileSpacing),
                    _HubCard(
                      icon: Icons.event_busy_outlined,
                      accent: AppColors.warning,
                      title: 'Leave',
                      badge: snap.pendingLeave > 0 ? '${snap.pendingLeave} pending' : null,
                      subtitle: snap.onLeaveToday.isEmpty
                          ? 'Requests, who is out, and remaining balances'
                          : '${snap.onLeaveToday.length} on leave today · requests and balances',
                      onTap: () => _open(
                        TeamLeaveScreen(
                          initialTab: snap.pendingLeave > 0
                              ? 0
                              : snap.onLeaveToday.isNotEmpty
                              ? 1
                              : 2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
          ),
        ),
        if (trailing != null) Text(trailing!, style: TextStyle(fontSize: 13, color: context.textSecondary)),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final TeamMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final times = [
      if (member.today.checkIn != null) 'In ${formatReportTime(member.today.checkIn)}',
      if (member.today.checkOut != null) 'Out ${formatReportTime(member.today.checkOut)}',
    ];
    return AppListTile(
      leading: AppListTileLeading.initials(member.name),
      title: member.name,
      subtitleLines: [
        [member.designation, member.department].where((s) => s.isNotEmpty).join(' · '),
        if (times.isNotEmpty) times.join(' · '),
        if (member.today.isLate) 'Late arrival',
      ].where((s) => s.isNotEmpty).toList(),
      trailing: ReportStatusBadge(member.today.status),
      onTap: onTap,
    );
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: AppListTileLeading.icon(icon, accent: accent),
      title: title,
      subtitle: subtitle,
      trailing: Text(
        action,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent),
      ),
      accentColor: accent,
      onTap: onTap,
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: AppListTileLeading.icon(icon, accent: accent),
      title: title,
      subtitle: subtitle,
      trailing: badge == null ? null : AppStatusBadge(label: badge!, tone: AppStatusTone.warning),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_search_field.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/team/data/team_models.dart';
import 'package:attendance/features/team/data/team_service.dart';
import 'package:attendance/features/team/presentation/team_member_detail_screen.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> with ReportLoader<TeamMembersScreen, List<TeamMember>> {
  final _service = TeamService();
  final _search = TextEditingController();
  late String? _status = widget.initialStatus;

  @override
  Duration get cacheTtl => CachePolicy.teamTtl;

  @override
  void initState() {
    super.initState();
    loadIfNeeded();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Future<List<TeamMember>> fetch() => _service.fetchMembers();

  List<TeamMember> _visible(List<TeamMember> all) {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final m in all)
        if ((_status == null || m.today.status.toLowerCase() == _status) &&
            (q.isEmpty ||
                m.name.toLowerCase().contains(q) ||
                m.department.toLowerCase().contains(q) ||
                m.designation.toLowerCase().contains(q)))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final all = data ?? const <TeamMember>[];
    final rows = _visible(all);
    final statuses = {for (final m in all) m.today.status.toLowerCase()};
    return Scaffold(
      appBar: const GradientAppBar(title: 'Team members', showBack: true, showProfileAction: false),
      body: AppContentContainer(
        padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding, AppDimensions.pagePadding, AppDimensions.pagePadding, 0),
        child: Column(
          children: [
            AppSearchField(
              controller: _search,
              hint: 'Search by name or department',
              onChanged: (_) => setState(() {}),
            ),
            if (statuses.length > 1) ...[
              const SizedBox(height: AppDimensions.sectionGap),
              AppChoiceSegments<String?>(
                value: _status,
                onChanged: (v) => setState(() => _status = v),
                options: [
                  const AppSegmentOption(value: null, label: 'All'),
                  for (final s in ['present', 'wfh', 'leave', 'absent', 'not_marked'])
                    if (statuses.contains(s)) AppSegmentOption(value: s, label: AttendanceStatusStyle.of(s).label),
                ],
              ),
            ],
            const SizedBox(height: AppDimensions.sectionGap),
            Expanded(
              child: AppLoadingState(
                isLoading: loading,
                hasLoaded: hasLoaded,
                hasData: rows.isNotEmpty,
                refreshing: refreshing,
                error: error,
                onRetry: reload,
                onRefresh: reload,
                loading: const AppSkeletonList(itemCount: 6),
                empty: AppEmptyState(
                  icon: Icons.groups_outlined,
                  title: all.isEmpty ? 'No team members' : 'No matches',
                  message: all.isEmpty
                      ? 'Employees and managers will appear here'
                      : 'Try a different search or filter',
                ),
                child: AppAdaptiveList(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacing24),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final m = rows[i];
                    final times = [
                      if (m.today.checkIn != null) 'In ${formatReportTime(m.today.checkIn)}',
                      if (m.today.checkOut != null) 'Out ${formatReportTime(m.today.checkOut)}',
                    ];
                    return AppListTile(
                      leading: AppListTileLeading.initials(m.name),
                      title: m.name,
                      subtitleLines: [
                        [m.designation, m.department].where((s) => s.isNotEmpty).join(' · '),
                        if (times.isNotEmpty) times.join(' · '),
                        if (m.today.isLate) 'Late arrival',
                        'Leave balance ${m.leaveBalance}',
                      ].where((s) => s.isNotEmpty).toList(),
                      trailing: ReportStatusBadge(m.today.status),
                      onTap: () async {
                        await Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => TeamMemberDetailScreen(member: m)));
                        if (context.mounted) reload();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

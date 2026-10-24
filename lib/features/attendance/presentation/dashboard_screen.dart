import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/attendance/data/remote_attendance_models.dart';
import 'package:attendance/features/dashboard/data/dashboard_models.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/features/lead/presentation/lead_detail_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_detail_screen.dart';
import 'package:attendance/features/project/data/project_models.dart';
import 'package:attendance/features/project/presentation/project_detail_screen.dart';
import 'package:attendance/state/dashboard_provider.dart';
import 'package:attendance/state/notification_provider.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/remote_attendance_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  AnimationController? _pageAnimController;
  Animation<double>? _pageFade;
  Animation<Offset>? _pageSlide;

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pageFade = CurvedAnimation(parent: _pageAnimController!, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageAnimController!, curve: Curves.easeOutCubic));
    _pageAnimController!.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ProfileProvider>().loadIfNeeded();
      if (!mounted) return;
      context.read<NotificationProvider>().refresh();
      if (!mounted) return;
      context.read<DashboardProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _pageAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    if (profileProvider.loading && !profileProvider.hasLoaded) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: const GradientAppBar(title: 'Dashboard', showNotificationAction: true),
        body: const AppSkeletonDashboard(),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Dashboard', showNotificationAction: true),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AppContentContainer(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _pageFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _pageSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: const _DashboardBody(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badgeText;

  const _SectionHeader({required this.title, required this.icon, this.badgeText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        const Spacer(),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
            ),
          ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  String _labelize(String raw) {
    if (raw.isEmpty) return '-';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    if (dash.loading && dash.data == null) {
      return const AppSkeletonDashboard();
    }
    if (dash.error != null && dash.data == null) {
      return AppErrorState(error: dash.error!, onRetry: dash.refresh);
    }
    final data = dash.data;
    if (data == null) {
      return const AppEmptyState(
        icon: Icons.dashboard_outlined,
        title: 'No dashboard data',
        message: 'Pull to refresh or try again later',
      );
    }

    final my = data.myStats;
    if (my != null) {
      return _PersonalDashboardContent(data: data, myStats: my, labelize: _labelize);
    }

    final stats = data.stats;
    final statTiles = <Widget>[
      _AttendanceStatTile(present: stats.todayPresent, absent: stats.todayAbsent),
      _StatTile(
        icon: Icons.event_outlined,
        label: "Today's meetings",
        value: stats.todayMeetings,
        color: AppColors.info,
      ),
      _StatTile(
        icon: Icons.task_alt_outlined,
        label: 'Overdue tasks',
        value: stats.overdueTasks,
        color: AppColors.error,
      ),
      _StatTile(icon: Icons.fiber_new_outlined, label: 'New leads', value: stats.newLeads, color: AppColors.warning),
    ];

    final showLeads = context.watch<ProfileProvider>().canAccessLeadModule;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DashboardProvider>().refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _SectionHeader(title: 'Overview', icon: Icons.insights_outlined),
          const SizedBox(height: 12),
          _StatGrid(tiles: statTiles),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Upcoming meetings',
            icon: Icons.groups_outlined,
            badgeText: '${data.upcomingMeetings.length}',
          ),
          const SizedBox(height: 12),
          if (data.upcomingMeetings.isEmpty)
            const AppEmptyState(
              icon: Icons.event_available_outlined,
              title: 'No upcoming meetings',
              message: 'Scheduled meetings will show up here',
            )
          else
            for (var i = 0; i < data.upcomingMeetings.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _UpcomingMeetingTile(meeting: data.upcomingMeetings[i], labelize: _labelize),
            ],
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent projects',
            icon: Icons.work_outline,
            badgeText: '${data.recentProjects.length}',
          ),
          const SizedBox(height: 12),
          if (data.recentProjects.isEmpty)
            const AppEmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No recent projects',
              message: 'New projects will show up here',
            )
          else
            for (var i = 0; i < data.recentProjects.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _RecentProjectTile(project: data.recentProjects[i], labelize: _labelize),
            ],
          if (showLeads) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Recent leads',
              icon: Icons.business_center_outlined,
              badgeText: '${data.recentLeads.length}',
            ),
            const SizedBox(height: 12),
            if (data.recentLeads.isEmpty)
              const AppEmptyState(
                icon: Icons.business_center_outlined,
                title: 'No recent leads',
                message: 'New leads will show up here',
              )
            else
              for (var i = 0; i < data.recentLeads.length.clamp(0, 5); i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _RecentLeadTile(lead: data.recentLeads[i], labelize: _labelize),
              ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: wide ? 112 : 132,
          ),
          itemBuilder: (_, i) => tiles[i],
        );
      },
    );
  }
}

class _PersonalDashboardContent extends StatelessWidget {
  const _PersonalDashboardContent({required this.data, required this.myStats, required this.labelize});

  final DashboardData data;
  final DashboardMyStats myStats;
  final String Function(String) labelize;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        icon: Icons.folder_outlined,
        label: 'My projects',
        value: myStats.myProjects,
        color: AppTheme.primaryBlue,
      ),
      _StatTile(
        icon: Icons.task_alt_outlined,
        label: 'Assigned tasks',
        value: myStats.assignedTasks,
        color: AppColors.info,
      ),
      _StatTile(
        icon: Icons.pending_actions_outlined,
        label: 'Pending tasks',
        value: myStats.pendingMyTasks,
        color: AppColors.warning,
      ),
      _StatTile(
        icon: Icons.warning_amber_outlined,
        label: 'Overdue tasks',
        value: myStats.overdueMyTasks,
        color: AppColors.error,
      ),
      _StatTile(
        icon: Icons.flag_outlined,
        label: 'Milestones',
        value: myStats.assignedMilestones,
        color: AppColors.success,
      ),
      _StatTile(icon: Icons.event_outlined, label: 'My meetings', value: myStats.myMeetings, color: AppColors.info),
    ];

    final showLeads = context.watch<ProfileProvider>().canAccessLeadModule;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
              children: [
          _TodayAttendanceCard(today: myStats.attendanceToday, labelize: labelize),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Overview', icon: Icons.insights_outlined),
          const SizedBox(height: 12),
          _StatGrid(tiles: tiles),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Upcoming meetings',
            icon: Icons.groups_outlined,
            badgeText: '${data.upcomingMeetings.length}',
          ),
          const SizedBox(height: 12),
          if (data.upcomingMeetings.isEmpty)
            const AppEmptyState(
              icon: Icons.event_available_outlined,
              title: 'No upcoming meetings',
              message: 'Your meetings will show up here',
            )
          else
            for (var i = 0; i < data.upcomingMeetings.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _UpcomingMeetingTile(meeting: data.upcomingMeetings[i], labelize: labelize),
            ],
          if (data.upcomingMilestones.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Upcoming milestones',
              icon: Icons.flag_outlined,
              badgeText: '${data.upcomingMilestones.length}',
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < data.upcomingMilestones.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _UpcomingMilestoneTile(item: data.upcomingMilestones[i]),
            ],
          ],
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent projects',
            icon: Icons.work_outline,
            badgeText: '${data.recentProjects.length}',
          ),
          const SizedBox(height: 12),
          if (data.recentProjects.isEmpty)
            const AppEmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No recent projects',
              message: 'Projects you are part of will show up here',
            )
          else
            for (var i = 0; i < data.recentProjects.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _RecentProjectTile(project: data.recentProjects[i], labelize: labelize),
            ],
          if (showLeads) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Recent leads',
              icon: Icons.business_center_outlined,
              badgeText: '${data.recentLeads.length}',
            ),
            const SizedBox(height: 12),
            if (data.recentLeads.isEmpty)
              const AppEmptyState(
                icon: Icons.business_center_outlined,
                title: 'No recent leads',
                message: 'New leads will show up here',
              )
            else
              for (var i = 0; i < data.recentLeads.length.clamp(0, 5); i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _RecentLeadTile(lead: data.recentLeads[i], labelize: labelize),
              ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TodayAttendanceCard extends StatelessWidget {
  const _TodayAttendanceCard({required this.today, required this.labelize});

  final RemoteAttendanceRecord? today;
  final String Function(String) labelize;

  Future<void> _run(BuildContext context, {required bool checkIn}) async {
    final attendance = context.read<RemoteAttendanceProvider>();
    final ok = checkIn ? await attendance.checkIn() : await attendance.checkOut();
    if (!context.mounted) return;
    if (!ok) {
      AppFeedback.error(context, attendance.error ?? Exception(checkIn ? 'Check-in failed' : 'Check-out failed'));
      return;
    }
    AppFeedback.success(context, checkIn ? 'Checked in' : 'Checked out');
    await context.read<DashboardProvider>().refresh();
  }

  /// Accepts full ISO timestamps or bare `HH:mm[:ss]` times (taken as today).
  static DateTime? _parseTime(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final full = DateTime.tryParse(s);
    if (full != null) return full.toLocal();
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(s);
    if (m == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3] ?? '0'));
  }

  static String _fmt(String? raw) {
    final t = _parseTime(raw);
    if (t != null) return DateFormat('h:mm a').format(t);
    final s = raw?.trim() ?? '';
    return s.isEmpty ? '--:--' : s;
  }

  static String? _duration(String? inRaw, String? outRaw) {
    final a = _parseTime(inRaw);
    final b = _parseTime(outRaw) ?? (a != null ? DateTime.now() : null);
    if (a == null || b == null || b.isBefore(a)) return null;
    final d = b.difference(a);
    return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final acting = context.watch<RemoteAttendanceProvider>().acting;
    final record = today;
    final checkedIn = (record?.checkIn ?? '').isNotEmpty;
    final checkedOut = (record?.checkOut ?? '').isNotEmpty;
    final worked = checkedIn ? _duration(record!.checkIn, record.checkOut) : null;

    final String statusText;
    final IconData statusIcon;
    if (!checkedIn) {
      statusText = record == null ? 'Not checked in' : labelize(record.status);
      statusIcon = Icons.radio_button_unchecked;
    } else if (!checkedOut) {
      statusText = 'Working';
      statusIcon = Icons.circle;
    } else {
      statusText = 'Day complete';
      statusIcon = Icons.check_circle;
    }

    final String actionLabel;
    final IconData actionIcon;
    final VoidCallback? action;
    if (!checkedIn) {
      actionLabel = 'Check in';
      actionIcon = Icons.login_rounded;
      action = acting ? null : () => _run(context, checkIn: true);
    } else if (!checkedOut) {
      actionLabel = 'Check out';
      actionIcon = Icons.logout_rounded;
      action = acting ? null : () => _run(context, checkIn: false);
    } else {
      actionLabel = 'All done for today';
      actionIcon = Icons.check_circle_outline;
      action = null;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      DateFormat('EEEE').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                      Text(
                      AppDateFormat.date(DateTime.now()),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
                      Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: checkedIn && !checkedOut ? AppColors.success : Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                        ),
                      ),
                    ],
                  ),
          if (record?.isLate == true) ...[
            const SizedBox(height: 8),
                  Row(
                    children: [
                Icon(Icons.schedule, size: 14, color: Colors.amber.shade200),
                      const SizedBox(width: 4),
                Text(
                  'Marked late today',
                  style: TextStyle(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PunchTimeBlock(icon: Icons.login_rounded, label: 'Check in', value: _fmt(record?.checkIn)),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: _PunchTimeBlock(icon: Icons.logout_rounded, label: 'Check out', value: _fmt(record?.checkOut)),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: _PunchTimeBlock(icon: Icons.timelapse_rounded, label: 'Worked', value: worked ?? '--'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              onPressed: action,
              icon: acting ? const AppProgress(size: AppLoaderSize.small, color: AppColors.primary) : Icon(actionIcon),
              label: Text(acting ? 'Please wait…' : actionLabel),
              ),
            ),
          ],
        ),
    );
  }
}

class _PunchTimeBlock extends StatelessWidget {
  const _PunchTimeBlock({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _UpcomingMeetingTile extends StatelessWidget {
  const _UpcomingMeetingTile({required this.meeting, required this.labelize});

  final DashboardUpcomingMeeting meeting;
  final String Function(String) labelize;

  (Color fg, Color bg) _typeColors(String type) {
    switch (type.toLowerCase()) {
      case 'lead':
        return (AppColors.info, AppColors.infoSoft);
      case 'client':
        return (AppColors.primary, AppColors.primarySoft);
      case 'employee':
        return (AppColors.success, AppColors.successSoft);
      case 'other':
        return (AppColors.warning, AppColors.warningSoft);
      default:
        return (AppColors.textSecondary, AppColors.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _typeColors(meeting.meetingType);
    return AppListTile(
      leading: AppListTileLeading.icon(Icons.groups_outlined, accent: fg),
      title: meeting.title.isEmpty ? 'Untitled meeting' : meeting.title,
      subtitleLines: [
        if (meeting.rangeLabel.isNotEmpty) meeting.rangeLabel,
        if (meeting.organizerName.isNotEmpty) meeting.organizerName,
        if (meeting.location.isNotEmpty) meeting.location,
      ],
      trailing: AppStatusBadge(label: meeting.typeLabel, foregroundColor: fg, backgroundColor: bg),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => MeetingDetailScreen(meeting: meeting.toMeeting())));
      },
    );
  }
}

class _UpcomingMilestoneTile extends StatelessWidget {
  const _UpcomingMilestoneTile({required this.item});

  final DashboardUpcomingItem item;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: AppListTileLeading.icon(Icons.flag_outlined, accent: AppColors.success),
      title: item.title.isEmpty ? 'Untitled milestone' : item.title,
      subtitleLines: [if (item.when.isNotEmpty) AppDateFormat.fromRaw(item.when, withTime: true)],
    );
  }
}

class _AttendanceStatTile extends StatelessWidget {
  const _AttendanceStatTile({required this.present, required this.absent});

  final int present;
  final int absent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.subtleBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.how_to_reg_outlined, color: AppTheme.primaryBlue, size: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$present',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.success, height: 1.1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                '$absent',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.error, height: 1.1),
              ),
            ],
          ),
          Text(
            'Present / Absent',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.textSecondary, fontWeight: FontWeight.w600, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.subtleBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: context.textPrimary, height: 1.1),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.textSecondary, fontWeight: FontWeight.w600, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _RecentProjectTile extends StatelessWidget {
  const _RecentProjectTile({required this.project, required this.labelize});

  final Project project;
  final String Function(String) labelize;

  (Color fg, Color bg) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return (AppColors.info, AppColors.infoSoft);
      case 'completed':
        return (AppColors.success, AppColors.successSoft);
      case 'draft':
      case 'pending':
        return (AppColors.warning, AppColors.warningSoft);
      default:
        return (AppColors.textSecondary, AppColors.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _statusColors(project.status);
    final typeLabel = project.projectTypeLabel.isNotEmpty ? project.projectTypeLabel : labelize(project.projectType);
    return AppListTile(
      leading: AppListTileLeading.icon(Icons.work_outline, accent: fg),
      title: project.name,
      subtitleLines: [
        if (project.client.displayName.isNotEmpty) project.client.displayName,
        if (typeLabel.isNotEmpty) typeLabel,
        if ((project.startDate ?? '').isNotEmpty) 'Start ${AppDateFormat.fromRaw(project.startDate)}',
      ],
      trailing: AppStatusBadge(label: labelize(project.status), foregroundColor: fg, backgroundColor: bg),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)));
      },
    );
  }
}

class _RecentLeadTile extends StatelessWidget {
  const _RecentLeadTile({required this.lead, required this.labelize});

  final Lead lead;
  final String Function(String) labelize;

  (Color fg, Color bg) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'hot':
        return (AppColors.error, AppColors.errorSoft);
      case 'warm':
        return (AppColors.warning, AppColors.warningSoft);
      case 'converted':
        return (AppColors.success, AppColors.successSoft);
      case 'cold':
      default:
        return (AppColors.info, AppColors.infoSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _statusColors(lead.leadStatus);
    final company = lead.companyName.trim();
    final email = lead.companyEmail.trim();
    final phone = lead.companyPhone.trim();
    final industry = lead.industry.trim();

    return AppListTile(
      leading: AppListTileLeading.icon(Icons.business_center_outlined, accent: fg),
      overline: (lead.leadCode ?? '').trim().isEmpty ? null : lead.leadCode,
      title: company.isNotEmpty ? company : 'Lead #${lead.id ?? ''}',
      meta: [
        if (email.isNotEmpty) AppListTileMeta(Icons.email_outlined, email),
        if (phone.isNotEmpty) AppListTileMeta(Icons.phone_outlined, phone),
      ],
      footer: industry.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                industry,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textSecondary),
              ),
            ),
      trailing: AppStatusBadge(label: labelize(lead.leadStatus), foregroundColor: fg, backgroundColor: bg),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)));
      },
    );
  }
}

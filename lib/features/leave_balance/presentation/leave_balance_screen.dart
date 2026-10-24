import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_search_field.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/leave_balance/data/leave_balance_service.dart';
import 'package:attendance/features/leave_balance/presentation/leave_balance_adjust_dialog.dart';
import 'package:attendance/state/profile_provider.dart';

class LeaveBalanceScreen extends StatefulWidget {
  const LeaveBalanceScreen({super.key});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen>
    with ReportLoader<LeaveBalanceScreen, LeaveBalanceHome> {
  final _service = LeaveBalanceService();
  final _search = TextEditingController();

  bool get _showMine => !context.read<ProfileProvider>().isAdmin;
  bool get _showPeople => context.read<ProfileProvider>().isAdminOrManager;
  bool get _canAdjust => context.read<ProfileProvider>().isAdminOrManager;

  @override
  Duration get cacheTtl => CachePolicy.leaveBalanceTtl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().loadIfNeeded();
      if (mounted) loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Future<LeaveBalanceHome> fetch() => _service.fetchHome(includeMine: _showMine, includePeople: _showPeople);

  List<LeaveBalancePerson> _visiblePeople(List<LeaveBalancePerson> all) {
    final q = _search.text.trim().toLowerCase();
    final rows = [...all]
      ..sort((a, b) {
        final byBalance = a.balance.compareTo(b.balance);
        if (byBalance != 0) return byBalance;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    if (q.isEmpty) return rows;
    return [
      for (final p in rows)
        if (p.name.toLowerCase().contains(q) || (p.department ?? '').toLowerCase().contains(q)) p,
    ];
  }

  Future<void> _adjust(LeaveBalancePerson person) async {
    final saved = await showAdjustLeaveBalanceDialog(context, person: person);
    if (saved && mounted) {
      AppFeedback.success(context, 'Balance updated for ${person.name}');
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = data;
    final mine = home?.mine;
    final people = home?.people;
    final visible = people == null ? const <LeaveBalancePerson>[] : _visiblePeople(people);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Leave balance', showBack: true, showProfileAction: false),
      body: AppContentContainer(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          0,
        ),
        child: AppLoadingState(
          isLoading: loading,
          hasLoaded: hasLoaded,
          hasData: home != null,
          refreshing: refreshing,
          error: error,
          onRetry: reload,
          onRefresh: reload,
          loading: const AppSkeletonList(itemCount: 6),
          empty: const AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No leave balance',
            message: 'Your leave days will appear here once they are allocated',
          ),
          child: home == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (mine != null) ...[
                      _MyBalanceCard(mine: mine),
                      const SizedBox(height: 16),
                      Text(
                        'History',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      if (mine.logs.isEmpty)
                        ReportCard(
                          child: Text(
                            'No credits or deductions yet',
                            style: TextStyle(fontSize: 13.5, color: context.textSecondary),
                          ),
                        )
                      else
                        for (var i = 0; i < mine.logs.length; i++) ...[
                          if (i > 0) const SizedBox(height: kAppListTileSpacing),
                          _LogTile(log: mine.logs[i]),
                        ],
                    ],
                    if (people != null) ...[
                      if (mine != null) const SizedBox(height: 24),
                      Text(
                        _showMine ? 'People' : 'Everyone',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _canAdjust ? 'Tap a person to credit or debit days' : '${people.length} people',
                        style: TextStyle(fontSize: 13, color: context.textSecondary),
                      ),
                      const SizedBox(height: kAppListTileSpacing),
                      AppSearchField(
                        controller: _search,
                        hint: 'Search by name or department',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            people.isEmpty ? 'No balances yet' : 'No matches',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textSecondary),
                          ),
                        )
                      else
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0) const SizedBox(height: kAppListTileSpacing),
                          _PersonCard(person: visible[i], canAdjust: _canAdjust, onAdjust: () => _adjust(visible[i])),
                        ],
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _MyBalanceCard extends StatelessWidget {
  const _MyBalanceCard({required this.mine});

  final MyLeaveBalance mine;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remaining', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  '${mine.balance} day${mine.balance == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
                Text(mine.name, style: TextStyle(fontSize: 13.5, color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final LeaveBalanceLog log;

  @override
  Widget build(BuildContext context) {
    final credit = log.isCredit;
    final delta = log.change == 0 ? '0' : '${credit && log.change > 0 ? '+' : ''}${log.change}';
    return AppListTile(
      leading: AppListTileLeading.icon(
        credit ? Icons.add : Icons.remove,
        accent: credit ? AppColors.success : AppColors.error,
      ),
      title: '${appLabelize(log.type)} · $delta',
      subtitleLines: [
        '${log.balanceBefore} → ${log.balanceAfter}',
        if (log.note != null) log.note!,
        if (log.changedBy != null) 'By ${log.changedBy!.name}',
        if (log.createdAt != null) AppDateFormat.fromRaw(log.createdAt, withTime: true),
      ],
      showChevron: false,
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.canAdjust, required this.onAdjust});

  final LeaveBalancePerson person;
  final bool canAdjust;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: AppListTileLeading.initials(person.name),
      title: person.name,
      subtitle: person.department,
      trailing: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${person.balance}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
            ),
            TextSpan(
              text: ' remaining',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.textSecondary),
            ),
          ],
        ),
      ),
      showChevron: canAdjust,
      onTap: canAdjust ? onAdjust : null,
    );
  }
}

import 'package:flutter/material.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_search_field.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/leave_pool/data/leave_pool_service.dart';
import 'package:attendance/features/leave_pool/presentation/leave_pool_dialogs.dart';

class LeavePoolScreen extends StatefulWidget {
  const LeavePoolScreen({super.key});

  @override
  State<LeavePoolScreen> createState() => _LeavePoolScreenState();
}

class _LeavePoolScreenState extends State<LeavePoolScreen> with ReportLoader<LeavePoolScreen, LeavePoolOverview> {
  final _service = LeavePoolService();
  final _search = TextEditingController();
  int _year = DateTime.now().year;

  @override
  Duration get cacheTtl => CachePolicy.leaveBalanceTtl;

  @override
  String get cacheKey => 'leave-pool:$_year';

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
  Future<LeavePoolOverview> fetch() => _service.fetchOverview(_year);

  void _setYear(int year) {
    setState(() => _year = year);
    loadIfNeeded();
  }

  List<LeavePoolEmployee> _visible(LeavePoolOverview pool) {
    final q = _search.text.trim().toLowerCase();
    final rows = [...pool.employees]
      ..sort((a, b) {
        final pending = b.pendingDays.compareTo(a.pendingDays);
        if (pending != 0) return pending;
        final unpaid = b.unpaidUsed.compareTo(a.unpaidUsed);
        if (unpaid != 0) return unpaid;
        return a.employee.name.toLowerCase().compareTo(b.employee.name.toLowerCase());
      });
    if (q.isEmpty) return rows;
    return [
      for (final e in rows)
        if (e.employee.name.toLowerCase().contains(q) || (e.employee.department ?? '').toLowerCase().contains(q)) e,
    ];
  }

  Future<void> _setQuota() async {
    final current = data?.annualLeaveQuota ?? 0;
    final saved = await showSetLeaveQuotaDialog(context, currentQuota: current);
    if (saved && mounted) {
      AppFeedback.success(context, 'Yearly quota updated');
      await reload();
    }
  }

  Future<void> _allocate() async {
    final pool = data;
    final saved = await showAllocateLeaveDialog(
      context,
      suggestedDays: pool?.annualLeaveQuota ?? 0,
      employeeCount: pool?.totals.employees ?? pool?.employees.length ?? 0,
      year: _year,
    );
    if (saved && mounted) {
      AppFeedback.success(context, 'Leave days allocated to everyone');
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pool = data;
    final nowYear = DateTime.now().year;
    final rows = pool == null ? const <LeavePoolEmployee>[] : _visible(pool);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Leave pool', showBack: true, showProfileAction: false),
      body: AppContentContainer(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          0,
        ),
        child: Column(
          children: [
            ReportPeriodBar(
              icon: Icons.calendar_today_outlined,
              label: '$_year',
              onPrevious: () => _setYear(_year - 1),
              onNext: _year >= nowYear + 1 ? null : () => _setYear(_year + 1),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AppLoadingState(
                isLoading: loading,
                hasLoaded: hasLoaded,
                hasData: pool != null,
                refreshing: refreshing,
                error: error,
                onRetry: reload,
                onRefresh: reload,
                loading: const AppSkeletonList(itemCount: 6),
                empty: const AppEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No leave pool',
                  message: 'Leave balances for this year will appear here',
                ),
                child: pool == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          _QuotaCard(pool: pool, onEdit: _setQuota),
                          if (pool.totals.pendingRequests > 0) ...[
                            const SizedBox(height: 12),
                            _PendingBanner(count: pool.totals.pendingRequests),
                          ],
                          const SizedBox(height: 12),
                          ReportStatGrid(
                            columns: 3,
                            stats: [
                              ReportStat(label: 'People', value: pool.totals.employees, color: AppColors.primary),
                              ReportStat(label: 'Remaining', value: pool.totals.balance, color: AppColors.success),
                              ReportStat(
                                label: 'Credited',
                                value: pool.totals.creditedThisYear,
                                color: const Color(0xFF0F766E),
                              ),
                              ReportStat(label: 'Paid used', value: pool.totals.paidUsed, color: AppColors.warning),
                              ReportStat(label: 'Unpaid used', value: pool.totals.unpaidUsed, color: AppColors.error),
                              ReportStat(
                                label: 'Pending days',
                                value: pool.totals.pendingDays,
                                color: const Color(0xFFEA580C),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Theme(
                            data: Theme.of(context).copyWith(
                              filledButtonTheme: FilledButtonThemeData(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                              outlinedButtonTheme: OutlinedButtonThemeData(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _setQuota,
                                    icon: const Icon(Icons.tune_rounded, size: 18),
                                    label: const Text('Set quota'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: pool.employees.isEmpty ? null : _allocate,
                                    icon: const Icon(Icons.done_all_rounded, size: 18),
                                    label: const Text('Allocate'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Employees',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          AppSearchField(
                            controller: _search,
                            hint: 'Search by name or department',
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          if (rows.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Text(
                                pool.employees.isEmpty ? 'No employees in the pool' : 'No matches',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.textSecondary),
                              ),
                            )
                          else
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0) const SizedBox(height: kAppListTileSpacing),
                              _EmployeeCard(row: rows[i]),
                            ],
                          SizedBox(height: MediaQuery.paddingOf(context).bottom),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.pool, required this.onEdit});

  final LeavePoolOverview pool;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final empty = pool.annualLeaveQuota <= 0;
    return AppListTile(
      leading: AppListTileLeading.icon(Icons.event_available_outlined, accent: const Color(0xFF0F766E)),
      title: empty ? 'No yearly quota yet' : '${pool.annualLeaveQuota} days per year',
      subtitle: empty ? 'Set how many paid leave days each person gets' : 'Policy for ${pool.year} · tap to change',
      trailing: Text(
        empty ? 'Set' : 'Edit',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
      ),
      onTap: onEdit,
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1 ? '1 leave request is waiting for review' : '$count leave requests are waiting for review',
              style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.row});

  final LeavePoolEmployee row;

  @override
  Widget build(BuildContext context) {
    final metrics = <(String, int, Color)>[
      ('Credited', row.creditedThisYear, const Color(0xFF0F766E)),
      ('Paid used', row.paidUsed, AppColors.warning),
      ('Unpaid', row.unpaidUsed, AppColors.error),
      if (row.pendingDays > 0) ('Pending', row.pendingDays, const Color(0xFFEA580C)),
    ];

    return AppListTile(
      leading: AppListTileLeading.initials(row.employee.name),
      title: row.employee.name,
      subtitle: row.employee.department,
      trailing: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${row.balance}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
            ),
            TextSpan(
              text: ' remaining',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.textSecondary),
            ),
          ],
        ),
      ),
      showChevron: false,
      footer: metrics.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final m in metrics) _MetricChip(label: m.$1, value: m.$2, color: m.$3),
              ],
            ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
            TextSpan(
              text: ' $label',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
